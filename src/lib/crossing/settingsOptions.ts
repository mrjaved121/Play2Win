import type { CrossingDifficulty } from "@/lib/types";

/**
 * Admin-adjustable option sets/ranges/defaults for Multiplier Crossing's
 * CrossingSettings — split out from engine.ts (which pulls in Node's
 * `crypto` for the per-lane HMAC draw and so can't be imported from a
 * "use client" component) for the exact reason crash/settingsOptions.ts is
 * split: both the server (engine.ts re-exports these) and the admin
 * settings UI (imports this file directly) share exactly one copy, so they
 * can't silently drift out of sync.
 */

/** Target long-run RTP, as a whole percent — one of these tiers only. Matches crash's RTP_OPTIONS register. */
export const RTP_OPTIONS = [94, 95] as const;
export const DEFAULT_RTP: number = 95;

/** Board-layout constants — NOT admin-tunable, unlike bust%. Changing lane count changes what the client renders, not just risk (see engine.ts doc comment). */
export const LANE_COUNTS: Record<CrossingDifficulty, number> = {
  easy: 30,
  medium: 25,
  hard: 22,
  hardcore: 18,
};

export const DIFFICULTIES: CrossingDifficulty[] = ["easy", "medium", "hard", "hardcore"];

/** Per-lane bust probability, as a whole percent, per difficulty tier. */
export const BUST_PCT_RANGE: Record<CrossingDifficulty, { min: number; max: number }> = {
  easy: { min: 3, max: 10 },
  medium: { min: 6, max: 14 },
  hard: { min: 10, max: 20 },
  hardcore: { min: 15, max: 30 },
};

export const DEFAULT_BUST_PCT: Record<CrossingDifficulty, number> = {
  easy: 6,
  medium: 9,
  hard: 13,
  hardcore: 20,
};

export const MIN_BET_RANGE = { min: 10, max: 50 } as const;
export const MAX_BET_RANGE = { min: 100, max: 1000 } as const;
export const DEFAULT_MIN_BET = 20;
export const DEFAULT_MAX_BET = 500;

/** Absolute payout cap applied at resolution — a mechanism crash has no equivalent of (see engine.ts). */
export const MAX_WIN_RANGE = { min: 1000, max: 1000000 } as const;
export const DEFAULT_MAX_WIN = 100000;
