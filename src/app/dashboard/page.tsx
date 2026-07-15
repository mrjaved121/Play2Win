"use client";

import { useMemo } from "react";
import { useApi } from "@/lib/hooks/useApi";
import { Card, CardHeader, CardTitle, CardBody } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { StatTile } from "@/components/dashboard/StatTile";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";
import { RevenueTrendChart } from "@/components/charts/RevenueTrendChart";
import { PlayerGrowthChart } from "@/components/charts/PlayerGrowthChart";
import { formatCompactNumber, formatCredits } from "@/lib/utils";
import type { ActivityEvent, KpiSummary, TimeseriesPoint } from "@/lib/types";

export default function OverviewPage() {
  const { data: overview, isLoading: overviewLoading } = useApi<{
    kpi: KpiSummary;
    activity: ActivityEvent[];
  }>("/api/analytics/overview");
  const { data: revenue, isLoading: revenueLoading } = useApi<{ points: TimeseriesPoint[] }>(
    "/api/analytics/revenue?days=30",
  );
  const { data: growth, isLoading: growthLoading } = useApi<{ points: TimeseriesPoint[] }>(
    "/api/analytics/growth?days=30",
  );

  const revenueTrend14 = useMemo(
    () => revenue?.points.slice(-14).map((p) => p.value) ?? [],
    [revenue],
  );
  const signupsTrend14 = useMemo(() => {
    const points = growth?.points.slice(-15) ?? [];
    const deltas: number[] = [];
    for (let i = 1; i < points.length; i++) deltas.push(points[i].value - points[i - 1].value);
    return deltas;
  }, [growth]);

  const kpi = overview?.kpi;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-ink">Overview</h1>
        <p className="mt-1 text-sm text-ink-secondary">
          Platform health across players, transactions, and the game catalog.
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        {overviewLoading || !kpi ? (
          Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-24" />)
        ) : (
          <>
            <StatTile
              label="Total players"
              value={formatCompactNumber(kpi.totalPlayers)}
              deltaCaption={`+${kpi.newSignups7d} this week`}
            />
            <StatTile
              label="Active players (24h)"
              value={formatCompactNumber(kpi.activePlayers24h)}
              deltaCaption={`of ${formatCompactNumber(kpi.totalPlayers)} total`}
            />
            <StatTile
              label="Revenue (30d)"
              value={formatCredits(kpi.totalRevenue)}
              deltaPct={kpi.revenueDeltaPct}
              trend={revenueTrend14}
            />
            <StatTile
              label="Transactions (24h)"
              value={formatCompactNumber(kpi.transactions24h)}
              deltaPct={kpi.transactionsDeltaPct}
            />
            <StatTile
              label="New signups (7d)"
              value={formatCompactNumber(kpi.newSignups7d)}
              deltaPct={kpi.newSignupsDeltaPct}
              trend={signupsTrend14}
            />
            <StatTile label="Avg. session" value={`${kpi.averageSessionMinutes} min`} />
          </>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Revenue trend (30 days)</CardTitle>
          </CardHeader>
          <CardBody>
            {revenueLoading || !revenue ? (
              <Skeleton className="h-72" />
            ) : (
              <RevenueTrendChart data={revenue.points} />
            )}
          </CardBody>
        </Card>

        <Card className="lg:row-span-2">
          <CardHeader>
            <CardTitle>Recent activity</CardTitle>
          </CardHeader>
          <CardBody className="max-h-[38rem] overflow-y-auto">
            {overviewLoading || !overview ? (
              <div className="flex flex-col gap-3">
                {Array.from({ length: 6 }).map((_, i) => (
                  <Skeleton key={i} className="h-10" />
                ))}
              </div>
            ) : (
              <ActivityFeed events={overview.activity} />
            )}
          </CardBody>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Player growth (30 days)</CardTitle>
          </CardHeader>
          <CardBody>
            {growthLoading || !growth ? (
              <Skeleton className="h-72" />
            ) : (
              <PlayerGrowthChart data={growth.points} />
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
