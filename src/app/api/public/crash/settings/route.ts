import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getCrashSettingsRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Public, read-only Multiplier Climb settings — same response for every
 * caller, no guestId/accessToken. Lets the mobile app's bet stepper/quick-bet
 * presets track whatever min/max bet admin has live right now instead of
 * hardcoded client constants (see blackhole_app's CrashConstants, used only
 * as the pre-fetch fallback). rtp/instantCrashRate are included too — this
 * game already reveals crash points/server seeds for provably-fair
 * verification, so there's nothing to hide about the odds either.
 */
export async function GET() {
  try {
    const settings = await getCrashSettingsRepository().get();
    return corsJson({
      minBet: settings.minBet,
      maxBet: settings.maxBet,
      rtp: settings.rtp,
      instantCrashRate: settings.instantCrashRate,
    });
  } catch (error) {
    return corsError(error, 500);
  }
}
