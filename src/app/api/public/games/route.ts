import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getGamesRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Read-only, unauthenticated catalog feed for the mobile app's Lobby.
 * Excludes `disabled` games entirely; `maintenance` games are still
 * included (shown locked, same as a "coming soon" entry) so a temporary
 * outage doesn't just make the tile vanish. Only a lean shape is exposed —
 * no wagering/session stats.
 */
export async function GET() {
  try {
    const games = await getGamesRepository().list();
    const catalog = games
      .filter((game) => game.status !== "disabled")
      .map((game) => ({
        id: game.id,
        name: game.name,
        category: game.category,
        status: game.status,
        appEntryPoint: game.appEntryPoint ?? null,
      }));
    return corsJson({ games: catalog });
  } catch (error) {
    return corsError(error, 500);
  }
}
