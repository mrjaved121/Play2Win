import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getGamesRepository } from "@/lib/repositories";
import type { GameCategory, GameEntryPoint, GameStatus, NewGameInput } from "@/lib/types";

const VALID_CATEGORIES: GameCategory[] = ["slots", "table", "arcade", "puzzle"];
const VALID_STATUSES: GameStatus[] = ["active", "disabled", "maintenance"];
const VALID_ENTRY_POINTS: GameEntryPoint[] = ["slots", "crash", "wheel", "scratch"];

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const games = await getGamesRepository().list();
  return NextResponse.json({ games });
}

export async function POST(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await request.json().catch(() => null);
  const name = typeof body?.name === "string" ? body.name.trim() : "";
  const category = body?.category as GameCategory;
  const status = (body?.status as GameStatus) ?? "active";
  const rtp = Number(body?.rtp);
  const releaseDate = typeof body?.releaseDate === "string" ? body.releaseDate : "";
  const appEntryPoint = VALID_ENTRY_POINTS.includes(body?.appEntryPoint as GameEntryPoint)
    ? (body.appEntryPoint as GameEntryPoint)
    : undefined;

  if (!name || !VALID_CATEGORIES.includes(category) || !VALID_STATUSES.includes(status)) {
    return NextResponse.json({ error: "name, category, and status are required." }, { status: 400 });
  }
  if (!Number.isFinite(rtp) || rtp <= 0 || rtp > 100) {
    return NextResponse.json({ error: "rtp must be a number between 0 and 100." }, { status: 400 });
  }
  if (!releaseDate) {
    return NextResponse.json({ error: "releaseDate is required." }, { status: 400 });
  }

  const input: NewGameInput = { name, category, status, rtp, releaseDate, appEntryPoint };
  const game = await getGamesRepository().create(input);
  return NextResponse.json({ game }, { status: 201 });
}
