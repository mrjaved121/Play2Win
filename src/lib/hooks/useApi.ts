"use client";

import { useEffect, useState } from "react";

interface UseApiResult<T> {
  data: T | null;
  error: string | null;
  isLoading: boolean;
}

/** Minimal GET-fetch hook shared by the dashboard pages. Pass null to skip fetching. */
export function useApi<T>(url: string | null): UseApiResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isFetching, setIsFetching] = useState(() => Boolean(url));

  useEffect(() => {
    if (!url) return;
    let cancelled = false;
    // Standard fetch-on-mount pattern: the effect synchronizes with the
    // network, and flagging the request as in-flight is part of that sync.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setIsFetching(true);
    setError(null);

    fetch(url)
      .then(async (res) => {
        const body = await res.json().catch(() => null);
        if (cancelled) return;
        if (!res.ok) {
          setError(body?.error ?? `Request failed (${res.status})`);
          setData(null);
        } else {
          setData(body);
        }
      })
      .catch((e: unknown) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Network error");
      })
      .finally(() => {
        if (!cancelled) setIsFetching(false);
      });

    return () => {
      cancelled = true;
    };
  }, [url]);

  return { data, error, isLoading: url !== null && isFetching };
}
