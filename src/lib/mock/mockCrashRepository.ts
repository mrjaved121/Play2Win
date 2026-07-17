import { randomUUID } from "crypto";
import {
  computeCrashPoint,
  generateServerSeed,
  GROWTH_RATE,
  hashServerSeed,
  MAX_BET,
  MIN_BET,
  multiplierAtElapsed,
  secondsUntilCrash,
} from "@/lib/crash/engine";
import { mockLatency } from "@/lib/mock/delay";
import { findOrCreateGuestPlayer } from "@/lib/mock/playerResolution";
import { seedGames, seedPlayers, seedTransactions } from "@/lib/mock/seedData";
import type { CrashRepository } from "@/lib/repositories/types";
import type { CrashHistoryEntry, CrashRoundPublic, Player, Transaction } from "@/lib/types";

interface RoundRecord {
  id: string;
  playerId: string;
  betAmount: number;
  serverSeed: string;
  serverSeedHash: string;
  crashPoint: number;
  startedAt: string;
  status: CrashRoundPublic["status"];
  payout?: number;
  resolvedMultiplier?: number;
  resolvedAt?: string;
}

function toHistoryEntry(round: RoundRecord): CrashHistoryEntry {
  return {
    roundId: round.id,
    bet: round.betAmount,
    multiplier: round.status === "collected" ? (round.resolvedMultiplier ?? 1) : round.crashPoint,
    winAmount: round.payout ?? 0,
    isWin: round.status === "collected",
    timestamp: round.resolvedAt ?? round.startedAt,
  };
}

// Module-level singletons: fine for a single dev-server process (same
// "resets on restart" tradeoff the rest of the mock data layer already
// has — see README.md's Known limitations).
const rounds = new Map<string, RoundRecord>();

function findGameId(): string | undefined {
  return seedGames.find((g) => g.name === "Multiplier Climb")?.id;
}

function recordTransaction(player: Player, type: "wager" | "payout", amount: number): void {
  const txn: Transaction = {
    id: `tx_${randomUUID().slice(0, 8)}`,
    playerId: player.id,
    playerName: player.displayName,
    type,
    status: "completed",
    amount,
    gameId: findGameId(),
    gameName: "Multiplier Climb",
    createdAt: new Date().toISOString(),
  };
  seedTransactions.unshift(txn);
}

function toPublic(round: RoundRecord): CrashRoundPublic {
  const reveal = round.status !== "pending";
  return {
    roundId: round.id,
    status: round.status,
    betAmount: round.betAmount,
    startedAt: round.startedAt,
    growthRate: GROWTH_RATE,
    serverSeedHash: round.serverSeedHash,
    payout: round.payout,
    resolvedMultiplier: round.resolvedMultiplier,
    ...(reveal ? { crashPoint: round.crashPoint, serverSeed: round.serverSeed } : {}),
  };
}

/**
 * Lazily settles a still-pending round if its hidden crash time has
 * passed, returning the (possibly just-updated) status. Callers should
 * use the return value rather than re-reading `round.status` themselves —
 * TS's control-flow narrowing doesn't know this function can mutate it.
 */
function settleIfCrashed(round: RoundRecord): RoundRecord["status"] {
  if (round.status === "pending") {
    const elapsedSeconds = (Date.now() - new Date(round.startedAt).getTime()) / 1000;
    if (elapsedSeconds >= secondsUntilCrash(round.crashPoint)) {
      round.status = "crashed";
      round.resolvedAt = new Date().toISOString();
    }
  }
  return round.status;
}

function requireOwnedRound(guestId: string, roundId: string): { round: RoundRecord; player: Player } {
  const round = rounds.get(roundId);
  const player = seedPlayers.find((p) => p.guestId === guestId);
  if (!round || !player || round.playerId !== player.id) {
    throw new Error("Round not found");
  }
  return { round, player };
}

// Mock mode has no real Supabase Auth to verify a JWT against, so unlike
// supabaseCrashRepository it always resolves by guestId — accessToken is
// accepted (for interface compliance) but not honored. Cross-device
// portability isn't meaningfully testable without a real Supabase project;
// see linkAccount for the one thing mock mode does track (userId tagging).
export const mockCrashRepository: CrashRepository = {
  async getOrCreatePlayerBalance({ guestId }) {
    await mockLatency();
    const player = findOrCreateGuestPlayer(guestId);
    return { playerId: player.id, balance: player.creditBalance };
  },

  async placeBet({ guestId, betAmount }) {
    await mockLatency();
    if (!Number.isFinite(betAmount) || betAmount < MIN_BET || betAmount > MAX_BET) {
      throw new Error(`Bet must be between ${MIN_BET} and ${MAX_BET} credits`);
    }
    const player = findOrCreateGuestPlayer(guestId);
    if (player.creditBalance < betAmount) {
      throw new Error("Insufficient balance");
    }

    const id = randomUUID();
    const serverSeed = generateServerSeed();
    const round: RoundRecord = {
      id,
      playerId: player.id,
      betAmount,
      serverSeed,
      serverSeedHash: hashServerSeed(serverSeed),
      crashPoint: computeCrashPoint(serverSeed, id),
      startedAt: new Date().toISOString(),
      status: "pending",
    };
    rounds.set(id, round);

    player.creditBalance -= betAmount;
    player.totalWagered += betAmount;
    player.gamesPlayed += 1;
    player.lastActiveAt = round.startedAt;
    recordTransaction(player, "wager", -betAmount);

    const game = seedGames.find((g) => g.name === "Multiplier Climb");
    if (game) {
      game.totalSessions += 1;
      game.totalWagered += betAmount;
    }

    return { round: toPublic(round), balance: player.creditBalance };
  },

  async collect({ guestId, roundId }) {
    await mockLatency();
    const { round, player } = requireOwnedRound(guestId, roundId);
    if (round.status !== "pending") {
      throw new Error("Round already resolved");
    }

    const statusAfterSettle = settleIfCrashed(round);
    if (statusAfterSettle === "crashed") {
      return { round: toPublic(round), balance: player.creditBalance };
    }

    const elapsedSeconds = (Date.now() - new Date(round.startedAt).getTime()) / 1000;
    const multiplier = multiplierAtElapsed(elapsedSeconds);
    const payout = Math.floor(round.betAmount * multiplier);

    round.status = "collected";
    round.resolvedMultiplier = multiplier;
    round.payout = payout;
    round.resolvedAt = new Date().toISOString();

    player.creditBalance += payout;
    player.lastActiveAt = new Date().toISOString();
    recordTransaction(player, "payout", payout);

    const game = seedGames.find((g) => g.name === "Multiplier Climb");
    if (game) game.totalPayout += payout;

    return { round: toPublic(round), balance: player.creditBalance };
  },

  async getState({ guestId, roundId }) {
    await mockLatency();
    const round = rounds.get(roundId);
    const player = seedPlayers.find((p) => p.guestId === guestId);
    if (!round || !player || round.playerId !== player.id) return null;
    settleIfCrashed(round);
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
};
