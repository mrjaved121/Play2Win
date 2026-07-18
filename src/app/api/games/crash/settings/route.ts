import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getCrashSettingsRepository, getGamesRepository } from "@/lib/repositories";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const settings = await getCrashSettingsRepository().get();
  return NextResponse.json({ settings });
}

export async function PUT(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await request.json().catch(() => null);
  const patch: { rtp?: number; instantCrashRate?: number; minBet?: number; maxBet?: number } = {};
  if (typeof body?.rtp === "number") patch.rtp = body.rtp;
  if (typeof body?.instantCrashRate === "number") patch.instantCrashRate = body.instantCrashRate;
  if (typeof body?.minBet === "number") patch.minBet = body.minBet;
  if (typeof body?.maxBet === "number") patch.maxBet = body.maxBet;

  try {
    const settings = await getCrashSettingsRepository().update(patch);

    // Best-effort: keep the Games catalog's displayed RTP for Multiplier
    // Climb in sync so the two admin views never disagree. Not fatal if
    // this fails — the settings themselves (the source of truth for actual
    // gameplay) already saved.
    if (patch.rtp !== undefined) {
      try {
        const games = await getGamesRepository().list();
        const crashGame = games.find((g) => g.appEntryPoint === "crash");
        if (crashGame) await getGamesRepository().update(crashGame.id, { rtp: settings.rtp });
      } catch {
        // Ignored — see comment above.
      }
    }

    return NextResponse.json({ settings });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to update settings.";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
