import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getNewsRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/** Read-only, unauthenticated feed of active Help & Support entries for the mobile app. */
export async function GET() {
  try {
    const news = await getNewsRepository().list();
    return corsJson({ news: news.filter((item) => item.isActive) });
  } catch (error) {
    return corsError(error, 500);
  }
}
