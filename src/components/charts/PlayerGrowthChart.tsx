"use client";

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { ChartTooltip } from "@/components/charts/ChartTooltip";
import { formatCompactNumber } from "@/lib/utils";
import type { TimeseriesPoint } from "@/lib/types";

function formatDateTick(iso: string) {
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function PlayerGrowthChart({ data }: { data: TimeseriesPoint[] }) {
  return (
    <div className="h-72 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
          <defs>
            <linearGradient id="growth-fill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--color-series-2)" stopOpacity={0.12} />
              <stop offset="100%" stopColor="var(--color-series-2)" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid stroke="var(--color-grid)" vertical={false} />
          <XAxis
            dataKey="date"
            tickFormatter={formatDateTick}
            tick={{ fill: "var(--color-ink-muted)", fontSize: 12 }}
            axisLine={{ stroke: "var(--color-axis)" }}
            tickLine={false}
            minTickGap={32}
          />
          <YAxis
            tickFormatter={(v: number) => formatCompactNumber(v)}
            tick={{ fill: "var(--color-ink-muted)", fontSize: 12 }}
            axisLine={false}
            tickLine={false}
            width={44}
          />
          <Tooltip
            content={<ChartTooltip formatter={(v: number) => `${formatCompactNumber(v)} players`} />}
            cursor={{ stroke: "var(--color-axis)", strokeWidth: 1 }}
          />
          <Area
            type="monotone"
            dataKey="value"
            stroke="var(--color-series-2)"
            strokeWidth={2}
            fill="url(#growth-fill)"
            dot={false}
            activeDot={{ r: 4, stroke: "var(--color-surface)", strokeWidth: 2 }}
            isAnimationActive={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
