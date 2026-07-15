import { seedGames, seedPlayers, seedTransactions } from "@/lib/mock/seedData";
import { mockLatency } from "@/lib/mock/delay";
import {
  computeGamePopularity,
  computeKpiSummary,
  computePlayerGrowth,
  computeRecentActivity,
  computeRetentionCohorts,
  computeRevenueTrend,
} from "@/lib/analytics/compute";
import type { AnalyticsRepository } from "@/lib/repositories/types";

export const mockAnalyticsRepository: AnalyticsRepository = {
  async getKpiSummary() {
    await mockLatency();
    return computeKpiSummary(seedPlayers, seedTransactions);
  },

  async getRecentActivity(limit: number) {
    await mockLatency();
    return computeRecentActivity(seedPlayers, seedGames, seedTransactions, limit);
  },

  async getRevenueTrend(days: number) {
    await mockLatency();
    return computeRevenueTrend(seedTransactions, days);
  },

  async getPlayerGrowth(days: number) {
    await mockLatency();
    return computePlayerGrowth(seedPlayers, days);
  },

  async getGamePopularity() {
    await mockLatency();
    return computeGamePopularity(seedGames);
  },

  async getRetentionCohorts() {
    await mockLatency();
    return computeRetentionCohorts();
  },
};
