import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getGameRoundRepository } from "@/lib/repositories";
import type { GameRoundType } from "@/lib/types";

const VALID_GAME_TYPES: GameRoundType[] = ["wheel", "scratch"];

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Public, unauthenticated-by-default play endpoint shared by Lucky Wheel
 * and Scratch Card. Lives at `/api/games/[id]/play` (reusing the Games
 * catalog's existing `[id]` segment name — Next.js requires one dynamic
 * segment name per path position, and `/api/games/[id]/route.ts` already
 * claims it) but `id` here is a *game type* ("wheel"/"scratch"), not a
 * catalog row id. The RNG itself lives in src/lib/games/wheel.ts and
 * scratch.ts; this route is just validation + the repository call.
 */
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!VALID_GAME_TYPES.includes(id as GameRoundType)) {
    return corsError(new Error(`Unknown game type "${id}"`), 404);
  }
  const gameType = id as GameRoundType;

  const body = await request.json().catch(() => null);
  const guestId = typeof body?.guestId === "string" ? body.guestId : "";
  const bet = Number(body?.bet);
  if (!guestId) return corsError(new Error("guestId is required"));
  if (!Number.isFinite(bet) || bet <= 0) return corsError(new Error("bet must be a positive number"));

  try {
    const accessToken = extractBearerToken(request);
    const outcome = await getGameRoundRepository().play({ gameType, guestId, accessToken, bet });
    return corsJson(outcome);
  } catch (error) {
    return corsError(error);
  }
}
