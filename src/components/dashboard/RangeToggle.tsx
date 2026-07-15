"use client";

import { cn } from "@/lib/utils";

const OPTIONS = [
  { label: "7D", value: 7 },
  { label: "30D", value: 30 },
  { label: "90D", value: 90 },
];

export function RangeToggle({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  return (
    <div className="inline-flex rounded-lg border border-line p-0.5 text-xs">
      {OPTIONS.map((opt) => (
        <button
          key={opt.value}
          onClick={() => onChange(opt.value)}
          className={cn(
            "rounded-md px-2.5 py-1 font-medium transition-colors cursor-pointer",
            value === opt.value ? "bg-accent-soft text-accent" : "text-ink-secondary",
          )}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
