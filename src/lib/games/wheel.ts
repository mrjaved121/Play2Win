import { weightedPickIndex } from "@/lib/games/weightedPick";

export const MIN_WHEEL_BET = 10;
export const MAX_WHEEL_BET = 500;

export interface WheelSegment {
  multiplier: number;
  label: string;
}

/**
 * 8 segments, weights tuned to land close to the slot machine's 92%
 * target RTP (same approach as blackhole_app's SpinEngine — see its doc
 * comment on GameConstants.targetRtp). Verified: sum(weight * multiplier)
 * / sum(weight) = 184/200 = 0.92 exactly. Retune here only — the mobile
 * app's wheel_screen.dart mirrors this table for rendering and must be
 * kept in sync, same convention already used for crash's MIN_BET/MAX_BET.
 */
export const WHEEL_SEGMENTS: Array<WheelSegment & { weight: number }> = [
  { multiplier: 0, weight: 56, label: "Bust" },
  { multiplier: 0.5, weight: 48, label: "0.5x" },
  { multiplier: 1, weight: 44, label: "1x" },
  { multiplier: 1.5, weight: 26, label: "1.5x" },
  { multiplier: 2, weight: 14, label: "2x" },
  { multiplier: 3, weight: 8, label: "3x" },
  { multiplier: 5, weight: 3, label: "5x" },
  { multiplier: 10, weight: 1, label: "10x" },
];

export interface WheelResult {
  segmentIndex: number;
  multiplier: number;
  winAmount: number;
}

export function spinWheel(bet: number): WheelResult {
  const segmentIndex = weightedPickIndex(WHEEL_SEGMENTS.map((s) => s.weight));
  const multiplier = WHEEL_SEGMENTS[segmentIndex].multiplier;
  return { segmentIndex, multiplier, winAmount: Math.floor(bet * multiplier) };
}
