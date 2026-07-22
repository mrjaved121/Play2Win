import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getCrossingSettingsRepository, getGamesRepository } from "@/lib/repositories";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const settings = await getCrossingSettingsRepository().get();
  return NextResponse.json({ settings });
}

export async function PUT(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await request.json().catch(() => null);
  const patch: {
    rtp?: number;
    minBet?: number;
    maxBet?: number;
    maxWin?: number;
    easyBustPct?: number;
    mediumBustPct?: number;
    hardBustPct?: number;
    hardcoreBustPct?: number;
  } = {};
  if (typeof body?.rtp === "number") patch.rtp = body.rtp;
  if (typeof body?.minBet === "number") patch.minBet = body.minBet;
  if (typeof body?.maxBet === "number") patch.maxBet = body.maxBet;
  if (typeof body?.maxWin === "number") patch.maxWin = body.maxWin;
  if (typeof body?.easyBustPct === "number") patch.easyBustPct = body.easyBustPct;
  if (typeof body?.mediumBustPct === "number") patch.mediumBustPct = body.mediumBustPct;
  if (typeof body?.hardBustPct === "number") patch.hardBustPct = body.hardBustPct;
  if (typeof body?.hardcoreBustPct === "number") patch.hardcoreBustPct = body.hardcoreBustPct;

  try {
    const settings = await getCrossingSettingsRepository().update(patch);

    // Best-effort: keep the Games catalog's displayed RTP for Multiplier
    // Crossing in sync — same non-fatal pattern as the crash settings route.
    if (patch.rtp !== undefined) {
      try {
        const games = await getGamesRepository().list();
        const crossingGame = games.find((g) => g.appEntryPoint === "crossing");
        if (crossingGame) await getGamesRepository().update(crossingGame.id, { rtp: settings.rtp });
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
