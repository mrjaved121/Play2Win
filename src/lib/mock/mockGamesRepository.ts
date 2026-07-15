import { seedGames } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import type { Game } from "@/lib/types";
import type { GamesRepository } from "@/lib/repositories/types";

const games: Game[] = seedGames;
let nextId = games.length + 1;

export const mockGamesRepository: GamesRepository = {
  async list() {
    await mockLatency();
    return [...games].sort(
      (a, b) => new Date(b.releaseDate).getTime() - new Date(a.releaseDate).getTime(),
    );
  },

  async create(input) {
    await mockLatency();
    const game: Game = {
      id: `gm_${(nextId++).toString().padStart(3, "0")}`,
      name: input.name,
      category: input.category,
      status: input.status,
      rtp: input.rtp,
      totalSessions: 0,
      totalWagered: 0,
      totalPayout: 0,
      releaseDate: input.releaseDate,
      accentSeed: games.length,
    };
    games.push(game);
    return game;
  },

  async update(id, patch) {
    await mockLatency();
    const game = games.find((g) => g.id === id);
    if (!game) throw new Error(`Game ${id} not found`);
    Object.assign(game, patch);
    return game;
  },

  async remove(id) {
    await mockLatency();
    const idx = games.findIndex((g) => g.id === id);
    if (idx >= 0) games.splice(idx, 1);
  },
};
