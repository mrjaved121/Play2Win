import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrashRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

export async function POST(request: Request) {
  let body: { guestId?: unknown; betAmount?: unknown };
  try {
    body = await request.json();
  } catch {
    return corsError(new Error("Invalid JSON body"));
  }

  const guestId = typeof body.guestId === "string" ? body.guestId : undefined;
  const betAmount = typeof body.betAmount === "number" ? body.betAmount : undefined;
  if (!guestId || betAmount === undefined) {
    return corsError(new Error("guestId and betAmount are required"));
  }

  try {
    const accessToken = extractBearerToken(request);
    const result = await getCrashRepository().placeBet({ guestId, betAmount, accessToken });
    return corsJson(result);
  } catch (error) {
    return corsError(error);
  }
}
