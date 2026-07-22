import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getCrossingRepository } from "@/lib/repositories";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const live = await getCrossingRepository().getLiveRounds();
  return NextResponse.json(live);
}
