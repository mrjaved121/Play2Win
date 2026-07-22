import { buildLadder, LANE_COUNTS } from "@/lib/crossing/engine";
import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getCrossingSettingsRepository } from "@/lib/repositories";
import type { CrossingDifficulty } from "@/lib/types";

export async function OPTIONS() {
  return corsPreflight();
}

const DIFFICULTIES: CrossingDifficulty[] = ["easy", "medium", "hard", "hardcore"];

/**
 * Public, read-only Multiplier Crossing settings — same response for every
 * caller, no guestId/accessToken. Includes the full per-difficulty payout
 * ladder (a pure function of rtp/bustPct/laneCount, no secret involved —
 * see engine.ts's buildLadder) so the mobile app's difficulty picker can
 * show real multiplier badges before the player bets, and so the bet
 * stepper can track live min/max/maxWin instead of hardcoded constants.
 */
export async function GET() {
  try {
    const settings = await getCrossingSettingsRepository().get();
    const bustPctByDifficulty: Record<CrossingDifficulty, number> = {
      easy: settings.easyBustPct,
      medium: settings.mediumBustPct,
      hard: settings.hardBustPct,
      hardcore: settings.hardcoreBustPct,
    };
    const difficulties = Object.fromEntries(
      DIFFICULTIES.map((difficulty) => [
        difficulty,
        {
          laneCount: LANE_COUNTS[difficulty],
          bustPct: bustPctByDifficulty[difficulty],
          ladder: buildLadder(LANE_COUNTS[difficulty], settings.rtp, bustPctByDifficulty[difficulty]),
        },
      ]),
    );
    return corsJson({
      minBet: settings.minBet,
      maxBet: settings.maxBet,
      maxWin: settings.maxWin,
      rtp: settings.rtp,
      difficulties,
    });
  } catch (error) {
    return corsError(error, 500);
  }
}
