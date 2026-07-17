import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getSlotsRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Records one already-resolved slot spin. The outcome (symbols/win
 * amount/jackpot) is decided entirely client-side — unchanged game logic,
 * see blackhole_app's SpinEngine — so this route only sanity-checks shape
 * and bounds, never rejects a spin the client already showed the player.
 */
export async function POST(request: Request) {
  const body = await request.json().catch(() => null);

  const guestId = typeof body?.guestId === "string" ? body.guestId : "";
  const bet = Number(body?.bet);
  const winAmount = Number(body?.winAmount);
  const isWin = typeof body?.isWin === "boolean" ? body.isWin : winAmount > 0;
  const isJackpot = typeof body?.isJackpot === "boolean" ? body.isJackpot : false;
  const outcome = typeof body?.outcome === "string" ? body.outcome : "";
  const symbols = Array.isArray(body?.symbols) ? body.symbols.filter((s: unknown) => typeof s === "string") : [];
  const clientBalance = Number(body?.clientBalance);

  if (!guestId) return corsError(new Error("guestId is required"));
  if (!Number.isFinite(bet) || bet < 0) return corsError(new Error("bet must be a non-negative number"));
  if (!Number.isFinite(winAmount) || winAmount < 0) {
    return corsError(new Error("winAmount must be a non-negative number"));
  }
  if (!outcome) return corsError(new Error("outcome is required"));
  if (!Number.isFinite(clientBalance) || clientBalance < 0) {
    return corsError(new Error("clientBalance must be a non-negative number"));
  }

  try {
    const accessToken = extractBearerToken(request);
    const result = await getSlotsRepository().recordSpin({
      guestId,
      accessToken,
      bet,
      winAmount,
      isWin,
      isJackpot,
      outcome,
      symbols,
      clientBalance,
    });
    return corsJson(result);
  } catch (error) {
    return corsError(error, 500);
  }
}
