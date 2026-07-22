import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getCrashRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Platform-wide Multiplier Climb activity (total bets/wagered/payout,
 * top wins, top bets) — unlike the rest of the crash API, this isn't
 * keyed by guestId/accessToken, it's the same for every caller.
 */
export async function GET() {
  try {
    const leaderboard = await getCrashRepository().getLeaderboard();
    return corsJson(leaderboard);
  } catch (error) {
    return corsError(error, 500);
  }
}
