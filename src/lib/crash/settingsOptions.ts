/**
 * Admin-adjustable option sets/ranges/defaults for Multiplier Climb's
 * CrashSettings — split out from engine.ts (which pulls in Node's `crypto`
 * for computeCrashPoint and so can't be imported from a "use client"
 * component) so both the server (engine.ts re-exports these) and the admin
 * settings UI (imports this file directly) share exactly one copy. Keeping
 * these in two places is what let them drift out of sync before: the
 * dashboard's RTP dropdown offered options the backend had stopped
 * accepting.
 */

/** Target long-run RTP, as a whole percent — one of these tiers only. */
export const RTP_OPTIONS = [94, 95] as const;
export const DEFAULT_RTP: number = 95;

/** Percent of rounds forced to crash at 1.00x, independent of RTP. */
export const INSTANT_CRASH_RATE_OPTIONS = [3, 4, 5, 6, 7] as const;
export const DEFAULT_INSTANT_CRASH_RATE: number = 5;

export const MIN_BET_RANGE = { min: 10, max: 50 } as const;
export const MAX_BET_RANGE = { min: 100, max: 1000 } as const;
export const DEFAULT_MIN_BET = 20;
export const DEFAULT_MAX_BET = 500;
