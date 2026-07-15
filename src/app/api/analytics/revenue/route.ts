import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getAnalyticsRepository } from "@/lib/repositories";

export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const days = Number(searchParams.get("days") ?? 30);

  const points = await getAnalyticsRepository().getRevenueTrend(days);
  return NextResponse.json({ points });
}
