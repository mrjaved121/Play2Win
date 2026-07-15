"use client";

import type { PlayerStatus } from "@/lib/types";

const OPTIONS: PlayerStatus[] = ["active", "suspended", "banned"];

export function PlayerStatusSelect({
  value,
  onChange,
  disabled,
}: {
  value: PlayerStatus;
  onChange: (status: PlayerStatus) => void;
  disabled?: boolean;
}) {
  return (
    <select
      value={value}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value as PlayerStatus)}
      className="h-8 rounded-md border border-line bg-surface-raised px-2 text-xs text-ink outline-none focus:border-accent disabled:opacity-50"
    >
      {OPTIONS.map((s) => (
        <option key={s} value={s}>
          {s[0].toUpperCase() + s.slice(1)}
        </option>
      ))}
    </select>
  );
}
