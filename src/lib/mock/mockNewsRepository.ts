import { seedNews } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import type { NewsItem } from "@/lib/types";
import type { NewsRepository } from "@/lib/repositories/types";

const news: NewsItem[] = seedNews;
let nextId = news.length + 1;

function sortNews(items: NewsItem[]): NewsItem[] {
  return [...items].sort((a, b) => {
    if (a.displayOrder !== b.displayOrder) return a.displayOrder - b.displayOrder;
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });
}

export const mockNewsRepository: NewsRepository = {
  async list() {
    await mockLatency();
    return sortNews(news);
  },

  async create(input) {
    await mockLatency();
    const now = new Date().toISOString();
    const maxOrder = news.reduce((max, n) => Math.max(max, n.displayOrder), -1);
    const item: NewsItem = {
      id: `nw_${(nextId++).toString().padStart(3, "0")}`,
      title: input.title,
      content: input.content,
      isActive: input.isActive,
      displayOrder: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    };
    news.push(item);
    return item;
  },

  async update(id, patch) {
    await mockLatency();
    const item = news.find((n) => n.id === id);
    if (!item) throw new Error(`News item ${id} not found`);
    Object.assign(item, patch, { updatedAt: new Date().toISOString() });
    return item;
  },

  async remove(id) {
    await mockLatency();
    const idx = news.findIndex((n) => n.id === id);
    if (idx >= 0) news.splice(idx, 1);
  },
};
