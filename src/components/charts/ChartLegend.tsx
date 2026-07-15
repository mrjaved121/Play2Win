"use client";

interface ChartLegendProps {
  payload?: Array<{ value?: string; color?: string }>;
}

export function ChartLegend({ payload }: ChartLegendProps) {
  if (!payload || payload.length === 0) return null;
  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 pt-2 text-xs">
      {payload.map((entry, i) => (
        <div key={i} className="flex items-center gap-1.5 text-ink-secondary">
          <span
            className="inline-block size-2.5 shrink-0 rounded-full"
            style={{ backgroundColor: entry.color }}
          />
          {entry.value}
        </div>
      ))}
    </div>
  );
}
