import { randomUUID } from "crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  computeCrashPoint,
  generateServerSeed,
  GROWTH_RATE,
  hashServerSeed,
  multiplierAtElapsed,
  secondsUntilCrash,
} from "@/lib/crash/engine";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import { findOrCreateAccountPlayer, resolvePlayer } from "@/lib/supabase/playerResolution";
import { supabaseCrashSettingsRepository } from "@/lib/supabase/supabaseCrashSettingsRepository";
import type { CrashRepository } from "@/lib/repositories/types";
import type {
  CrashHistoryEntry,
  CrashLeaderboard,
  CrashLeaderboardEntry,
  CrashLiveRoundEntry,
  CrashRoundPublic,
} from "@/lib/types";

interface CrashRoundRow {
  id: string;
  player_id: string;
  bet_amount: number;
  growth_rate: number;
  crash_point: number;
  rtp: number;
  instant_crash_rate: number;
  server_seed: string;
  server_seed_hash: string;
  status: CrashRoundPublic["status"];
  payout: number | null;
  resolved_multiplier: number | null;
  started_at: string;
  resolved_at: string | null;
  voided: boolean;
  players?: { display_name?: string } | null;
}

function toHistoryEntry(row: CrashRoundRow): CrashHistoryEntry {
  return {
    roundId: row.id,
    bet: Number(row.bet_amount),
    multiplier: row.status === "collected" ? Number(row.resolved_multiplier) : Number(row.crash_point),
    crashPoint: Number(row.crash_point),
    winAmount: row.payout != null ? Number(row.payout) : 0,
    isWin: row.status === "collected",
    timestamp: row.resolved_at ?? row.started_at,
    voided: row.voided,
  };
}

type GameStatColumn = "total_sessions" | "total_wagered" | "total_payout";

/** Adds each given delta to a `games` aggregate column — same read-then-write pattern used by the slots and wheel/scratch repositories. */
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

function toPublic(row: CrashRoundRow): CrashRoundPublic {
  const reveal = row.status !== "pending";
  return {
    roundId: row.id,
    status: row.status,
    betAmount: Number(row.bet_amount),
    startedAt: row.started_at,
    growthRate: Number(row.growth_rate),
    serverSeedHash: row.server_seed_hash,
    payout: row.payout != null ? Number(row.payout) : undefined,
    resolvedMultiplier: row.resolved_multiplier != null ? Number(row.resolved_multiplier) : undefined,
    rtp: row.rtp != null ? Number(row.rtp) : undefined,
    instantCrashRate: row.instant_crash_rate != null ? Number(row.instant_crash_rate) : undefined,
    voided: row.voided,
    ...(reveal ? { crashPoint: Number(row.crash_point), serverSeed: row.server_seed } : {}),
  };
}

async function findGameId(supabase: SupabaseClient): Promise<string | undefined> {
  const { data } = await supabase.from("games").select("id").eq("name", "Multiplier Climb").maybeSingle();
  return (data?.id as string | undefined) ?? undefined;
}

/**
 * A still-flying round (its hidden crash time hasn't passed yet) this
 * player already has, if any — lets a second bet ride the same flight as
 * an earlier one instead of always starting a fresh crash point. Not
 * gated on `status`: a round the player already collected is still a
 * valid flight to join, since the underlying rocket keeps climbing for
 * anyone else riding it until the crash point actually passes.
 */
async function findJoinableRound(supabase: SupabaseClient, playerId: string): Promise<CrashRoundRow | undefined> {
  const { data } = await supabase
    .from("crash_rounds")
    .select("*")
    .eq("player_id", playerId)
    .order("started_at", { ascending: false })
    .limit(5);
  const candidates = (data ?? []) as CrashRoundRow[];
  return candidates.find((r) => {
    const elapsedSeconds = (Date.now() - new Date(r.started_at).getTime()) / 1000;
    return elapsedSeconds < secondsUntilCrash(Number(r.crash_point));
  });
}

/**
 * Flips a still-pending round to "crashed" once its hidden crash time has
 * passed. Guarded by `.eq("status", "pending")` on the update so two
 * concurrent requests (e.g. a `collect` racing a `getState` reconciliation
 * poll) can't both "win" the transition; the loser just re-reads whatever
 * the winner left behind.
 */
async function settleIfCrashed(supabase: SupabaseClient, round: CrashRoundRow): Promise<CrashRoundRow> {
  if (round.status !== "pending") return round;
  const elapsedSeconds = (Date.now() - new Date(round.started_at).getTime()) / 1000;
  if (elapsedSeconds < secondsUntilCrash(Number(round.crash_point))) return round;

  const { data, error } = await supabase
    .from("crash_rounds")
    .update({ status: "crashed", resolved_at: new Date().toISOString() })
    .eq("id", round.id)
    .eq("status", "pending")
    .select("*")
    .maybeSingle();
  if (error) throw new Error(`Supabase crash.settle failed: ${error.message}`);
  if (data) return data as CrashRoundRow;

  const { data: fresh, error: freshError } = await supabase
    .from("crash_rounds")
    .select("*")
    .eq("id", round.id)
    .single();
  if (freshError) throw new Error(`Supabase crash.settle refetch failed: ${freshError.message}`);
  return fresh as CrashRoundRow;
}

export const supabaseCrashRepository: CrashRepository = {
  async getOrCreatePlayerBalance({ guestId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);
    return { playerId: player.id, balance: Number(player.credit_balance) };
  },

  async placeBet({ guestId, betAmount, accessToken }) {
    const settings = await supabaseCrashSettingsRepository.get();
    if (!Number.isFinite(betAmount) || betAmount < settings.minBet || betAmount > settings.maxBet) {
      throw new Error(`Bet must be between ${settings.minBet} and ${settings.maxBet} credits`);
    }
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);
    const balance = Number(player.credit_balance);
    if (balance < betAmount) throw new Error("Insufficient balance");

    // The round id feeds the crash-point HMAC, so it's minted here rather
    // than left to Postgres's default so we can compute crashPoint before
    // the insert — except when joining an existing flight, where the
    // crash point/seed/rtp/instantCrashRate must be copied verbatim (NOT
    // re-derived from this new id, or re-read from settings which may have
    // changed since) so both bets share the exact same rocket.
    const roundId = randomUUID();
    const joinable = await findJoinableRound(supabase, player.id);
    const serverSeed = joinable ? joinable.server_seed : generateServerSeed();
    const rtp = joinable ? Number(joinable.rtp) : settings.rtp;
    const instantCrashRate = joinable ? Number(joinable.instant_crash_rate) : settings.instantCrashRate;
    const crashPoint = joinable
      ? Number(joinable.crash_point)
      : computeCrashPoint(serverSeed, roundId, rtp, instantCrashRate);

    const { data: round, error: roundError } = await supabase
      .from("crash_rounds")
      .insert({
        id: roundId,
        player_id: player.id,
        bet_amount: betAmount,
        growth_rate: GROWTH_RATE,
        crash_point: crashPoint,
        rtp,
        instant_crash_rate: instantCrashRate,
        server_seed: serverSeed,
        server_seed_hash: joinable ? joinable.server_seed_hash : hashServerSeed(serverSeed),
        started_at: joinable ? joinable.started_at : new Date().toISOString(),
        status: "pending",
      })
      .select("*")
      .single();
    if (roundError) throw new Error(`Supabase crash.placeBet failed: ${roundError.message}`);

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
    if (updateError) throw new Error(`Supabase crash.placeBet balance update failed: ${updateError.message}`);

    const gameId = await findGameId(supabase);
    await supabase.from("transactions").insert({
      player_id: player.id,
      game_id: gameId ?? null,
      type: "wager",
      status: "completed",
      amount: -betAmount,
    });
    if (gameId) await incrementGameStats(supabase, gameId, { total_sessions: 1, total_wagered: betAmount });

    return { round: toPublic(round as CrashRoundRow), balance: newBalance };
  },

  async collect({ guestId, roundId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const { data: roundRow, error: roundError } = await supabase
      .from("crash_rounds")
      .select("*")
      .eq("id", roundId)
      .eq("player_id", player.id)
      .maybeSingle();
    if (roundError) throw new Error(`Supabase crash.collect round lookup failed: ${roundError.message}`);
    if (!roundRow) throw new Error("Round not found");
    if ((roundRow as CrashRoundRow).status !== "pending") throw new Error("Round already resolved");

    const settled = await settleIfCrashed(supabase, roundRow as CrashRoundRow);
    if (settled.status === "crashed") {
      return { round: toPublic(settled), balance: Number(player.credit_balance) };
    }

    const elapsedSeconds = (Date.now() - new Date(settled.started_at).getTime()) / 1000;
    const multiplier = multiplierAtElapsed(elapsedSeconds);
    const payout = Math.floor(Number(settled.bet_amount) * multiplier);

    const { data: updatedRound, error: updateRoundError } = await supabase
      .from("crash_rounds")
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
    if (updateRoundError) throw new Error(`Supabase crash.collect update failed: ${updateRoundError.message}`);
    if (!updatedRound) throw new Error("Round already resolved");

    const newBalance = Number(player.credit_balance) + payout;
    const { error: balanceError } = await supabase
      .from("players")
      .update({ credit_balance: newBalance, last_active_at: new Date().toISOString() })
      .eq("id", player.id);
    if (balanceError) throw new Error(`Supabase crash.collect balance update failed: ${balanceError.message}`);

    const gameId = await findGameId(supabase);
    await supabase.from("transactions").insert({
      player_id: player.id,
      game_id: gameId ?? null,
      type: "payout",
      status: "completed",
      amount: payout,
    });
    if (gameId) await incrementGameStats(supabase, gameId, { total_payout: payout });

    return { round: toPublic(updatedRound as CrashRoundRow), balance: newBalance };
  },

  async getState({ guestId, roundId, accessToken }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const { data: roundRow } = await supabase
      .from("crash_rounds")
      .select("*")
      .eq("id", roundId)
      .eq("player_id", player.id)
      .maybeSingle();
    if (!roundRow) return null;

    const settled = await settleIfCrashed(supabase, roundRow as CrashRoundRow);
    return toPublic(settled);
  },

  async getHistory({ guestId, accessToken, page, pageSize }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error, count } = await supabase
      .from("crash_rounds")
      .select("*", { count: "exact" })
      .eq("player_id", player.id)
      .neq("status", "pending")
      .order("resolved_at", { ascending: false })
      .range(from, to);
    if (error) throw new Error(`Supabase crash.getHistory failed: ${error.message}`);

    return { items: (data ?? []).map((row) => toHistoryEntry(row as CrashRoundRow)), total: count ?? 0 };
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

    function toEntry(row: CrashRoundRow & { players?: { display_name?: string } | null }): CrashLeaderboardEntry {
      return {
        playerName: row.players?.display_name ?? "Player",
        bet: Number(row.bet_amount),
        multiplier: row.status === "collected" ? Number(row.resolved_multiplier) : Number(row.crash_point),
        payout: row.payout != null ? Number(row.payout) : 0,
      };
    }

    const { data: topWinsData } = await supabase
      .from("crash_rounds")
      .select("*, players(display_name)")
      .eq("status", "collected")
      .order("payout", { ascending: false })
      .limit(10);

    const { data: topBetsData } = await supabase
      .from("crash_rounds")
      .select("*, players(display_name)")
      .neq("status", "pending")
      .order("bet_amount", { ascending: false })
      .limit(10);

    const result: CrashLeaderboard = {
      ...totals,
      topWins: (topWinsData ?? []).map(toEntry),
      topBets: (topBetsData ?? []).map(toEntry),
    };
    return result;
  },

  async getLiveRounds() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("crash_rounds")
      .select("*, players(display_name)")
      .eq("status", "pending")
      .order("started_at", { ascending: false });
    if (error) throw new Error(`Supabase crash.getLiveRounds failed: ${error.message}`);

    const rows = (data ?? []) as CrashRoundRow[];
    const entries: CrashLiveRoundEntry[] = [];
    let totalWagered = 0;
    for (const row of rows) {
      const elapsedSeconds = (Date.now() - new Date(row.started_at).getTime()) / 1000;
      // See the mock repository's identical guard: don't surface a round
      // as "live" once its hidden crash time has actually passed, but
      // don't mutate it from this read-only admin view either.
      if (elapsedSeconds >= secondsUntilCrash(Number(row.crash_point))) continue;

      entries.push({
        roundId: row.id,
        playerId: row.player_id,
        playerName: row.players?.display_name ?? "Player",
        betAmount: Number(row.bet_amount),
        startedAt: row.started_at,
        growthRate: Number(row.growth_rate),
      });
      totalWagered += Number(row.bet_amount);
    }
    return { rounds: entries, activeBets: entries.length, totalWagered, serverTime: new Date().toISOString() };
  },

  async emergencyStopAll() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.from("crash_rounds").select("*").eq("status", "pending");
    if (error) throw new Error(`Supabase crash.emergencyStopAll lookup failed: ${error.message}`);
    const pending = (data ?? []) as CrashRoundRow[];

    let voidedCount = 0;
    let refundedTotal = 0;
    const gameId = await findGameId(supabase);

    for (const round of pending) {
      const betAmount = Number(round.bet_amount);

      const { data: updatedRound, error: updateError } = await supabase
        .from("crash_rounds")
        .update({
          status: "crashed",
          voided: true,
          payout: betAmount,
          resolved_multiplier: null,
          resolved_at: new Date().toISOString(),
        })
        .eq("id", round.id)
        .eq("status", "pending")
        .select("id")
        .maybeSingle();
      if (updateError) throw new Error(`Supabase crash.emergencyStopAll update failed: ${updateError.message}`);
      if (!updatedRound) continue; // already resolved by something else (e.g. a collect that raced this) — skip

      const { data: playerRow, error: playerError } = await supabase
        .from("players")
        .select("credit_balance")
        .eq("id", round.player_id)
        .single();
      if (playerError) throw new Error(`Supabase crash.emergencyStopAll player lookup failed: ${playerError.message}`);

      const newBalance = Number(playerRow.credit_balance) + betAmount;
      const { error: balanceError } = await supabase
        .from("players")
        .update({ credit_balance: newBalance, last_active_at: new Date().toISOString() })
        .eq("id", round.player_id);
      if (balanceError) throw new Error(`Supabase crash.emergencyStopAll balance update failed: ${balanceError.message}`);

      await supabase.from("transactions").insert({
        player_id: round.player_id,
        game_id: gameId ?? null,
        type: "payout",
        status: "completed",
        amount: betAmount,
        note: "Emergency stop — round voided, bet refunded",
      });
      // Undoes this round's earlier totalWagered increment so a voided
      // round nets to zero in revenue reporting instead of reading as
      // "wagered but never paid out".
      if (gameId) await incrementGameStats(supabase, gameId, { total_wagered: -betAmount });

      voidedCount += 1;
      refundedTotal += betAmount;
    }

    return { voidedCount, refundedTotal };
  },
};
