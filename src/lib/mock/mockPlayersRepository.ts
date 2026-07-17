import { randomUUID } from "crypto";
import { seedPlayers, seedTransactions } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import type { Player, Transaction } from "@/lib/types";
import type {
  PlayersListParams,
  PlayersRepository,
} from "@/lib/repositories/types";

const players: Player[] = seedPlayers;

export const mockPlayersRepository: PlayersRepository = {
  async list({ search, status, page, pageSize }: PlayersListParams) {
    await mockLatency();
    let filtered = players;
    if (status) {
      filtered = filtered.filter((p) => p.status === status);
    }
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter(
        (p) =>
          p.displayName.toLowerCase().includes(q) ||
          p.email.toLowerCase().includes(q) ||
          p.id.toLowerCase().includes(q),
      );
    }
    filtered = [...filtered].sort(
      (a, b) => new Date(b.lastActiveAt).getTime() - new Date(a.lastActiveAt).getTime(),
    );
    const total = filtered.length;
    const start = (page - 1) * pageSize;
    const items = filtered.slice(start, start + pageSize);
    return { items, total };
  },

  async getById(id: string) {
    await mockLatency();
    return players.find((p) => p.id === id) ?? null;
  },

  async updateStatus(id: string, status) {
    await mockLatency();
    const player = players.find((p) => p.id === id);
    if (!player) throw new Error(`Player ${id} not found`);
    player.status = status;
    return player;
  },

  async adjustBalance(id: string, { amount, note }) {
    await mockLatency();
    const player = players.find((p) => p.id === id);
    if (!player) throw new Error(`Player ${id} not found`);
    player.creditBalance = Math.max(0, player.creditBalance + amount);

    const txn: Transaction = {
      id: `tx_${randomUUID().slice(0, 8)}`,
      playerId: player.id,
      playerName: player.displayName,
      type: "bonus",
      status: "completed",
      amount,
      note,
      createdAt: new Date().toISOString(),
    };
    seedTransactions.unshift(txn);

    return player;
  },
};
