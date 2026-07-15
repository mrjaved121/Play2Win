import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapGameRow, mapPlayerRow, mapTransactionRow } from "@/lib/supabase/mappers";
import {
  computeGamePopularity,
  computeKpiSummary,
  computePlayerGrowth,
  computeRecentActivity,
  computeRetentionCohorts,
  computeRevenueTrend,
} from "@/lib/analytics/compute";
import type { AnalyticsRepository } from "@/lib/repositories/types";
import type { Game, Player, Transaction } from "@/lib/types";

const ANALYTICS_WINDOW_DAYS = 90;
const MAX_ROWS = 10000;

async function fetchPlayers(): Promise<Player[]> {
  const supabase = getSupabaseServerClient();
  const { data, error } = await supabase.from("players").select("*").limit(MAX_ROWS);
  if (error) throw new Error(`Supabase analytics players fetch failed: ${error.message}`);
  return (data ?? []).map(mapPlayerRow);
}

async function fetchGames(): Promise<Game[]> {
  const supabase = getSupabaseServerClient();
  const { data, error } = await supabase.from("games").select("*").limit(MAX_ROWS);
  if (error) throw new Error(`Supabase analytics games fetch failed: ${error.message}`);
  return (data ?? []).map(mapGameRow);
}

async function fetchRecentTransactions(): Promise<Transaction[]> {
  const supabase = getSupabaseServerClient();
  const since = new Date(Date.now() - ANALYTICS_WINDOW_DAYS * 24 * 60 * 60 * 1000).toISOString();
  const { data, error } = await supabase
    .from("transactions")
    .select("*, players(display_name), games(name)")
    .gte("created_at", since)
    .order("created_at", { ascending: false })
    .limit(MAX_ROWS);
  if (error) throw new Error(`Supabase analytics transactions fetch failed: ${error.message}`);
  return (data ?? []).map(mapTransactionRow);
}

// Note: this issues a few unbounded table scans per call (fine for an admin
// dashboard's polling cadence at prototype scale). At production scale, back
// these with materialized views or Postgres RPC aggregates instead.
export const supabaseAnalyticsRepository: AnalyticsRepository = {
  async getKpiSummary() {
    const [players, transactions] = await Promise.all([fetchPlayers(), fetchRecentTransactions()]);
    return computeKpiSummary(players, transactions);
  },

  async getRecentActivity(limit: number) {
    const [players, games, transactions] = await Promise.all([
      fetchPlayers(),
      fetchGames(),
      fetchRecentTransactions(),
    ]);
    return computeRecentActivity(players, games, transactions, limit);
  },

  async getRevenueTrend(days: number) {
    const transactions = await fetchRecentTransactions();
    return computeRevenueTrend(transactions, days);
  },

  async getPlayerGrowth(days: number) {
    const players = await fetchPlayers();
    return computePlayerGrowth(players, days);
  },

  async getGamePopularity() {
    const games = await fetchGames();
    return computeGamePopularity(games);
  },

  async getRetentionCohorts() {
    return computeRetentionCohorts();
  },
};
