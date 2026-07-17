import { createHash, createHmac, randomBytes } from "crypto";

// Multiplier Climb (crash game) core math. Pure functions only — no I/O,
// no repository access — so both the mock and Supabase repositories share
// exactly one implementation of "what the multiplier is doing" and one
// implementation of "how the crash point is derived", and so this can be
// unit-tested in isolation.

/** multiplier(t) = e^(GROWTH_RATE * t), t in seconds since round start. */
export const GROWTH_RATE = 0.13;

export const MIN_BET = 10;
export const MAX_BET = 500;
export const STARTING_BALANCE = 500;

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
 * heavy-tailed distribution over [1.00, infinity) with a ~1-in-33
 * (~3%) instant-crash floor. Deterministic given (serverSeed, roundId), so
 * after a round resolves and the server seed is revealed, anyone —
 * including a thesis committee — can recompute this and confirm the
 * result wasn't picked after the fact.
 */
export function computeCrashPoint(serverSeed: string, roundId: string): number {
  const hmac = createHmac("sha256", serverSeed).update(roundId).digest("hex");
  const h = parseInt(hmac.slice(0, 13), 16);
  const e = Math.pow(2, 52);
  if (h % 33 === 0) return 1.0;
  const point = Math.floor((100 * e - h) / (e - h)) / 100;
  return Math.max(1.0, point);
}
