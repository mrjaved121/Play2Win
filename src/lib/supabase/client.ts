import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let cached: SupabaseClient | null = null;

/**
 * Server-only Supabase client. Prefers the service-role key (bypasses RLS,
 * required for cross-player admin queries) and falls back to the anon key.
 * Never import this from a "use client" component. See README.md for the
 * schema this adapter set expects and the env vars it reads.
 */
export function getSupabaseServerClient(): SupabaseClient {
  if (cached) return cached;

  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_ANON_KEY;

  if (!url || !key) {
    throw new Error(
      "Supabase is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY " +
        "(or SUPABASE_ANON_KEY) in .env.local, or set DATA_SOURCE=mock.",
    );
  }

  cached = createClient(url, key, { auth: { persistSession: false } });
  return cached;
}
