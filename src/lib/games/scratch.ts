import { weightedPickIndex } from "@/lib/games/weightedPick";

export const MIN_SCRATCH_COST = 10;
export const MAX_SCRATCH_COST = 500;

export interface ScratchTier {
  multiplier: number;
  symbol: string;
  label: string;
}

/**
 * Weights tuned to ~92.4% RTP (same target as the slot machine — see
 * wheel.ts's doc comment). Verified: sum(weight * multiplier) /
 * sum(weight) = 924/1000 = 0.924. Retune here only — the mobile app's
 * scratch_screen.dart mirrors this table for rendering and must be kept
 * in sync.
 */
export const SCRATCH_TIERS: Array<ScratchTier & { weight: number }> = [
  { multiplier: 0, weight: 648, symbol: "💀", label: "No win" },
  { multiplier: 2, weight: 232, symbol: "🍋", label: "2x" },
  { multiplier: 3, weight: 90, symbol: "🍒", label: "3x" },
  { multiplier: 5, weight: 25, symbol: "🔔", label: "5x" },
  { multiplier: 10, weight: 4, symbol: "💎", label: "10x" },
  { multiplier: 25, weight: 1, symbol: "👑", label: "25x jackpot" },
];

export interface ScratchResult {
  tierIndex: number;
  multiplier: number;
  winAmount: number;
  /** 3 panel symbols to reveal — all matching on a win, guaranteed non-matching on a loss. Purely cosmetic; the prize is already decided above. */
  panels: string[];
}

export function playScratch(cost: number): ScratchResult {
  const tierIndex = weightedPickIndex(SCRATCH_TIERS.map((t) => t.weight));
  const tier = SCRATCH_TIERS[tierIndex];
  const winAmount = Math.floor(cost * tier.multiplier);
  const panels = winAmount > 0 ? [tier.symbol, tier.symbol, tier.symbol] : threeDistinctSymbols();
  return { tierIndex, multiplier: tier.multiplier, winAmount, panels };
}

/** 3 distinct symbols from the tier set — guarantees no accidental 3-of-a-kind on a loss. */
function threeDistinctSymbols(): string[] {
  const pool = SCRATCH_TIERS.map((t) => t.symbol);
  const shuffled = [...pool].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, 3);
}
