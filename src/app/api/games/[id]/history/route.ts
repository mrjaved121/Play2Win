import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrashRepository, getGameRoundRepository } from "@/lib/repositories";
import type { GameRoundType } from "@/lib/types";

const VALID_GAME_TYPES: GameRoundType[] = ["wheel", "scratch"];

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Dual-purpose: a `guestId` query param serves the mobile app's own
 * player-facing history — public, CORS-enabled, resolved via the shared
 * credit_balance economy's player row (same convention as
 * /api/games/crash/history). A `playerId` param instead serves an admin
 * drill-down into any specific player's history and requires an admin
 * session — see stats/route.ts for the same split.
 */
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!VALID_GAME_TYPES.includes(id as GameRoundType)) {
    return corsError(new Error(`Unknown game type "${id}"`), 404);
  }
  const gameType = id as GameRoundType;

  const { searchParams } = new URL(request.url);
  const page = Number(searchParams.get("page") ?? 1);
  const pageSize = Number(searchParams.get("pageSize") ?? 20);

  try {
    const guestId = searchParams.get("guestId");
    if (guestId) {
      const accessToken = extractBearerToken(request);
      const { playerId } = await getCrashRepository().getOrCreatePlayerBalance({ guestId, accessToken });
      const history = await getGameRoundRepository().getHistory(playerId, gameType, { page, pageSize });
      return corsJson(history);
    }

    const auth = await requireAdmin();
    if (auth instanceof NextResponse) return auth;
    const playerId = searchParams.get("playerId");
    if (!playerId) return corsError(new Error("guestId or playerId is required"), 400);

    const history = await getGameRoundRepository().getHistory(playerId, gameType, { page, pageSize });
    return corsJson(history);
  } catch (error) {
    return corsError(error, 500);
  }
}
