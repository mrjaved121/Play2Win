import { createHash, createHmac, randomBytes } from "crypto";
import type { CrossingDifficulty } from "@/lib/types";
import {
  BUST_PCT_RANGE,
  DEFAULT_BUST_PCT,
  DEFAULT_MAX_BET,
  DEFAULT_MAX_WIN,
  DEFAULT_MIN_BET,
  DEFAULT_RTP,
  LANE_COUNTS,
  MAX_BET_RANGE,
  MAX_WIN_RANGE,
  MIN_BET_RANGE,
  RTP_OPTIONS,
} from "@/lib/crossing/settingsOptions";

// Multiplier Crossing core math. Pure functions only — no I/O, no
// repository access — so both the mock and Supabase repositories share
// exactly one implementation of "what the ladder looks like" and "whether
// a given lane busts", and so this can be unit-tested in isolation. Mirrors
// src/lib/crash/engine.ts's split and conventions.

export {
  RTP_OPTIONS,
  DEFAULT_RTP,
  LANE_COUNTS,
  BUST_PCT_RANGE,
  DEFAULT_BUST_PCT,
  MIN_BET_RANGE,
  MAX_BET_RANGE,
  DEFAULT_MIN_BET,
  DEFAULT_MAX_BET,
  MAX_WIN_RANGE,
  DEFAULT_MAX_WIN,
};

export function generateServerSeed(): string {
  return randomBytes(32).toString("hex");
}

export function hashServerSeed(serverSeed: string): string {
  return createHash("sha256").update(serverSeed).digest("hex");
}

export function survivalProbability(bustPct: number): number {
  return 1 - bustPct / 100;
}

/**
 * The smallest bust% that keeps multiplier(1) at or above 1.01 for a given
 * rtp — same margin, same reasoning, as crash engine.ts's floorSafeRate
 * guards `continuousEdge >= 1.01`: at exactly 1.00, a "successful" lane
 * pays back less than the stake, which is nonsensical, and floating-point
 * rounding right at the boundary can silently tip it below 1.00 in
 * practice. validateCrossingSettingsPatch rejects any bustPct below this
 * for the *current* rtp.
 */
export function minSafeBustPct(rtp: number): number {
  return 100 * (1 - rtp / 100 / 1.01);
}

/**
 * multiplier(n) = rtp * (1/p)^n, where p is the constant per-lane survival
 * probability for the chosen difficulty. This is the discrete analogue of
 * crash's continuous-time payout curve: EV(cash out at lane n) = bet *
 * multiplier(n) * p^n = bet * rtp for every n, so the house edge is hit
 * exactly regardless of which lane a player targets — it can't be gamed by
 * choosing a particular cash-out strategy, same load-bearing property
 * crash's continuousEdge derivation documents.
 */
export function laneMultiplier(n: number, rtp: number, survivalP: number): number {
  return Math.floor((rtp / 100) * Math.pow(1 / survivalP, n) * 100) / 100;
}

/** The full public payout ladder for one difficulty — index 0 = lane 1. Pure function of (rtp, bustPct, laneCount); no secret involved, safe to show before betting. */
export function buildLadder(laneCount: number, rtp: number, bustPct: number): number[] {
  const survivalP = survivalProbability(bustPct);
  return Array.from({ length: laneCount }, (_, i) => laneMultiplier(i + 1, rtp, survivalP));
}

/**
 * Per-lane provably-fair draw, folding in a client seed (crash's
 * computeCrashPoint only ever hashes serverSeed+roundId — this closes that
 * gap): HMAC the (secret) server seed with "clientSeed:roundId:laneIndex",
 * take the first 52 bits as an integer, map onto a uniform [0, 1) draw —
 * exactly crash's HMAC-slicing trick, applied per-lane instead of
 * once-per-round. Deterministic given (serverSeed, clientSeed, roundId,
 * laneIndex), so once serverSeed is revealed at resolution, anyone can
 * replay every lane 1..currentLane and confirm the exact survive/bust
 * sequence the round actually played out.
 */
function laneUnitInterval(serverSeed: string, clientSeed: string, roundId: string, laneIndex: number): number {
  const message = `${clientSeed}:${roundId}:${laneIndex}`;
  const hmac = createHmac("sha256", serverSeed).update(message).digest("hex");
  const h = parseInt(hmac.slice(0, 13), 16);
  return h / Math.pow(2, 52);
}

/** True = this lane busts. */
export function isLaneBust(
  serverSeed: string,
  clientSeed: string,
  roundId: string,
  laneIndex: number,
  bustPct: number,
): boolean {
  return laneUnitInterval(serverSeed, clientSeed, roundId, laneIndex) < bustPct / 100;
}

/**
 * Validates an incoming settings patch (from the admin settings API)
 * against the allowed option sets/ranges above. Shared by both the mock
 * and Supabase CrossingSettingsRepository so neither can drift from the
 * other's rules. Throws a plain `Error` (message safe to surface to the
 * client) on the first invalid field. `rtp`, if present in the same patch,
 * is validated first and used to compute the bust% floor for whichever
 * rtp will be in effect after this patch applies.
 */
export function validateCrossingSettingsPatch(patch: {
  rtp?: number;
  minBet?: number;
  maxBet?: number;
  maxWin?: number;
  easyBustPct?: number;
  mediumBustPct?: number;
  hardBustPct?: number;
  hardcoreBustPct?: number;
}, currentRtp: number): void {
  if (patch.rtp !== undefined && !(RTP_OPTIONS as readonly number[]).includes(patch.rtp)) {
    throw new Error(`rtp must be one of ${RTP_OPTIONS.join(", ")}`);
  }
  const effectiveRtp = patch.rtp ?? currentRtp;
  const floor = minSafeBustPct(effectiveRtp);

  const tierChecks: Array<[CrossingDifficulty, number | undefined]> = [
    ["easy", patch.easyBustPct],
    ["medium", patch.mediumBustPct],
    ["hard", patch.hardBustPct],
    ["hardcore", patch.hardcoreBustPct],
  ];
  for (const [tier, value] of tierChecks) {
    if (value === undefined) continue;
    const range = BUST_PCT_RANGE[tier];
    if (!Number.isFinite(value) || value < range.min || value > range.max) {
      throw new Error(`${tier}BustPct must be a number between ${range.min} and ${range.max}`);
    }
    if (value < floor) {
      throw new Error(`${tier}BustPct must be at least ${floor.toFixed(2)} to keep lane-1 payouts above 1.00x at rtp=${effectiveRtp}`);
    }
  }
  if (
    patch.minBet !== undefined &&
    (!Number.isInteger(patch.minBet) || patch.minBet < MIN_BET_RANGE.min || patch.minBet > MIN_BET_RANGE.max)
  ) {
    throw new Error(`minBet must be a whole number between ${MIN_BET_RANGE.min} and ${MIN_BET_RANGE.max}`);
  }
  if (
    patch.maxBet !== undefined &&
    (!Number.isInteger(patch.maxBet) || patch.maxBet < MAX_BET_RANGE.min || patch.maxBet > MAX_BET_RANGE.max)
  ) {
    throw new Error(`maxBet must be a whole number between ${MAX_BET_RANGE.min} and ${MAX_BET_RANGE.max}`);
  }
  if (
    patch.maxWin !== undefined &&
    (!Number.isInteger(patch.maxWin) || patch.maxWin < MAX_WIN_RANGE.min || patch.maxWin > MAX_WIN_RANGE.max)
  ) {
    throw new Error(`maxWin must be a whole number between ${MAX_WIN_RANGE.min} and ${MAX_WIN_RANGE.max}`);
  }
}
