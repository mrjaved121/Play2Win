import { randomUUID } from "crypto";
import { mockLatency } from "@/lib/mock/delay";
import { findOrCreateGuestPlayer } from "@/lib/mock/playerResolution";
import { seedGames, seedTransactions } from "@/lib/mock/seedData";
import type { SlotsRepository } from "@/lib/repositories/types";
import type { Player, SlotSpinEntry, Transaction } from "@/lib/types";

// Module-level singleton: same "resets on restart" tradeoff the rest of
// the mock data layer already has.
const spinHistory: SlotSpinEntry[] = [];

function findSlotGameId(): string | undefined {
  return seedGames.find((g) => g.appEntryPoint === "slots")?.id;
}

// Mock mode has no real Supabase Auth to verify a JWT against — like
// mockCrashRepository, accessToken is accepted for interface compliance
// but resolution always falls back to guestId.
function resolvePlayer(guestId: string): Player {
  return findOrCreateGuestPlayer(guestId);
}

function recordTransaction(player: Player, type: "wager" | "payout" | "bonus", amount: number): void {
  const txn: Transaction = {
    id: `tx_${randomUUID().slice(0, 8)}`,
    playerId: player.id,
    playerName: player.displayName,
    type,
    status: "completed",
    amount,
    gameId: findSlotGameId(),
    gameName: "Nova Slots",
    createdAt: new Date().toISOString(),
  };
  seedTransactions.unshift(txn);
}

export const mockSlotsRepository: SlotsRepository = {
  async recordSpin({ guestId, bet, winAmount, isWin, isJackpot, outcome, symbols, clientBalance }) {
    await mockLatency();
    const player = resolvePlayer(guestId);

    const isFirstSync = player.slotBalance === undefined;
    const newBalance = isFirstSync
      ? Math.max(0, Math.round(clientBalance))
      : Math.max(0, player.slotBalance! - bet + winAmount);

    player.slotBalance = newBalance;
    player.totalWagered += bet;
    player.gamesPlayed += 1;
    player.lastActiveAt = new Date().toISOString();

    spinHistory.unshift({
      id: `sp_${randomUUID().slice(0, 8)}`,
      playerId: player.id,
      bet,
      winAmount,
      isWin,
      isJackpot,
      outcome,
      symbols,
      createdAt: new Date().toISOString(),
    });

    if (bet > 0) recordTransaction(player, "wager", -bet);
    if (winAmount > 0) recordTransaction(player, isJackpot ? "bonus" : "payout", winAmount);

    const game = seedGames.find((g) => g.appEntryPoint === "slots");
    if (game) {
      game.totalSessions += 1;
      game.totalWagered += bet;
      game.totalPayout += winAmount;
    }

    return { balance: newBalance };
  },

  async getStats(playerId) {
    await mockLatency();
    const rows = spinHistory.filter((s) => s.playerId === playerId);
    const totalWagered = rows.reduce((sum, r) => sum + r.bet, 0);
    const totalWon = rows.reduce((sum, r) => sum + r.winAmount, 0);
    return {
      totalSpins: rows.length,
      totalWagered,
      totalWon,
      winCount: rows.filter((r) => r.isWin).length,
      jackpotCount: rows.filter((r) => r.isJackpot).length,
      netResult: totalWon - totalWagered,
    };
  },

  async getHistory(playerId, { page, pageSize }) {
    await mockLatency();
    const rows = spinHistory.filter((s) => s.playerId === playerId);
    const start = (page - 1) * pageSize;
    return { items: rows.slice(start, start + pageSize), total: rows.length };
  },
};
