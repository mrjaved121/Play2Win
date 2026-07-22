import { randomUUID } from "crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  buildLadder,
  generateServerSeed,
  hashServerSeed,
  isLaneBust,
  LANE_COUNTS,
} from "@/lib/crossing/engine";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import { findOrCreateAccountPlayer, resolvePlayer } from "@/lib/supabase/playerResolution";
import { supabaseCrossingSettingsRepository } from "@/lib/supabase/supabaseCrossingSettingsRepository";
import type { CrossingRepository } from "@/lib/repositories/types";
import type {
  CrossingDifficulty,
  CrossingHistoryEntry,
  CrossingLeaderboard,
  CrossingLeaderboardEntry,
  CrossingLiveRoundEntry,
  CrossingRoundPublic,
  CrossingSettings,
} from "@/lib/types";

interface CrossingRoundRow {
  id: string;
  player_id: string;
  bet_amount: number;
  difficulty: CrossingDifficulty;
  lane_count: number;
  bust_pct: number;
  rtp: number;
  client_seed: string;
  server_seed: string;
  server_seed_hash: string;
  current_lane: number;
  status: CrossingRoundPublic["status"];
  payout: number | null;
  resolved_multiplier: number | null;
  started_at: string;
  resolved_at: string | null;
  voided: boolean;
  players?: { display_name?: string } | null;
}

function bustPctForDifficulty(settings: CrossingSettings, difficulty: CrossingDifficulty): number {
  return {
    easy: settings.easyBustPct,
    medium: settings.mediumBustPct,
    hard: settings.hardBustPct,
    hardcore: settings.hardcoreBustPct,
  }[difficulty];
}

function toHistoryEntry(row: CrossingRoundRow): CrossingHistoryEntry {
  return {
    roundId: row.id,
    bet: Number(row.bet_amount),
    difficulty: row.difficulty,
    lanesCleared: row.current_lane,
    multiplier: row.status === "collected" ? Number(row.resolved_multiplier) : 0,
    winAmount: row.payout != null ? Number(row.payout) : 0,
    isWin: row.status === "collected",
    timestamp: row.resolved_at ?? row.started_at,
    voided: row.voided,
  };
}

type GameStatColumn = "total_sessions" | "total_wagered" | "total_payout";

/** Same read-then-write pattern as supabaseCrashRepository's incrementGameStats. */
async function incrementGameStats(
  supabase: SupabaseClient,
  gameId: string,
  deltas: Partial<Record<GameStatColumn, number>>,
): Promise<void> {
  const { data: gameRow } = await supabase
    .from("games")
    .select("total_sessions, total_wagered, total_payout")
    .eq("id", gameId)
    .maybeSingle();
  if (!gameRow) return;
  const update: Partial<Record<GameStatColumn, number>> = {};
  for (const column of Object.keys(deltas) as GameStatColumn[]) {
    update[column] = Number(gameRow[column]) + (deltas[column] ?? 0);
  }
  await supabase.from("games").update(update).eq("id", gameId);
}

function toPublic(row: CrossingRoundRow): CrossingRoundPublic {
  const reveal = row.status !== "pending";
  return {
    roundId: row.id,
    status: row.status,
    difficulty: row.difficulty,
    betAmount: Number(row.bet_amount),
    laneCount: row.lane_count,
    currentLane: row.current_lane,
    ladder: buildLadder(row.lane_count, Number(row.rtp), Number(row.bust_pct)),
    clientSeed: row.client_seed,
    serverSeedHash: row.server_seed_hash,
    startedAt: row.started_at,
    payout: row.payout != null ? Number(row.payout) : undefined,
    resolvedMultiplier: row.resolved_multiplier != null ? Number(row.resolved_multiplier) : undefined,
    rtp: Number(row.rtp),
    bustPct: Number(row.bust_pct),
    voided: row.voided,
    ...(reveal ? { serverSeed: row.server_seed } : {}),
  };
}

async function findGameId(supabase: SupabaseClient): Promise<string | undefined> {
  const { data } = await supabase.from("games").select("id").eq("name", "Multiplier Crossing").maybeSingle();
  return (data?.id as string | undefined) ?? undefined;
}

/** Unlike crash, there's no "join an existing flight" concept — only one round in flight per player at a time. */
async function findPendingRound(supabase: SupabaseClient, playerId: string): Promise<CrossingRoundRow | null> {
  const { data } = await supabase
    .from("crossing_rounds")
    .select("*")
    .eq("player_id", playerId)
    .eq("status", "pending")
    .maybeSingle();
  return (data as CrossingRoundRow | null) ?? null;
}

export const supabaseCrossingRepository: CrossingRepository = {
  async getOrCreatePlayerBalance({ guestId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);
    return { playerId: player.id, balance: Number(player.credit_balance) };
  },

  async placeBet({ guestId, betAmount, difficulty, clientSeed, accessToken }) {
    const settings = await supabaseCrossingSettingsRepository.get();
    if (!Number.isFinite(betAmount) || betAmount < settings.minBet || betAmount > settings.maxBet) {
      throw new Error(`Bet must be between ${settings.minBet} and ${settings.maxBet} credits`);
    }
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);
    const balance = Number(player.credit_balance);
    if (balance < betAmount) throw new Error("Insufficient balance");

    const existing = await findPendingRound(supabase, player.id);
    if (existing) throw new Error("You already have a round in progress");

    const roundId = randomUUID();
    const serverSeed = generateServerSeed();
    const seed = clientSeed.trim() || randomUUID();
    const laneCount = LANE_COUNTS[difficulty];
    const bustPct = bustPctForDifficulty(settings, difficulty);

    const { data: round, error: roundError } = await supabase
      .from("crossing_rounds")
      .insert({
        id: roundId,
        player_id: player.id,
        bet_amount: betAmount,
        difficulty,
        lane_count: laneCount,
        bust_pct: bustPct,
        rtp: settings.rtp,
        client_seed: seed,
        server_seed: serverSeed,
        server_seed_hash: hashServerSeed(serverSeed),
        current_lane: 0,
        started_at: new Date().toISOString(),
        status: "pending",
      })
      .select("*")
      .single();
    if (roundError) throw new Error(`Supabase crossing.placeBet failed: ${roundError.message}`);

    const newBalance = balance - betAmount;
    const { error: updateError } = await supabase
      .from("players")
      .update({
        credit_balance: newBalance,
        total_wagered: Number(player.total_wagered) + betAmount,
        games_played: Number(player.games_played) + 1,
        last_active_at: new Date().toISOString(),
      })
      .eq("id", player.id);
    if (updateError) throw new Error(`Supabase crossing.placeBet balance update failed: ${updateError.message}`);

    const gameId = await findGameId(supabase);
    await supabase.from("transactions").insert({
      player_id: player.id,
      game_id: gameId ?? null,
      type: "wager",
      status: "completed",
      amount: -betAmount,
    });
    if (gameId) await incrementGameStats(supabase, gameId, { total_sessions: 1, total_wagered: betAmount });

    return { round: toPublic(round as CrossingRoundRow), balance: newBalance };
  },

  async advance({ guestId, roundId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const { data: roundRow, error: roundError } = await supabase
      .from("crossing_rounds")
      .select("*")
      .eq("id", roundId)
      .eq("player_id", player.id)
      .maybeSingle();
    if (roundError) throw new Error(`Supabase crossing.advance round lookup failed: ${roundError.message}`);
    if (!roundRow) throw new Error("Round not found");
    const round = roundRow as CrossingRoundRow;
    if (round.status !== "pending") throw new Error("Round already resolved");

    const laneIndex = round.current_lane + 1;
    const bust = isLaneBust(round.server_seed, round.client_seed, round.id, laneIndex, Number(round.bust_pct));

    if (bust) {
      // Guarded by .eq("status", "pending") so a racing cashout/advance can't double-resolve this round.
      const { data: updated, error: updateError } = await supabase
        .from("crossing_rounds")
        .update({ status: "busted", payout: 0, resolved_multiplier: 0, resolved_at: new Date().toISOString() })
        .eq("id", roundId)
        .eq("status", "pending")
        .select("*")
        .maybeSingle();
      if (updateError) throw new Error(`Supabase crossing.advance bust update failed: ${updateError.message}`);
      const finalRound = (updated as CrossingRoundRow | null) ?? round;
      return { round: toPublic(finalRound), balance: Number(player.credit_balance) };
    }

    if (laneIndex === round.lane_count) {
      const settings = await supabaseCrossingSettingsRepository.get();
      const ladder = buildLadder(round.lane_count, Number(round.rtp), Number(round.bust_pct));
      const multiplier = ladder[laneIndex - 1];
      const payout = Math.min(Math.floor(Number(round.bet_amount) * multiplier), settings.maxWin);

      const { data: updated, error: updateError } = await supabase
        .from("crossing_rounds")
        .update({
          current_lane: laneIndex,
          status: "collected",
          resolved_multiplier: multiplier,
          payout,
          resolved_at: new Date().toISOString(),
        })
        .eq("id", roundId)
        .eq("status", "pending")
        .select("*")
        .maybeSingle();
      if (updateError) throw new Error(`Supabase crossing.advance final-lane update failed: ${updateError.message}`);
      if (!updated) throw new Error("Round already resolved");

      const newBalance = Number(player.credit_balance) + payout;
      const { error: balanceError } = await supabase
        .from("players")
        .update({ credit_balance: newBalance, last_active_at: new Date().toISOString() })
        .eq("id", player.id);
      if (balanceError) throw new Error(`Supabase crossing.advance balance update failed: ${balanceError.message}`);

      const gameId = await findGameId(supabase);
      await supabase.from("transactions").insert({
        player_id: player.id,
        game_id: gameId ?? null,
        type: "payout",
        status: "completed",
        amount: payout,
      });
      if (gameId) await incrementGameStats(supabase, gameId, { total_payout: payout });

      return { round: toPublic(updated as CrossingRoundRow), balance: newBalance };
    }

    const { data: updated, error: updateError } = await supabase
      .from("crossing_rounds")
      .update({ current_lane: laneIndex })
      .eq("id", roundId)
      .eq("status", "pending")
      .select("*")
      .maybeSingle();
    if (updateError) throw new Error(`Supabase crossing.advance update failed: ${updateError.message}`);
    if (!updated) throw new Error("Round already resolved");

    return { round: toPublic(updated as CrossingRoundRow), balance: Number(player.credit_balance) };
  },

  async cashout({ guestId, roundId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const { data: roundRow, error: roundError } = await supabase
      .from("crossing_rounds")
      .select("*")
      .eq("id", roundId)
      .eq("player_id", player.id)
      .maybeSingle();
    if (roundError) throw new Error(`Supabase crossing.cashout round lookup failed: ${roundError.message}`);
    if (!roundRow) throw new Error("Round not found");
    const round = roundRow as CrossingRoundRow;
    if (round.status !== "pending") throw new Error("Round already resolved");
    if (round.current_lane < 1) throw new Error("Advance at least one lane before cashing out");

    const settings = await supabaseCrossingSettingsRepository.get();
    const ladder = buildLadder(round.lane_count, Number(round.rtp), Number(round.bust_pct));
    const multiplier = ladder[round.current_lane - 1];
    const payout = Math.min(Math.floor(Number(round.bet_amount) * multiplier), settings.maxWin);

    const { data: updatedRound, error: updateRoundError } = await supabase
      .from("crossing_rounds")
      .update({
        status: "collected",
        resolved_multiplier: multiplier,
        payout,
        resolved_at: new Date().toISOString(),
      })
      .eq("id", roundId)
      .eq("status", "pending")
      .select("*")
      .maybeSingle();
    if (updateRoundError) throw new Error(`Supabase crossing.cashout update failed: ${updateRoundError.message}`);
    if (!updatedRound) throw new Error("Round already resolved");

    const newBalance = Number(player.credit_balance) + payout;
    const { error: balanceError } = await supabase
      .from("players")
      .update({ credit_balance: newBalance, last_active_at: new Date().toISOString() })
      .eq("id", player.id);
    if (balanceError) throw new Error(`Supabase crossing.cashout balance update failed: ${balanceError.message}`);

    const gameId = await findGameId(supabase);
    await supabase.from("transactions").insert({
      player_id: player.id,
      game_id: gameId ?? null,
      type: "payout",
      status: "completed",
      amount: payout,
    });
    if (gameId) await incrementGameStats(supabase, gameId, { total_payout: payout });

    return { round: toPublic(updatedRound as CrossingRoundRow), balance: newBalance };
  },

  async getState({ guestId, roundId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const { data: roundRow } = await supabase
      .from("crossing_rounds")
      .select("*")
      .eq("id", roundId)
      .eq("player_id", player.id)
      .maybeSingle();
    if (!roundRow) return null;
    return toPublic(roundRow as CrossingRoundRow);
  },

  async getHistory({ guestId, accessToken, page, pageSize }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error, count } = await supabase
      .from("crossing_rounds")
      .select("*", { count: "exact" })
      .eq("player_id", player.id)
      .neq("status", "pending")
      .order("resolved_at", { ascending: false })
      .range(from, to);
    if (error) throw new Error(`Supabase crossing.getHistory failed: ${error.message}`);

    return { items: (data ?? []).map((row) => toHistoryEntry(row as CrossingRoundRow)), total: count ?? 0 };
  },

  async linkAccount({ guestId, userId, email, displayName }) {
    const supabase = getSupabaseServerClient();
    const player = await findOrCreateAccountPlayer(supabase, { userId, email, displayName, guestId });
    return { playerId: player.id, balance: Number(player.credit_balance) };
  },

  async getLeaderboard() {
    const supabase = getSupabaseServerClient();
    const gameId = await findGameId(supabase);

    let totals = { totalBets: 0, totalWagered: 0, totalPayout: 0 };
    if (gameId) {
      const { data: gameRow } = await supabase
        .from("games")
        .select("total_sessions, total_wagered, total_payout")
        .eq("id", gameId)
        .maybeSingle();
      if (gameRow) {
        totals = {
          totalBets: Number(gameRow.total_sessions),
          totalWagered: Number(gameRow.total_wagered),
          totalPayout: Number(gameRow.total_payout),
        };
      }
    }

    function toEntry(row: CrossingRoundRow): CrossingLeaderboardEntry {
      return {
        playerName: row.players?.display_name ?? "Player",
        bet: Number(row.bet_amount),
        difficulty: row.difficulty,
        multiplier: row.resolved_multiplier != null ? Number(row.resolved_multiplier) : 1,
        payout: row.payout != null ? Number(row.payout) : 0,
      };
    }

    const { data: topWinsData } = await supabase
      .from("crossing_rounds")
      .select("*, players(display_name)")
      .eq("status", "collected")
      .order("payout", { ascending: false })
      .limit(10);

    const result: CrossingLeaderboard = {
      ...totals,
      topWins: (topWinsData ?? []).map((row) => toEntry(row as CrossingRoundRow)),
    };
    return result;
  },

  async getLiveRounds() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("crossing_rounds")
      .select("*, players(display_name)")
      .eq("status", "pending")
      .order("started_at", { ascending: false });
    if (error) throw new Error(`Supabase crossing.getLiveRounds failed: ${error.message}`);

    const rows = (data ?? []) as CrossingRoundRow[];
    const entries: CrossingLiveRoundEntry[] = rows.map((row) => ({
      roundId: row.id,
      playerId: row.player_id,
      playerName: row.players?.display_name ?? "Player",
      difficulty: row.difficulty,
      betAmount: Number(row.bet_amount),
      currentLane: row.current_lane,
      laneCount: row.lane_count,
      startedAt: row.started_at,
    }));
    const totalWagered = entries.reduce((sum, e) => sum + e.betAmount, 0);
    return { rounds: entries, activeBets: entries.length, totalWagered, serverTime: new Date().toISOString() };
  },

  async emergencyStopAll() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.from("crossing_rounds").select("*").eq("status", "pending");
    if (error) throw new Error(`Supabase crossing.emergencyStopAll lookup failed: ${error.message}`);
    const pending = (data ?? []) as CrossingRoundRow[];

    let voidedCount = 0;
    let refundedTotal = 0;
    const gameId = await findGameId(supabase);

    for (const round of pending) {
      const betAmount = Number(round.bet_amount);

      const { data: updatedRound, error: updateError } = await supabase
        .from("crossing_rounds")
        .update({
          status: "busted",
          voided: true,
          payout: betAmount,
          resolved_multiplier: null,
          resolved_at: new Date().toISOString(),
        })
        .eq("id", round.id)
        .eq("status", "pending")
        .select("id")
        .maybeSingle();
      if (updateError) throw new Error(`Supabase crossing.emergencyStopAll update failed: ${updateError.message}`);
      if (!updatedRound) continue; // already resolved by something else — skip

      const { data: playerRow, error: playerError } = await supabase
        .from("players")
        .select("credit_balance")
        .eq("id", round.player_id)
        .single();
      if (playerError) throw new Error(`Supabase crossing.emergencyStopAll player lookup failed: ${playerError.message}`);

      const newBalance = Number(playerRow.credit_balance) + betAmount;
      const { error: balanceError } = await supabase
        .from("players")
        .update({ credit_balance: newBalance, last_active_at: new Date().toISOString() })
        .eq("id", round.player_id);
      if (balanceError) throw new Error(`Supabase crossing.emergencyStopAll balance update failed: ${balanceError.message}`);

      await supabase.from("transactions").insert({
        player_id: round.player_id,
        game_id: gameId ?? null,
        type: "payout",
        status: "completed",
        amount: betAmount,
        note: "Emergency stop — round voided, bet refunded",
      });
      if (gameId) await incrementGameStats(supabase, gameId, { total_wagered: -betAmount });

      voidedCount += 1;
      refundedTotal += betAmount;
    }

    return { voidedCount, refundedTotal };
  },
};
