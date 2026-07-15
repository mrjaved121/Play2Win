"use client";

interface ChartTooltipProps {
  active?: boolean;
  label?: string;
  formatter?: (value: number) => string;
  payload?: Array<{ value: number; name?: string; color?: string }>;
}

export function ChartTooltip({ active, label, payload, formatter }: ChartTooltipProps) {
  if (!active || !payload || payload.length === 0) return null;

  return (
    <div className="rounded-lg border border-line bg-surface-raised px-3 py-2 shadow-sm">
      {label && <p className="text-xs font-medium text-ink-secondary">{label}</p>}
      <div className="mt-1 flex flex-col gap-0.5">
        {payload.map((entry, i) => (
          <div key={i} className="flex items-center gap-2 text-xs">
            {entry.color && (
              <span
                className="inline-block size-2 rounded-full"
                style={{ backgroundColor: entry.color }}
              />
            )}
            {entry.name && <span className="text-ink-secondary">{entry.name}</span>}
            <span className="tabular font-semibold text-ink">
              {formatter ? formatter(entry.value) : entry.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
