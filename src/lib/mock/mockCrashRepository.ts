import { randomUUID } from "crypto";
import {
  computeCrashPoint,
  generateServerSeed,
  GROWTH_RATE,
  hashServerSeed,
  multiplierAtElapsed,
  secondsUntilCrash,
} from "@/lib/crash/engine";
import { mockLatency } from "@/lib/mock/delay";
import { mockCrashSettingsRepository } from "@/lib/mock/mockCrashSettingsRepository";
import { findOrCreateGuestPlayer } from "@/lib/mock/playerResolution";
import { seedGames, seedPlayers, seedTransactions } from "@/lib/mock/seedData";
import type { CrashRepository } from "@/lib/repositories/types";
import type {
  CrashHistoryEntry,
  CrashLeaderboard,
  CrashLeaderboardEntry,
  CrashLiveRoundEntry,
  CrashRoundPublic,
  Player,
  Transaction,
} from "@/lib/types";

interface RoundRecord {
  id: string;
  playerId: string;
  betAmount: number;
  serverSeed: string;
  serverSeedHash: string;
  crashPoint: number;
  rtp: number;
  instantCrashRate: number;
  startedAt: string;
  status: CrashRoundPublic["status"];
  payout?: number;
  resolvedMultiplier?: number;
  resolvedAt?: string;
  voided?: boolean;
}

function toHistoryEntry(round: RoundRecord): CrashHistoryEntry {
  return {
    roundId: round.id,
    bet: round.betAmount,
    multiplier: round.status === "collected" ? (round.resolvedMultiplier ?? 1) : round.crashPoint,
    crashPoint: round.crashPoint,
    winAmount: round.payout ?? 0,
    isWin: round.status === "collected",
    timestamp: round.resolvedAt ?? round.startedAt,
    voided: round.voided,
  };
}

// Module-level singletons: fine for a single dev-server process (same
// "resets on restart" tradeoff the rest of the mock data layer already
// has — see README.md's Known limitations).
const rounds = new Map<string, RoundRecord>();

function findGame() {
  return seedGames.find((g) => g.name === "Multiplier Climb");
}

function recordTransaction(
  player: Player,
  type: "wager" | "payout",
  amount: number,
  note?: string,
): void {
  const txn: Transaction = {
    id: `tx_${randomUUID().slice(0, 8)}`,
    playerId: player.id,
    playerName: player.displayName,
    type,
    status: "completed",
    amount,
    gameId: findGame()?.id,
    gameName: "Multiplier Climb",
    note,
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
    rtp: round.rtp,
    instantCrashRate: round.instantCrashRate,
    voided: round.voided,
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

/**
 * A still-flying round (its hidden crash time hasn't passed yet) this
 * player already has, if any — lets a second bet ride the same flight as
 * an earlier one instead of always starting a fresh crash point. Not
 * gated on `status`: a round the player already collected is still a
 * valid flight to join, since the underlying rocket keeps climbing for
 * anyone else riding it until the crash point actually passes.
 */
function findJoinableRound(playerId: string): RoundRecord | undefined {
  const candidates = Array.from(rounds.values())
    .filter((r) => r.playerId === playerId)
    .sort((a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime())
    .slice(0, 5);
  return candidates.find((r) => {
    const elapsedSeconds = (Date.now() - new Date(r.startedAt).getTime()) / 1000;
    return elapsedSeconds < secondsUntilCrash(r.crashPoint);
  });
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
    const settings = await mockCrashSettingsRepository.get();
    if (!Number.isFinite(betAmount) || betAmount < settings.minBet || betAmount > settings.maxBet) {
      throw new Error(`Bet must be between ${settings.minBet} and ${settings.maxBet} credits`);
    }
    const player = findOrCreateGuestPlayer(guestId);
    if (player.creditBalance < betAmount) {
      throw new Error("Insufficient balance");
    }

    const id = randomUUID();
    // Joining an existing flight means reusing its exact crash parameters
    // — computeCrashPoint must NOT run again here, since it derives the
    // point from (serverSeed, roundId, rtp, instantCrashRate) and a fresh
    // id (or a settings change since the flight started) would give a
    // different point than the flight this bet is meant to share.
    const joinable = findJoinableRound(player.id);
    const serverSeed = joinable ? joinable.serverSeed : generateServerSeed();
    const rtp = joinable ? joinable.rtp : settings.rtp;
    const instantCrashRate = joinable ? joinable.instantCrashRate : settings.instantCrashRate;
    const round: RoundRecord = {
      id,
      playerId: player.id,
      betAmount,
      serverSeed,
      serverSeedHash: joinable ? joinable.serverSeedHash : hashServerSeed(serverSeed),
      crashPoint: joinable ? joinable.crashPoint : computeCrashPoint(serverSeed, id, rtp, instantCrashRate),
      rtp,
      instantCrashRate,
      startedAt: joinable ? joinable.startedAt : new Date().toISOString(),
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

  async getLeaderboard() {
    await mockLatency();
    const game = seedGames.find((g) => g.name === "Multiplier Climb");
    const resolved = Array.from(rounds.values()).filter((r) => r.status !== "pending");

    const toEntry = (round: RoundRecord): CrashLeaderboardEntry => ({
      playerName: seedPlayers.find((p) => p.id === round.playerId)?.displayName ?? "Player",
      bet: round.betAmount,
      multiplier: round.status === "collected" ? (round.resolvedMultiplier ?? 1) : round.crashPoint,
      payout: round.payout ?? 0,
    });

    const topWins = resolved
      .filter((r) => r.status === "collected")
      .sort((a, b) => (b.payout ?? 0) - (a.payout ?? 0))
      .slice(0, 10)
      .map(toEntry);

    const topBets = [...resolved].sort((a, b) => b.betAmount - a.betAmount).slice(0, 10).map(toEntry);

    const result: CrashLeaderboard = {
      totalBets: game?.totalSessions ?? 0,
      totalWagered: game?.totalWagered ?? 0,
      totalPayout: game?.totalPayout ?? 0,
      topWins,
      topBets,
    };
    return result;
  },

  async getLiveRounds() {
    await mockLatency();
    const entries: CrashLiveRoundEntry[] = [];
    let totalWagered = 0;
    for (const round of rounds.values()) {
      if (round.status !== "pending") continue;
      const elapsedSeconds = (Date.now() - new Date(round.startedAt).getTime()) / 1000;
      // Not yet lazily settled, but its hidden crash time has actually
      // passed — leave it out rather than showing a "live" round that's
      // really already over (and don't mutate status from a read-only
      // admin view; ordinary gameplay settles it on the next poll/collect).
      if (elapsedSeconds >= secondsUntilCrash(round.crashPoint)) continue;

      const player = seedPlayers.find((p) => p.id === round.playerId);
      entries.push({
        roundId: round.id,
        playerId: round.playerId,
        playerName: player?.displayName ?? "Player",
        betAmount: round.betAmount,
        startedAt: round.startedAt,
        growthRate: GROWTH_RATE,
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

      round.status = "crashed";
      round.voided = true;
      round.payout = round.betAmount;
      round.resolvedMultiplier = undefined;
      round.resolvedAt = new Date().toISOString();

      player.creditBalance += round.betAmount;
      player.lastActiveAt = round.resolvedAt;
      recordTransaction(player, "payout", round.betAmount, "Emergency stop — round voided, bet refunded");
      // Undoes this round's earlier totalWagered increment so a voided
      // round nets to zero in revenue reporting instead of reading as
      // "wagered but never paid out".
      if (game) game.totalWagered -= round.betAmount;

      voidedCount += 1;
      refundedTotal += round.betAmount;
    }
    return { voidedCount, refundedTotal };
  },
};
