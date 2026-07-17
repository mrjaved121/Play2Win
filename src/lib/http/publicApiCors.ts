import { NextResponse } from "next/server";

/**
 * The `/api/games/**` routes are called directly by the mobile app (and
 * potentially a Flutter Web build) rather than from this dashboard's own
 * origin, so — unlike the admin `/api/**` routes — they need CORS headers
 * and no session cookie is expected. There's no per-player auth beyond the
 * guestId the caller supplies (see CrashRepository doc comment): fine for
 * a research prototype's simulated-currency game, not something to lift
 * into a real-money product as-is.
 */
const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export function corsJson(body: unknown, init?: ResponseInit): NextResponse {
  return NextResponse.json(body, {
    ...init,
    headers: { ...CORS_HEADERS, ...(init?.headers as Record<string, string> | undefined) },
  });
}

export function corsPreflight(): NextResponse {
  return new NextResponse(null, { status: 204, headers: CORS_HEADERS });
}

/** Maps a thrown `Error`'s message to a 400 (client/business error) response. */
export function corsError(error: unknown, status = 400): NextResponse {
  const message = error instanceof Error ? error.message : "Unexpected error";
  return corsJson({ error: message }, { status });
}

/**
 * Pulls a Supabase access token out of `Authorization: Bearer <token>`, if
 * present. Undefined (not a rejection) when absent — these routes accept
 * anonymous guest callers too; see CrashRepository's `resolvePlayer`.
 */
export function extractBearerToken(request: Request): string | undefined {
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match?.[1]?.trim() || undefined;
}
