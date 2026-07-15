/**
 * Resolves a "from" ISO timestamp for transaction filters. Accepts either an
 * explicit `from` param or a `rangeDays` preset (last N days from now) —
 * computed server-side so the request handler owns the impure Date.now()
 * call instead of a React render path.
 */
export function resolveFromParam(searchParams: URLSearchParams): string | undefined {
  const rangeDays = Number(searchParams.get("rangeDays") ?? 0);
  if (rangeDays > 0) {
    return new Date(Date.now() - rangeDays * 24 * 60 * 60 * 1000).toISOString();
  }
  return searchParams.get("from") ?? undefined;
}
