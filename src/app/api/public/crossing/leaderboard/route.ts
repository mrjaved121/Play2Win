import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getCrossingRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Platform-wide Multiplier Crossing activity (total bets/wagered/payout,
 * top wins) — unlike the rest of the crossing API, this isn't keyed by
 * guestId/accessToken, it's the same for every caller. Backs the mobile
 * app's "live wins" ticker.
 */
export async function GET() {
  try {
    const leaderboard = await getCrossingRepository().getLeaderboard();
    return corsJson(leaderboard);
  } catch (error) {
    return corsError(error, 500);
  }
}
