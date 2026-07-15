import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getPlayersRepository } from "@/lib/repositories";
import type { PlayerStatus } from "@/lib/types";

const VALID_STATUSES: PlayerStatus[] = ["active", "suspended", "banned"];

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const player = await getPlayersRepository().getById(id);
  if (!player) return NextResponse.json({ error: "Player not found" }, { status: 404 });
  return NextResponse.json({ player });
}

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const body = await request.json().catch(() => null);
  const status = body?.status as PlayerStatus | undefined;

  if (!status || !VALID_STATUSES.includes(status)) {
    return NextResponse.json({ error: "Invalid status" }, { status: 400 });
  }

  const player = await getPlayersRepository().updateStatus(id, status);
  return NextResponse.json({ player });
}
