import { seedPurchaseGuides } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import type { PurchaseGuideEntry } from "@/lib/types";
import type { PurchaseGuideRepository } from "@/lib/repositories/types";

const guides: PurchaseGuideEntry[] = seedPurchaseGuides;
let nextId = guides.length + 1;

function sortGuides(items: PurchaseGuideEntry[]): PurchaseGuideEntry[] {
  return [...items].sort((a, b) => {
    if (a.displayOrder !== b.displayOrder) return a.displayOrder - b.displayOrder;
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });
}

export const mockPurchaseGuideRepository: PurchaseGuideRepository = {
  async list() {
    await mockLatency();
    return sortGuides(guides);
  },

  async create(input) {
    await mockLatency();
    const now = new Date().toISOString();
    const maxOrder = guides.reduce((max, g) => Math.max(max, g.displayOrder), -1);
    const item: PurchaseGuideEntry = {
      id: `pg_${(nextId++).toString().padStart(3, "0")}`,
      title: input.title,
      content: input.content,
      isActive: input.isActive,
      displayOrder: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    };
    guides.push(item);
    return item;
  },

  async update(id, patch) {
    await mockLatency();
    const item = guides.find((g) => g.id === id);
    if (!item) throw new Error(`Purchase guide ${id} not found`);
    Object.assign(item, patch, { updatedAt: new Date().toISOString() });
    return item;
  },

  async remove(id) {
    await mockLatency();
    const idx = guides.findIndex((g) => g.id === id);
    if (idx >= 0) guides.splice(idx, 1);
  },
};
