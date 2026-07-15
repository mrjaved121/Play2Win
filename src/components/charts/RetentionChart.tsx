"use client";

import { useState } from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { BarChart3, Table as TableIcon } from "lucide-react";
import { ChartTooltip } from "@/components/charts/ChartTooltip";
import { ChartLegend } from "@/components/charts/ChartLegend";
import { cn } from "@/lib/utils";
import type { RetentionCohort } from "@/lib/types";

export function RetentionChart({ data }: { data: RetentionCohort[] }) {
  const [view, setView] = useState<"chart" | "table">("chart");

  return (
    <div>
      <div className="flex justify-end">
        <div className="inline-flex rounded-lg border border-line p-0.5 text-xs">
          <button
            onClick={() => setView("chart")}
            className={cn(
              "flex items-center gap-1 rounded-md px-2 py-1 transition-colors cursor-pointer",
              view === "chart" ? "bg-accent-soft text-accent" : "text-ink-secondary",
            )}
          >
            <BarChart3 className="size-3.5" /> Chart
          </button>
          <button
            onClick={() => setView("table")}
            className={cn(
              "flex items-center gap-1 rounded-md px-2 py-1 transition-colors cursor-pointer",
              view === "table" ? "bg-accent-soft text-accent" : "text-ink-secondary",
            )}
          >
            <TableIcon className="size-3.5" /> Table
          </button>
        </div>
      </div>

      {view === "chart" ? (
        <div className="h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }} barGap={4} barCategoryGap="20%">
              <CartesianGrid stroke="var(--color-grid)" vertical={false} />
              <XAxis
                dataKey="cohort"
                tick={{ fill: "var(--color-ink-muted)", fontSize: 12 }}
                axisLine={{ stroke: "var(--color-axis)" }}
                tickLine={false}
              />
              <YAxis
                tickFormatter={(v: number) => `${v}%`}
                tick={{ fill: "var(--color-ink-muted)", fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                width={40}
                domain={[0, 100]}
              />
              <Tooltip
                content={<ChartTooltip formatter={(v: number) => `${v}%`} />}
                cursor={{ fill: "var(--color-page)" }}
              />
              <Legend content={<ChartLegend />} />
              <Bar dataKey="day1" name="Day 1" fill="var(--color-series-1)" radius={[4, 4, 0, 0]} maxBarSize={18} />
              <Bar dataKey="day7" name="Day 7" fill="var(--color-series-2)" radius={[4, 4, 0, 0]} maxBarSize={18} />
              <Bar dataKey="day30" name="Day 30" fill="var(--color-series-3)" radius={[4, 4, 0, 0]} maxBarSize={18} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line text-left text-xs text-ink-muted">
                <th className="py-2 font-medium">Cohort</th>
                <th className="py-2 font-medium">Day 1</th>
                <th className="py-2 font-medium">Day 7</th>
                <th className="py-2 font-medium">Day 30</th>
              </tr>
            </thead>
            <tbody>
              {data.map((c) => (
                <tr key={c.cohort} className="border-b border-line last:border-0">
                  <td className="py-2 text-ink">{c.cohort}</td>
                  <td className="py-2 tabular text-ink-secondary">{c.day1}%</td>
                  <td className="py-2 tabular text-ink-secondary">{c.day7}%</td>
                  <td className="py-2 tabular text-ink-secondary">{c.day30}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
