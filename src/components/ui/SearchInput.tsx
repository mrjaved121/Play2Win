"use client";

import { useEffect, useState } from "react";
import { Search } from "lucide-react";

export function SearchInput({
  placeholder,
  onDebouncedChange,
  debounceMs = 300,
}: {
  placeholder?: string;
  onDebouncedChange: (value: string) => void;
  debounceMs?: number;
}) {
  const [value, setValue] = useState("");

  useEffect(() => {
    const handle = setTimeout(() => onDebouncedChange(value), debounceMs);
    return () => clearTimeout(handle);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value, debounceMs]);

  return (
    <div className="relative">
      <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-ink-muted" />
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder ?? "Search..."}
        className="h-9 w-full rounded-lg border border-line bg-surface-raised pl-9 pr-3 text-sm text-ink placeholder:text-ink-muted outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft sm:w-64"
      />
    </div>
  );
}
