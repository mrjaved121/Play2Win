import { mockLatency } from "@/lib/mock/delay";
import type { AppContentRepository } from "@/lib/repositories/types";
import type { AppContent } from "@/lib/types";

// Module-level singleton: same "resets on restart" tradeoff the rest of
// the mock data layer already has. Starts empty (no seed row) — the admin
// page's first save is what creates it, same as a fresh Supabase project.
const content = new Map<string, AppContent>();

export const mockAppContentRepository: AppContentRepository = {
  async getByKey(key) {
    await mockLatency();
    return content.get(key) ?? null;
  },

  async upsert(key, input) {
    await mockLatency();
    const row: AppContent = {
      key,
      title: input.title,
      content: input.content,
      isActive: input.isActive,
      updatedAt: new Date().toISOString(),
    };
    content.set(key, row);
    return row;
  },
};
