import { corsError, corsJson, corsPreflight, extractBearerToken } from "@/lib/http/publicApiCors";
import { getCrossingRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const guestId = searchParams.get("guestId");
  if (!guestId) return corsError(new Error("guestId is required"));

  const page = Number(searchParams.get("page") ?? 1);
  const pageSize = Number(searchParams.get("pageSize") ?? 20);

  try {
    const accessToken = extractBearerToken(request);
    const history = await getCrossingRepository().getHistory({ guestId, accessToken, page, pageSize });
    return corsJson(history);
  } catch (error) {
    return corsError(error, 500);
  }
}
