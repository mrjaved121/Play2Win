import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getSlotsRepository } from "@/lib/repositories";

/** Admin-only — see stats/route.ts's doc comment for why this isn't public. */
export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const playerId = searchParams.get("playerId");
  if (!playerId) return NextResponse.json({ error: "playerId is required" }, { status: 400 });

  const page = Number(searchParams.get("page") ?? 1);
  const pageSize = Number(searchParams.get("pageSize") ?? 20);

  const result = await getSlotsRepository().getHistory(playerId, { page, pageSize });
  return NextResponse.json(result);
}
