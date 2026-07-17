import { randomUUID } from "crypto";
import { mockLatency } from "@/lib/mock/delay";
import { findOrCreateGuestPlayer } from "@/lib/mock/playerResolution";
import { seedGames, seedTransactions } from "@/lib/mock/seedData";
import { MAX_SCRATCH_COST, MIN_SCRATCH_COST, playScratch } from "@/lib/games/scratch";
import { MAX_WHEEL_BET, MIN_WHEEL_BET, spinWheel } from "@/lib/games/wheel";
import type { GameRoundRepository } from "@/lib/repositories/types";
import type { GameRoundEntry, GameRoundType, Player, Transaction } from "@/lib/types";

// Module-level singleton: same "resets on restart" tradeoff the rest of
// the mock data layer already has.
const gameRounds: GameRoundEntry[] = [];

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

function recordTransaction(player: Player, gameType: GameRoundType, type: "wager" | "payout", amount: number): void {
  const txn: Transaction = {
    id: `tx_${randomUUID().slice(0, 8)}`,
    playerId: player.id,
    playerName: player.displayName,
    type,
    status: "completed",
    amount,
    gameId: seedGames.find((g) => g.appEntryPoint === gameType)?.id,
    gameName: gameType === "wheel" ? "Lucky Wheel" : "Scratch Card",
    createdAt: new Date().toISOString(),
  };
  seedTransactions.unshift(txn);
}

// Mock mode has no real Supabase Auth to verify a JWT against — like the
// other mock game repositories, accessToken is accepted for interface
// compliance but resolution always falls back to guestId.
export const mockGameRoundRepository: GameRoundRepository = {
  async play({ gameType, guestId, bet }) {
    await mockLatency();
    const player = findOrCreateGuestPlayer(guestId);
    if (player.creditBalance < bet) throw new Error("Insufficient balance");

    const { result, winAmount } = resolveOutcome(gameType, bet);

    player.creditBalance = player.creditBalance - bet + winAmount;
    player.totalWagered += bet;
    player.gamesPlayed += 1;
    player.lastActiveAt = new Date().toISOString();

    const roundId = `gr_${randomUUID().slice(0, 8)}`;
    gameRounds.unshift({
      id: roundId,
      playerId: player.id,
      gameType,
      betAmount: bet,
      winAmount,
      result,
      createdAt: new Date().toISOString(),
    });

    recordTransaction(player, gameType, "wager", -bet);
    if (winAmount > 0) recordTransaction(player, gameType, "payout", winAmount);

    const game = seedGames.find((g) => g.appEntryPoint === gameType);
    if (game) {
      game.totalSessions += 1;
      game.totalWagered += bet;
      game.totalPayout += winAmount;
    }

    return { result, winAmount, newBalance: player.creditBalance, transactionId: roundId };
  },

  async getStats(playerId, gameType) {
    await mockLatency();
    const rows = gameRounds.filter((r) => r.playerId === playerId && r.gameType === gameType);
    const totalWagered = rows.reduce((sum, r) => sum + r.betAmount, 0);
    const totalWon = rows.reduce((sum, r) => sum + r.winAmount, 0);
    return {
      totalRounds: rows.length,
      totalWagered,
      totalWon,
      winCount: rows.filter((r) => r.winAmount > 0).length,
      netResult: totalWon - totalWagered,
    };
  },

  async getHistory(playerId, gameType, { page, pageSize }) {
    await mockLatency();
    const rows = gameRounds.filter((r) => r.playerId === playerId && r.gameType === gameType);
    const start = (page - 1) * pageSize;
    return { items: rows.slice(start, start + pageSize), total: rows.length };
  },
};
