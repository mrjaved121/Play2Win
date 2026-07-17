import { corsError, corsJson, corsPreflight } from "@/lib/http/publicApiCors";
import { getAppContentRepository } from "@/lib/repositories";

export async function OPTIONS() {
  return corsPreflight();
}

/**
 * Read-only, unauthenticated feed for the mobile app. Returns
 * `{ content: null }` (not a 404) when the key doesn't exist yet or is
 * inactive, so the app can render its own "not available" copy uniformly
 * rather than branching on error vs. empty.
 */
export async function GET(_request: Request, { params }: { params: Promise<{ key: string }> }) {
  try {
    const { key } = await params;
    const content = await getAppContentRepository().getByKey(key);
    return corsJson({ content: content?.isActive ? content : null });
  } catch (error) {
    return corsError(error, 500);
  }
}
