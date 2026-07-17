import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrashRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const guestId = searchParams.get("guestId");
  if (!guestId) return corsError(new Error("guestId is required"));

  try {
    const accessToken = extractBearerToken(request);
    const { playerId, balance } = await getCrashRepository().getOrCreatePlayerBalance({ guestId, accessToken });
    return corsJson({ balance, playerId });
  } catch (error) {
    return corsError(error, 500);
  }
}
