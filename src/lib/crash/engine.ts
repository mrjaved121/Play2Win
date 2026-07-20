import { createHash, createHmac, randomBytes } from "crypto";
import {
  DEFAULT_INSTANT_CRASH_RATE,
  DEFAULT_MAX_BET,
  DEFAULT_MIN_BET,
  DEFAULT_RTP,
  INSTANT_CRASH_RATE_OPTIONS,
  MAX_BET_RANGE,
  MIN_BET_RANGE,
  RTP_OPTIONS,
} from "@/lib/crash/settingsOptions";

// Multiplier Climb (crash game) core math. Pure functions only — no I/O,
// no repository access — so both the mock and Supabase repositories share
// exactly one implementation of "what the multiplier is doing" and one
// implementation of "how the crash point is derived", and so this can be
// unit-tested in isolation.

/** multiplier(t) = e^(GROWTH_RATE * t), t in seconds since round start. */
export const GROWTH_RATE = 0.13;

export const STARTING_BALANCE = 100;

// Re-exported from settingsOptions.ts (not declared here) so a "use
// client" component (the admin settings UI) can import the option
// sets/ranges without pulling in this file's `crypto` import — see that
// file's doc comment.
export {
  RTP_OPTIONS,
  DEFAULT_RTP,
  INSTANT_CRASH_RATE_OPTIONS,
  DEFAULT_INSTANT_CRASH_RATE,
  MIN_BET_RANGE,
  MAX_BET_RANGE,
  DEFAULT_MIN_BET,
  DEFAULT_MAX_BET,
};

export function multiplierAtElapsed(elapsedSeconds: number): number {
  return Math.exp(GROWTH_RATE * Math.max(0, elapsedSeconds));
}

/** Inverse of multiplierAtElapsed — how long until the round hits crashPoint. */
export function secondsUntilCrash(crashPoint: number): number {
  return Math.log(crashPoint) / GROWTH_RATE;
}

export function generateServerSeed(): string {
  return randomBytes(32).toString("hex");
}

export function hashServerSeed(serverSeed: string): string {
  return createHash("sha256").update(serverSeed).digest("hex");
}

/**
 * Provably-fair crash point, modeled on the algorithm popularized by
 * Bustabit/Stake-style crash games: HMAC the (secret) server seed with the
 * round id, take the first 52 bits as an integer, and map it onto a
 * heavy-tailed distribution over [1.00, infinity). Deterministic given
 * (serverSeed, roundId, rtp, instantCrashRate), so after a round resolves
 * and the server seed is revealed, anyone — including a thesis committee —
 * can recompute this and confirm the result wasn't picked after the fact.
 * `rtp`/`instantCrashRate` are the settings that were live *when this round
 * started* (stored on the round itself — see CrashRoundPublic — precisely
 * so a later settings change can't retroactively change what a past round's
 * reveal is supposed to reproduce).
 *
 * Construction: `instantCrashRate`% of the hash space is carved off as a
 * forced 1.00x bust. The rest maps via inverse-CDF onto a Pareto tail
 * P(crashPoint >= m) = continuousEdge / m (m >= 1), where `continuousEdge`
 * is solved so that a player cashing out at any fixed multiplier m > 1 has
 * the same expected return either way:
 *
 *   RTP = P(not instant bust) * P(crashPoint >= m | not instant bust) * m
 *       = (1 - instantCrashRate/100) * (continuousEdge / m) * m
 *       = (1 - instantCrashRate/100) * continuousEdge
 *
 * so continuousEdge = rtp/100 / (1 - instantCrashRate/100) makes that
 * equal rtp/100 regardless of which multiplier a player targets — flooring
 * to cents then adds the same small extra edge real crash games have.
 *
 * continuousEdge is a *minimum* multiplier for the continuous pool (its
 * value at u=0), so it must be comfortably above 1.00 — not merely >= 1.00.
 * `floor(raw * 100) / 100` rounds *down* to cents, so even a continuousEdge
 * of exactly 1.00 (or anywhere in [1.00, 1.01)) still floors a thin slice
 * of genuinely-continuous draws down to exactly 1.00 — indistinguishable
 * from an instant bust once rounded, even though `raw` itself never
 * dipped below continuousEdge. Both failure modes — continuousEdge below
 * 1.00 (draws go negative-multiplier-adjacent and get clamped) and
 * continuousEdge in [1.00, 1.01) (draws get floored into the 1.00 cent)
 * — silently inflate the *observed* 1.00x rate past the configured
 * instantCrashRate while still hitting the target RTP exactly (verified
 * by simulation: e.g. rtp=94 with instantCrashRate=3 measured ~7%, not 3%
 * — using only the first fix, `effective = max(instantCrashRate, 100 -
 * rtp)`, still measured ~7% instead of the intended ~6.9%). Since RTP is
 * the actual financial house-edge commitment, `effective` raises
 * instantCrashRate to whatever's needed to keep continuousEdge >= 1.01 —
 * i.e. for (rtp, instantCrashRate) pairs where `rtp + instantCrashRate` is
 * too low, the observed instant-crash rate is `100 - (100/101)*rtp`
 * instead of the configured value, and RTP still lands exactly on target
 * either way. Deterministic from (rtp, instantCrashRate) alone, so a later
 * reveal recomputing this from the same stored settings reproduces it
 * exactly.
 */
export function computeCrashPoint(
  serverSeed: string,
  roundId: string,
  rtp: number = DEFAULT_RTP,
  instantCrashRate: number = DEFAULT_INSTANT_CRASH_RATE,
): number {
  const hmac = createHmac("sha256", serverSeed).update(roundId).digest("hex");
  const h = parseInt(hmac.slice(0, 13), 16);
  const e = Math.pow(2, 52);

  // The smallest instantCrashRate that keeps continuousEdge = rtp / (1 -
  // effective/100) at or above 1.01 — see doc comment above for why 1.00
  // isn't a large enough margin.
  const floorSafeRate = 100 - (100 / 101) * rtp;
  const effective = Math.max(instantCrashRate, floorSafeRate);
  const instantCrashThreshold = (effective / 100) * e;
  if (h < instantCrashThreshold) return 1.0;

  const continuousEdge = rtp / 100 / (1 - effective / 100);
  const u = (h - instantCrashThreshold) / (e - instantCrashThreshold); // uniform on [0, 1)
  const point = Math.floor((continuousEdge / (1 - u)) * 100) / 100;
  return Math.max(1.0, point);
}

/**
 * Validates an incoming settings patch (from the admin settings API)
 * against the allowed option sets/ranges above. Shared by both the mock
 * and Supabase CrashSettingsRepository so neither can drift from the
 * other's rules. Throws a plain `Error` (message safe to surface to the
 * client) on the first invalid field.
 */
export function validateCrashSettingsPatch(patch: {
  rtp?: number;
  instantCrashRate?: number;
  minBet?: number;
  maxBet?: number;
}): void {
  if (patch.rtp !== undefined && !(RTP_OPTIONS as readonly number[]).includes(patch.rtp)) {
    throw new Error(`rtp must be one of ${RTP_OPTIONS.join(", ")}`);
  }
  if (
    patch.instantCrashRate !== undefined &&
    !(INSTANT_CRASH_RATE_OPTIONS as readonly number[]).includes(patch.instantCrashRate)
  ) {
    throw new Error(`instantCrashRate must be one of ${INSTANT_CRASH_RATE_OPTIONS.join(", ")}`);
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
}
