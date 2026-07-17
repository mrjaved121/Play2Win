import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import { getCrashRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Links the caller's verified Supabase Auth identity (from the bearer
 * token, not anything client-supplied) to their device's crash-game guest
 * player row, so admin can find/credit a real account. Called once by the
 * mobile app right after a successful sign-in/sign-up — see
 * blackhole_app's login_screen.dart.
 */
export async function POST(request: Request) {
  try {
    const token = extractBearerToken(request);
    if (!token) return corsError(new Error("Missing bearer token"), 401);

    const body = await request.json().catch(() => null);
    const guestId = typeof body?.guestId === "string" ? body.guestId : "";
    if (!guestId) return corsError(new Error("guestId is required"));

    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return corsError(new Error("Invalid session"), 401);

    const { user } = data;
    if (!user.email) return corsError(new Error("Account has no email"));

    const displayName = (user.user_metadata?.full_name as string | undefined) ?? undefined;
    const result = await getCrashRepository().linkAccount({
      guestId,
      userId: user.id,
      email: user.email,
      displayName,
    });
    return corsJson(result);
  } catch (error) {
    return corsError(error, 400);
  }
}
