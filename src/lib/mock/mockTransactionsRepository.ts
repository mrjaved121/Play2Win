import { seedTransactions } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import type {
  TransactionsListParams,
  TransactionsRepository,
} from "@/lib/repositories/types";

export const mockTransactionsRepository: TransactionsRepository = {
  async list({ search, type, status, from, to, page, pageSize }: TransactionsListParams) {
    await mockLatency();
    let filtered = seedTransactions;

    if (type) filtered = filtered.filter((t) => t.type === type);
    if (status) filtered = filtered.filter((t) => t.status === status);
    if (from) {
      const fromMs = new Date(from).getTime();
      filtered = filtered.filter((t) => new Date(t.createdAt).getTime() >= fromMs);
    }
    if (to) {
      const toMs = new Date(to).getTime();
      filtered = filtered.filter((t) => new Date(t.createdAt).getTime() <= toMs);
    }
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter(
        (t) =>
          t.playerName.toLowerCase().includes(q) ||
          t.id.toLowerCase().includes(q) ||
          t.gameName?.toLowerCase().includes(q),
      );
    }

    const total = filtered.length;
    const start = (page - 1) * pageSize;
    const items = filtered.slice(start, start + pageSize);
    return { items, total };
  },
};
