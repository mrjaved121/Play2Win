import type { SupabaseClient } from "@supabase/supabase-js";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapSlotSpinRow } from "@/lib/supabase/mappers";
import { resolvePlayer } from "@/lib/supabase/playerResolution";
import type { SlotsRepository } from "@/lib/repositories/types";

async function findSlotGameId(supabase: SupabaseClient): Promise<string | undefined> {
  const { data } = await supabase.from("games").select("id").eq("app_entry_point", "slots").maybeSingle();
  return (data?.id as string | undefined) ?? undefined;
}

export const supabaseSlotsRepository: SlotsRepository = {
  async recordSpin({ guestId, accessToken, bet, winAmount, isWin, isJackpot, outcome, symbols, clientBalance }) {
    const supabase = getSupabaseServerClient();
    const player = await resolvePlayer(supabase, guestId, accessToken);

    // Null slot_balance means this row has never synced a spin before —
    // seed it from the device's existing local progress instead of
    // resetting a player who already had local-only history. After that,
    // the server is authoritative and clientBalance is only ever a
    // reported figure, never trusted for the balance math.
    const isFirstSync = player.slot_balance === null;
    const newBalance = isFirstSync
      ? Math.max(0, Math.round(clientBalance))
      : Math.max(0, Number(player.slot_balance) - bet + winAmount);

    const { error: updateError } = await supabase
      .from("players")
      .update({
        slot_balance: newBalance,
        total_wagered: Number(player.total_wagered) + bet,
        games_played: Number(player.games_played) + 1,
        last_active_at: new Date().toISOString(),
      })
      .eq("id", player.id);
    if (updateError) throw new Error(`Supabase slots.recordSpin balance update failed: ${updateError.message}`);

    const { error: historyError } = await supabase.from("spin_history").insert({
      player_id: player.id,
      bet,
      win_amount: winAmount,
      is_win: isWin,
      jackpot_hit: isJackpot,
      outcome,
      symbols,
    });
    if (historyError) throw new Error(`Supabase slots.recordSpin history insert failed: ${historyError.message}`);

    const gameId = await findSlotGameId(supabase);
    if (gameId) {
      if (bet > 0) {
        await supabase.from("transactions").insert({
          player_id: player.id,
          game_id: gameId,
          type: "wager",
          status: "completed",
          amount: -bet,
        });
      }
      if (winAmount > 0) {
        await supabase.from("transactions").insert({
          player_id: player.id,
          game_id: gameId,
          type: isJackpot ? "bonus" : "payout",
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

    return { balance: newBalance };
  },

  async getStats(playerId) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("spin_history")
      .select("bet, win_amount, is_win, jackpot_hit")
      .eq("player_id", playerId);
    if (error) throw new Error(`Supabase slots.getStats failed: ${error.message}`);

    const rows = data ?? [];
    const totalWagered = rows.reduce((sum, r) => sum + Number(r.bet), 0);
    const totalWon = rows.reduce((sum, r) => sum + Number(r.win_amount), 0);
    return {
      totalSpins: rows.length,
      totalWagered,
      totalWon,
      winCount: rows.filter((r) => r.is_win).length,
      jackpotCount: rows.filter((r) => r.jackpot_hit).length,
      netResult: totalWon - totalWagered,
    };
  },

  async getHistory(playerId, { page, pageSize }) {
    const supabase = getSupabaseServerClient();
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error, count } = await supabase
      .from("spin_history")
      .select("*", { count: "exact" })
      .eq("player_id", playerId)
      .order("created_at", { ascending: false })
      .range(from, to);
    if (error) throw new Error(`Supabase slots.getHistory failed: ${error.message}`);

    return { items: (data ?? []).map(mapSlotSpinRow), total: count ?? 0 };
  },
};
