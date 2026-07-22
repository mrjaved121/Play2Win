import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrossingRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const guestId = searchParams.get("guestId");
  const roundId = searchParams.get("roundId");
  if (!guestId || !roundId) {
    return corsError(new Error("guestId and roundId are required"));
  }

  try {
    const accessToken = extractBearerToken(request);
    const round = await getCrossingRepository().getState({ guestId, roundId, accessToken });
    if (!round) return corsError(new Error("Round not found"), 404);
    return corsJson({ round });
  } catch (error) {
    return corsError(error, 500);
  }
}
