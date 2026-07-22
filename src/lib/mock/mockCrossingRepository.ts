import { randomUUID } from "crypto";
import {
  buildLadder,
  generateServerSeed,
  hashServerSeed,
  isLaneBust,
  LANE_COUNTS,
} from "@/lib/crossing/engine";
import { mockLatency } from "@/lib/mock/delay";
import { mockCrossingSettingsRepository } from "@/lib/mock/mockCrossingSettingsRepository";
import { findOrCreateGuestPlayer } from "@/lib/mock/playerResolution";
import { seedGames, seedPlayers, seedTransactions } from "@/lib/mock/seedData";
import type { CrossingRepository } from "@/lib/repositories/types";
import type {
  CrossingDifficulty,
  CrossingHistoryEntry,
  CrossingLeaderboard,
  CrossingLeaderboardEntry,
  CrossingLiveRoundEntry,
  CrossingRoundPublic,
  CrossingSettings,
  Player,
  Transaction,
} from "@/lib/types";

interface RoundRecord {
  id: string;
  playerId: string;
  betAmount: number;
  difficulty: CrossingDifficulty;
  laneCount: number;
  bustPct: number;
  rtp: number;
  clientSeed: string;
  serverSeed: string;
  serverSeedHash: string;
  currentLane: number;
  startedAt: string;
  status: CrossingRoundPublic["status"];
  payout?: number;
  resolvedMultiplier?: number;
  resolvedAt?: string;
  voided?: boolean;
}

// Module-level singleton: fine for a single dev-server process, same
// "resets on restart" tradeoff as the rest of the mock data layer.
const rounds = new Map<string, RoundRecord>();

function bustPctForDifficulty(settings: CrossingSettings, difficulty: CrossingDifficulty): number {
  return {
    easy: settings.easyBustPct,
    medium: settings.mediumBustPct,
    hard: settings.hardBustPct,
    hardcore: settings.hardcoreBustPct,
  }[difficulty];
}

function findGame() {
  return seedGames.find((g) => g.name === "Multiplier Crossing");
}

function recordTransaction(player: Player, type: "wager" | "payout", amount: number, note?: string): void {
  const txn: Transaction = {
    id: `tx_${randomUUID().slice(0, 8)}`,
    playerId: player.id,
    playerName: player.displayName,
    type,
    status: "completed",
    amount,
    gameId: findGame()?.id,
    gameName: "Multiplier Crossing",
    note,
    createdAt: new Date().toISOString(),
  };
  seedTransactions.unshift(txn);
}

function toPublic(round: RoundRecord): CrossingRoundPublic {
  const reveal = round.status !== "pending";
  return {
    roundId: round.id,
    status: round.status,
    difficulty: round.difficulty,
    betAmount: round.betAmount,
    laneCount: round.laneCount,
    currentLane: round.currentLane,
    ladder: buildLadder(round.laneCount, round.rtp, round.bustPct),
    clientSeed: round.clientSeed,
    serverSeedHash: round.serverSeedHash,
    startedAt: round.startedAt,
    payout: round.payout,
    resolvedMultiplier: round.resolvedMultiplier,
    rtp: round.rtp,
    bustPct: round.bustPct,
    voided: round.voided,
    ...(reveal ? { serverSeed: round.serverSeed } : {}),
  };
}

function toHistoryEntry(round: RoundRecord): CrossingHistoryEntry {
  return {
    roundId: round.id,
    bet: round.betAmount,
    difficulty: round.difficulty,
    lanesCleared: round.currentLane,
    multiplier: round.status === "collected" ? (round.resolvedMultiplier ?? 1) : 0,
    winAmount: round.payout ?? 0,
    isWin: round.status === "collected",
    timestamp: round.resolvedAt ?? round.startedAt,
    voided: round.voided,
  };
}

/** A player can only have one round in flight at a time — unlike crash, there's no "join an existing flight" concept. */
function findPendingRound(playerId: string): RoundRecord | undefined {
  return Array.from(rounds.values()).find((r) => r.playerId === playerId && r.status === "pending");
}

function requireOwnedPendingRound(guestId: string, roundId: string): { round: RoundRecord; player: Player } {
  const round = rounds.get(roundId);
  const player = seedPlayers.find((p) => p.guestId === guestId);
  if (!round || !player || round.playerId !== player.id) {
    throw new Error("Round not found");
  }
  if (round.status !== "pending") {
    throw new Error("Round already resolved");
  }
  return { round, player };
}

// Mock mode has no real Supabase Auth to verify a JWT against, so unlike
// supabaseCrossingRepository it always resolves by guestId — accessToken is
// accepted (for interface compliance) but not honored. Mirrors
// mockCrashRepository's identical caveat.
export const mockCrossingRepository: CrossingRepository = {
  async getOrCreatePlayerBalance({ guestId }) {
    await mockLatency();
    const player = findOrCreateGuestPlayer(guestId);
    return { playerId: player.id, balance: player.creditBalance };
  },

  async placeBet({ guestId, betAmount, difficulty, clientSeed }) {
    await mockLatency();
    const settings = await mockCrossingSettingsRepository.get();
    if (!Number.isFinite(betAmount) || betAmount < settings.minBet || betAmount > settings.maxBet) {
      throw new Error(`Bet must be between ${settings.minBet} and ${settings.maxBet} credits`);
    }
    const player = findOrCreateGuestPlayer(guestId);
    if (player.creditBalance < betAmount) {
      throw new Error("Insufficient balance");
    }
    if (findPendingRound(player.id)) {
      throw new Error("You already have a round in progress");
    }

    const id = randomUUID();
    const serverSeed = generateServerSeed();
    const seed = clientSeed.trim() || randomUUID();
    const round: RoundRecord = {
      id,
      playerId: player.id,
      betAmount,
      difficulty,
      laneCount: LANE_COUNTS[difficulty],
      bustPct: bustPctForDifficulty(settings, difficulty),
      rtp: settings.rtp,
      clientSeed: seed,
      serverSeed,
      serverSeedHash: hashServerSeed(serverSeed),
      currentLane: 0,
      startedAt: new Date().toISOString(),
      status: "pending",
    };
    rounds.set(id, round);

    player.creditBalance -= betAmount;
    player.totalWagered += betAmount;
    player.gamesPlayed += 1;
    player.lastActiveAt = round.startedAt;
    recordTransaction(player, "wager", -betAmount);

    const game = findGame();
    if (game) {
      game.totalSessions += 1;
      game.totalWagered += betAmount;
    }

    return { round: toPublic(round), balance: player.creditBalance };
  },

  async advance({ guestId, roundId }) {
    await mockLatency();
    const { round, player } = requireOwnedPendingRound(guestId, roundId);

    const laneIndex = round.currentLane + 1;
    const bust = isLaneBust(round.serverSeed, round.clientSeed, round.id, laneIndex, round.bustPct);

    if (bust) {
      round.status = "busted";
      round.payout = 0;
      round.resolvedMultiplier = 0;
      round.resolvedAt = new Date().toISOString();
      player.lastActiveAt = round.resolvedAt;
      return { round: toPublic(round), balance: player.creditBalance };
    }

    round.currentLane = laneIndex;
    if (laneIndex === round.laneCount) {
      const settings = await mockCrossingSettingsRepository.get();
      const ladder = buildLadder(round.laneCount, round.rtp, round.bustPct);
      const multiplier = ladder[laneIndex - 1];
      const payout = Math.min(Math.floor(round.betAmount * multiplier), settings.maxWin);

      round.status = "collected";
      round.resolvedMultiplier = multiplier;
      round.payout = payout;
      round.resolvedAt = new Date().toISOString();

      player.creditBalance += payout;
      player.lastActiveAt = round.resolvedAt;
      recordTransaction(player, "payout", payout);

      const game = findGame();
      if (game) game.totalPayout += payout;
    }

    return { round: toPublic(round), balance: player.creditBalance };
  },

  async cashout({ guestId, roundId }) {
    await mockLatency();
    const { round, player } = requireOwnedPendingRound(guestId, roundId);
    if (round.currentLane < 1) {
      throw new Error("Advance at least one lane before cashing out");
    }

    const settings = await mockCrossingSettingsRepository.get();
    const ladder = buildLadder(round.laneCount, round.rtp, round.bustPct);
    const multiplier = ladder[round.currentLane - 1];
    const payout = Math.min(Math.floor(round.betAmount * multiplier), settings.maxWin);

    round.status = "collected";
    round.resolvedMultiplier = multiplier;
    round.payout = payout;
    round.resolvedAt = new Date().toISOString();

    player.creditBalance += payout;
    player.lastActiveAt = round.resolvedAt;
    recordTransaction(player, "payout", payout);

    const game = findGame();
    if (game) game.totalPayout += payout;

    return { round: toPublic(round), balance: player.creditBalance };
  },

  async getState({ guestId, roundId }) {
    await mockLatency();
    const round = rounds.get(roundId);
    const player = seedPlayers.find((p) => p.guestId === guestId);
    if (!round || !player || round.playerId !== player.id) return null;
    return toPublic(round);
  },

  async linkAccount({ guestId, userId, email, displayName }) {
    await mockLatency();
    const accountPlayer = seedPlayers.find((p) => p.userId === userId);
    if (accountPlayer) {
      return { playerId: accountPlayer.id, balance: accountPlayer.creditBalance };
    }

    const player = findOrCreateGuestPlayer(guestId);
    player.userId = userId;
    player.email = email;
    if (displayName) player.displayName = displayName;
    return { playerId: player.id, balance: player.creditBalance };
  },

  async getHistory({ guestId, page, pageSize }) {
    await mockLatency();
    const player = seedPlayers.find((p) => p.guestId === guestId);
    if (!player) return { items: [], total: 0 };

    const playerRounds = Array.from(rounds.values())
      .filter((r) => r.playerId === player.id && r.status !== "pending")
      .sort((a, b) => new Date(b.resolvedAt ?? b.startedAt).getTime() - new Date(a.resolvedAt ?? a.startedAt).getTime());

    const start = (page - 1) * pageSize;
    const items = playerRounds.slice(start, start + pageSize).map(toHistoryEntry);
    return { items, total: playerRounds.length };
  },

  async getLeaderboard() {
    await mockLatency();
    const game = findGame();
    const resolved = Array.from(rounds.values()).filter((r) => r.status !== "pending");

    const topWins: CrossingLeaderboardEntry[] = resolved
      .filter((r) => r.status === "collected")
      .sort((a, b) => (b.payout ?? 0) - (a.payout ?? 0))
      .slice(0, 10)
      .map((round) => ({
        playerName: seedPlayers.find((p) => p.id === round.playerId)?.displayName ?? "Player",
        bet: round.betAmount,
        difficulty: round.difficulty,
        multiplier: round.resolvedMultiplier ?? 1,
        payout: round.payout ?? 0,
      }));

    const result: CrossingLeaderboard = {
      totalBets: game?.totalSessions ?? 0,
      totalWagered: game?.totalWagered ?? 0,
      totalPayout: game?.totalPayout ?? 0,
      topWins,
    };
    return result;
  },

  async getLiveRounds() {
    await mockLatency();
    const entries: CrossingLiveRoundEntry[] = [];
    let totalWagered = 0;
    for (const round of rounds.values()) {
      if (round.status !== "pending") continue;
      const player = seedPlayers.find((p) => p.id === round.playerId);
      entries.push({
        roundId: round.id,
        playerId: round.playerId,
        playerName: player?.displayName ?? "Player",
        difficulty: round.difficulty,
        betAmount: round.betAmount,
        currentLane: round.currentLane,
        laneCount: round.laneCount,
        startedAt: round.startedAt,
      });
      totalWagered += round.betAmount;
    }
    return { rounds: entries, activeBets: entries.length, totalWagered, serverTime: new Date().toISOString() };
  },

  async emergencyStopAll() {
    await mockLatency();
    let voidedCount = 0;
    let refundedTotal = 0;
    const game = findGame();
    for (const round of rounds.values()) {
      if (round.status !== "pending") continue;
      const player = seedPlayers.find((p) => p.id === round.playerId);
      if (!player) continue;

      round.status = "busted";
      round.voided = true;
      round.payout = round.betAmount;
      round.resolvedMultiplier = undefined;
      round.resolvedAt = new Date().toISOString();

      player.creditBalance += round.betAmount;
      player.lastActiveAt = round.resolvedAt;
      recordTransaction(player, "payout", round.betAmount, "Emergency stop — round voided, bet refunded");
      if (game) game.totalWagered -= round.betAmount;

      voidedCount += 1;
      refundedTotal += round.betAmount;
    }
    return { voidedCount, refundedTotal };
  },
};
