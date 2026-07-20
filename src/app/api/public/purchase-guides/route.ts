import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getPurchaseGuideRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/** Read-only, unauthenticated feed of active "How to Buy" entries for the mobile app. */
export async function GET() {
  try {
    const guides = await getPurchaseGuideRepository().list();
    return corsJson({ guides: guides.filter((guide) => guide.isActive) });
  } catch (error) {
    return corsError(error, 500);
  }
}
