import type { SupabaseClient } from "@supabase/supabase-js";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapGameRoundRow } from "@/lib/supabase/mappers";
import { resolvePlayer } from "@/lib/supabase/playerResolution";
import { MAX_SCRATCH_COST, MIN_SCRATCH_COST, playScratch } from "@/lib/games/scratch";
import { MAX_WHEEL_BET, MIN_WHEEL_BET, spinWheel } from "@/lib/games/wheel";
import type { GameRoundRepository } from "@/lib/repositories/types";
import type { GameRoundType } from "@/lib/types";

async function findGameId(supabase: SupabaseClient, entryPoint: GameRoundType): Promise<string | undefined> {
  const { data } = await supabase.from("games").select("id").eq("app_entry_point", entryPoint).maybeSingle();
  return (data?.id as string | undefined) ?? undefined;
}

function resolveOutcome(gameType: GameRoundType, bet: number): { result: unknown; winAmount: number } {
  if (gameType === "wheel") {
    if (!Number.isFinite(bet) || bet < MIN_WHEEL_BET || bet > MAX_WHEEL_BET) {
      throw new Error(`Bet must be between ${MIN_WHEEL_BET} and ${MAX_WHEEL_BET} credits`);
    }
    const result = spinWheel(bet);
    return { result, winAmount: result.winAmount };
  }

  if (!Number.isFinite(bet) || bet < MIN_SCRATCH_COST || bet > MAX_SCRATCH_COST) {
    throw new Error(`Cost must be between ${MIN_SCRATCH_COST} and ${MAX_SCRATCH_COST} credits`);
  }
  const result = playScratch(bet);
  return { result, winAmount: result.winAmount };
}

export const supabaseGameRoundRepository: GameRoundRepository = {
  async play({ gameType, guestId, accessToken, bet }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);
    const balance = Number(player.credit_balance);
    if (balance < bet) throw new Error("Insufficient balance");

    // Decide the outcome only after the balance check, so a rejected bet
    // never consumes an RNG draw.
    const { result, winAmount } = resolveOutcome(gameType, bet);
    const newBalance = balance - bet + winAmount;

    const { error: balanceError } = await supabase
      .from("players")
      .update({
        credit_balance: newBalance,
        total_wagered: Number(player.total_wagered) + bet,
        games_played: Number(player.games_played) + 1,
        last_active_at: new Date().toISOString(),
      })
      .eq("id", player.id);
    if (balanceError) throw new Error(`Supabase gameRound.play balance update failed: ${balanceError.message}`);

    const { data: round, error: roundError } = await supabase
      .from("game_rounds")
      .insert({ player_id: player.id, game_type: gameType, bet_amount: bet, win_amount: winAmount, result })
      .select("id")
      .single();
    if (roundError) throw new Error(`Supabase gameRound.play round insert failed: ${roundError.message}`);

    const gameId = await findGameId(supabase, gameType);
    let transactionId = round.id as string;
    if (gameId) {
      const { data: wagerTxn, error: wagerError } = await supabase
        .from("transactions")
        .insert({ player_id: player.id, game_id: gameId, type: "wager", status: "completed", amount: -bet })
        .select("id")
        .single();
      if (wagerError) throw new Error(`Supabase gameRound.play wager insert failed: ${wagerError.message}`);
      transactionId = wagerTxn.id as string;

      if (winAmount > 0) {
        await supabase.from("transactions").insert({
          player_id: player.id,
          game_id: gameId,
          type: "payout",
          status: "completed",
          amount: winAmount,
        });
      }

      const { data: gameRow } = await supabase
        .from("games")
        .select("total_sessions, total_wagered, total_payout")
        .eq("id", gameId)
        .maybeSingle();
      if (gameRow) {
        await supabase
          .from("games")
          .update({
            total_sessions: Number(gameRow.total_sessions) + 1,
            total_wagered: Number(gameRow.total_wagered) + bet,
            total_payout: Number(gameRow.total_payout) + winAmount,
          })
          .eq("id", gameId);
      }
    }

    return { result, winAmount, newBalance, transactionId };
  },

  async getStats(playerId, gameType) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("game_rounds")
      .select("bet_amount, win_amount")
      .eq("player_id", playerId)
      .eq("game_type", gameType);
    if (error) throw new Error(`Supabase gameRound.getStats failed: ${error.message}`);

    const rows = data ?? [];
    const totalWagered = rows.reduce((sum, r) => sum + Number(r.bet_amount), 0);
    const totalWon = rows.reduce((sum, r) => sum + Number(r.win_amount), 0);
    return {
      totalRounds: rows.length,
      totalWagered,
      totalWon,
      winCount: rows.filter((r) => Number(r.win_amount) > 0).length,
      netResult: totalWon - totalWagered,
    };
  },

  async getHistory(playerId, gameType, { page, pageSize }) {
    const supabase = getSupabaseServerClient();
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error, count } = await supabase
      .from("game_rounds")
      .select("*", { count: "exact" })
      .eq("player_id", playerId)
      .eq("game_type", gameType)
      .order("created_at", { ascending: false })
      .range(from, to);
    if (error) throw new Error(`Supabase gameRound.getHistory failed: ${error.message}`);

    return { items: (data ?? []).map(mapGameRoundRow), total: count ?? 0 };
  },
};
