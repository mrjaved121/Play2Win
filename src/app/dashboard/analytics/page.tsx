"use client";

import { useState } from "react";
import { useApi } from "@/lib/hooks/useApi";
import { Card, CardHeader, CardTitle, CardBody } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { RangeToggle } from "@/components/dashboard/RangeToggle";
import { RevenueTrendChart } from "@/components/charts/RevenueTrendChart";
import { PlayerGrowthChart } from "@/components/charts/PlayerGrowthChart";
import { GamePopularityChart } from "@/components/charts/GamePopularityChart";
import { RetentionChart } from "@/components/charts/RetentionChart";
import type { GamePopularity, RetentionCohort, TimeseriesPoint } from "@/lib/types";

export default function AnalyticsPage() {
  const [range, setRange] = useState(30);
  const { data: revenue, isLoading: revenueLoading } = useApi<{ points: TimeseriesPoint[] }>(
    `/api/analytics/revenue?days=${range}`,
  );
  const { data: growth, isLoading: growthLoading } = useApi<{ points: TimeseriesPoint[] }>(
    `/api/analytics/growth?days=${range}`,
  );
  const { data: popularity, isLoading: popularityLoading } = useApi<{
    popularity: GamePopularity[];
  }>("/api/analytics/games");
  const { data: retention, isLoading: retentionLoading } = useApi<{
    cohorts: RetentionCohort[];
  }>("/api/analytics/retention");

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-ink">Analytics</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Revenue, growth, and engagement trends across the platform.
          </p>
        </div>
        <RangeToggle value={range} onChange={setRange} />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Revenue trend</CardTitle>
          </CardHeader>
          <CardBody>
            {revenueLoading || !revenue ? (
              <Skeleton className="h-72" />
            ) : (
              <RevenueTrendChart data={revenue.points} />
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Player growth</CardTitle>
          </CardHeader>
          <CardBody>
            {growthLoading || !growth ? (
              <Skeleton className="h-72" />
            ) : (
              <PlayerGrowthChart data={growth.points} />
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top games by sessions</CardTitle>
          </CardHeader>
          <CardBody>
            {popularityLoading || !popularity ? (
              <Skeleton className="h-72" />
            ) : (
              <GamePopularityChart data={popularity.popularity} />
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Retention by cohort</CardTitle>
          </CardHeader>
          <CardBody>
            {retentionLoading || !retention ? (
              <Skeleton className="h-72" />
            ) : (
              <RetentionChart data={retention.cohorts} />
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
