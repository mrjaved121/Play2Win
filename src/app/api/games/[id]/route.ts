import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getGamesRepository } from "@/lib/repositories";
import type { Game, GameEntryPoint } from "@/lib/types";

const VALID_ENTRY_POINTS: GameEntryPoint[] = ["slots", "crash", "wheel", "scratch", "crossing"];

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const body = await request.json().catch(() => null);
  const patch: Partial<Game> = {};
  if (typeof body?.name === "string") patch.name = body.name;
  if (typeof body?.category === "string") patch.category = body.category;
  if (typeof body?.status === "string") patch.status = body.status;
  if (typeof body?.rtp === "number") patch.rtp = body.rtp;
  if (typeof body?.releaseDate === "string") patch.releaseDate = body.releaseDate;
  // Present-but-invalid (e.g. "" for the form's "None" option) explicitly
  // clears it — see supabaseGamesRepository.update's "in" check for why
  // this can't just be `undefined` and skipped like the fields above.
  if (typeof body?.appEntryPoint === "string") {
    patch.appEntryPoint = VALID_ENTRY_POINTS.includes(body.appEntryPoint as GameEntryPoint)
      ? (body.appEntryPoint as GameEntryPoint)
      : undefined;
  }

  const game = await getGamesRepository().update(id, patch);
  return NextResponse.json({ game });
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  await getGamesRepository().remove(id);
  return NextResponse.json({ ok: true });
}
