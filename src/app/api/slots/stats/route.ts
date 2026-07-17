import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getSlotsRepository } from "@/lib/repositories";

/**
 * Admin-only (not under src/app/api/public/**) — an unauthenticated
 * version keyed by playerId would let anyone enumerate any player's
 * gambling history by guessing/iterating ids.
 */
export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const playerId = searchParams.get("playerId");
  if (!playerId) return NextResponse.json({ error: "playerId is required" }, { status: 400 });

  const stats = await getSlotsRepository().getStats(playerId);
  return NextResponse.json({ stats });
}
