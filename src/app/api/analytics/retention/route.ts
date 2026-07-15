import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getAnalyticsRepository } from "@/lib/repositories";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const cohorts = await getAnalyticsRepository().getRetentionCohorts();
  return NextResponse.json({ cohorts });
}
