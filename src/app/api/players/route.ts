import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getPlayersRepository } from "@/lib/repositories";
import type { PlayerStatus } from "@/lib/types";

export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const search = searchParams.get("search") ?? undefined;
  const status = (searchParams.get("status") as PlayerStatus | null) ?? undefined;
  const page = Number(searchParams.get("page") ?? 1);
  const pageSize = Number(searchParams.get("pageSize") ?? 20);

  const result = await getPlayersRepository().list({ search, status, page, pageSize });
  return NextResponse.json(result);
}
