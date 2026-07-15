"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LabelList } from "recharts";
import { ChartTooltip } from "@/components/charts/ChartTooltip";
import { formatCompactNumber } from "@/lib/utils";
import type { GamePopularity } from "@/lib/types";

export function GamePopularityChart({ data }: { data: GamePopularity[] }) {
  const chartHeight = Math.max(220, data.length * 40);

  return (
    <div style={{ height: chartHeight }} className="w-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={data}
          layout="vertical"
          margin={{ top: 4, right: 36, left: 0, bottom: 4 }}
          barCategoryGap="24%"
        >
          <CartesianGrid stroke="var(--color-grid)" horizontal={false} />
          <XAxis
            type="number"
            tickFormatter={(v: number) => formatCompactNumber(v)}
            tick={{ fill: "var(--color-ink-muted)", fontSize: 12 }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            type="category"
            dataKey="gameName"
            tick={{ fill: "var(--color-ink-secondary)", fontSize: 12 }}
            axisLine={false}
            tickLine={false}
            width={132}
          />
          <Tooltip
            content={<ChartTooltip formatter={(v: number) => `${formatCompactNumber(v)} sessions`} />}
            cursor={{ fill: "var(--color-page)" }}
          />
          <Bar dataKey="sessions" fill="var(--color-accent)" radius={[0, 4, 4, 0]} maxBarSize={20}>
            <LabelList
              dataKey="sessions"
              position="right"
              formatter={(v) => formatCompactNumber(Number(v ?? 0))}
              fill="var(--color-ink-secondary)"
              fontSize={12}
            />
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
