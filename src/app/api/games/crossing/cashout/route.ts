import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrossingRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

export async function POST(request: Request) {
  let body: { guestId?: unknown; roundId?: unknown };
  try {
    body = await request.json();
  } catch {
    return corsError(new Error("Invalid JSON body"));
  }

  const guestId = typeof body.guestId === "string" ? body.guestId : undefined;
  const roundId = typeof body.roundId === "string" ? body.roundId : undefined;
  if (!guestId || !roundId) {
    return corsError(new Error("guestId and roundId are required"));
  }

  try {
    const accessToken = extractBearerToken(request);
    const result = await getCrossingRepository().cashout({ guestId, roundId, accessToken });
    return corsJson(result);
  } catch (error) {
    return corsError(error);
  }
}
