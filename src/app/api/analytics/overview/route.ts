import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getAnalyticsRepository } from "@/lib/repositories";

export async function GET() {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const analytics = getAnalyticsRepository();
  const [kpi, activity] = await Promise.all([
    analytics.getKpiSummary(),
    analytics.getRecentActivity(12),
  ]);

  return NextResponse.json({ kpi, activity });
}
