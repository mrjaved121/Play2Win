"use client";

import { ArrowDownRight, ArrowUpRight } from "lucide-react";
import { AreaChart, Area, ResponsiveContainer } from "recharts";
import { cn } from "@/lib/utils";

interface StatTileProps {
  label: string;
  value: string;
  deltaPct?: number;
  deltaCaption?: string;
  trend?: number[];
  goodDirection?: "up" | "down";
}

export function StatTile({
  label,
  value,
  deltaPct,
  deltaCaption = "vs prior period",
  trend,
  goodDirection = "up",
}: StatTileProps) {
  const hasDelta = deltaPct !== undefined && Number.isFinite(deltaPct);
  const isUp = hasDelta && deltaPct! > 0;
  const isGood = hasDelta && (goodDirection === "up" ? isUp : !isUp);
  const deltaClass = !hasDelta
    ? ""
    : Math.abs(deltaPct!) < 0.05
      ? "text-ink-muted"
      : isGood
        ? "text-good"
        : "text-critical";

  return (
    <div className="rounded-xl border border-line bg-surface p-4">
      <p className="text-xs font-medium text-ink-secondary">{label}</p>
      <div className="mt-2 flex items-end justify-between gap-2">
        <p className="text-2xl font-semibold text-ink">{value}</p>
        {trend && trend.length > 1 && (
          <div className="h-8 w-20 shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trend.map((v) => ({ v }))}>
                <defs>
                  <linearGradient id={`spark-${label}`} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="var(--color-accent)" stopOpacity={0.25} />
                    <stop offset="100%" stopColor="var(--color-accent)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <Area
                  type="monotone"
                  dataKey="v"
                  stroke="var(--color-accent)"
                  strokeWidth={2}
                  fill={`url(#spark-${label})`}
                  dot={false}
                  isAnimationActive={false}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
      {hasDelta && (
        <div className={cn("mt-1.5 flex items-center gap-1 text-xs", deltaClass)}>
          {isUp ? <ArrowUpRight className="size-3.5" /> : <ArrowDownRight className="size-3.5" />}
          <span className="font-medium tabular">
            {isUp ? "+" : ""}
            {deltaPct!.toFixed(1)}%
          </span>
          <span className="text-ink-muted">{deltaCaption}</span>
        </div>
      )}
    </div>
  );
}
