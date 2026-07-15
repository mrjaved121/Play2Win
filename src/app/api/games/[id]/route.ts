import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getGamesRepository } from "@/lib/repositories";
import type { Game } from "@/lib/types";

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
