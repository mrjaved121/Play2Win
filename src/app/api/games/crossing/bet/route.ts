import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrossingRepository } from "@/lib/repositories";
import type { CrossingDifficulty } from "@/lib/types";

const VALID_DIFFICULTIES: CrossingDifficulty[] = ["easy", "medium", "hard", "hardcore"];

export async function OPTIONS() {
  return corsPreflight();
}

export async function POST(request: Request) {
  let body: { guestId?: unknown; betAmount?: unknown; difficulty?: unknown; clientSeed?: unknown };
  try {
    body = await request.json();
  } catch {
    return corsError(new Error("Invalid JSON body"));
  }

  const guestId = typeof body.guestId === "string" ? body.guestId : undefined;
  const betAmount = typeof body.betAmount === "number" ? body.betAmount : undefined;
  const difficulty = VALID_DIFFICULTIES.includes(body.difficulty as CrossingDifficulty)
    ? (body.difficulty as CrossingDifficulty)
    : undefined;
  const clientSeed = typeof body.clientSeed === "string" ? body.clientSeed : "";
  if (!guestId || betAmount === undefined || !difficulty) {
    return corsError(new Error("guestId, betAmount, and a valid difficulty are required"));
  }

  try {
    const accessToken = extractBearerToken(request);
    const result = await getCrossingRepository().placeBet({ guestId, betAmount, difficulty, clientSeed, accessToken });
    return corsJson(result);
  } catch (error) {
    return corsError(error);
  }
}
