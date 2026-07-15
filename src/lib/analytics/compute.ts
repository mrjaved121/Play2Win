// Pure aggregation functions shared by every data-source adapter (mock and
// Supabase alike) so KPI/chart math is defined exactly once. Adapters only
// differ in how they fetch the raw Player/Game/Transaction rows.
import { mulberry32 } from "@/lib/utils";
import type {
  ActivityEvent,
  Game,
  GamePopularity,
  KpiSummary,
  Player,
  RetentionCohort,
  TimeseriesPoint,
  Transaction,
} from "@/lib/types";

const DAY_MS = 24 * 60 * 60 * 1000;

function withinLastMs(iso: string, ms: number, now: number): boolean {
  return now - new Date(iso).getTime() <= ms;
}

function windowDeltaPct(current: number, previous: number): number {
  if (previous === 0) return current === 0 ? 0 : 100;
  return ((current - previous) / previous) * 100;
}

/** House take for a window: wagers collected minus payouts returned. */
function netRevenueInWindow(
  transactions: Transaction[],
  startMs: number,
  endMs: number,
): number {
  let total = 0;
  for (const t of transactions) {
    if (t.status !== "completed") continue;
    const ts = new Date(t.createdAt).getTime();
    if (ts < startMs || ts >= endMs) continue;
    if (t.type === "wager") total += -t.amount;
    if (t.type === "payout") total -= t.amount;
  }
  return Math.round(total);
}

export function computeKpiSummary(
  players: Player[],
  transactions: Transaction[],
): KpiSummary {
  const now = Date.now();

  const activePlayers24h = players.filter((p) =>
    withinLastMs(p.lastActiveAt, DAY_MS, now),
  ).length;

  const revenueCurrent = netRevenueInWindow(transactions, now - 30 * DAY_MS, now);
  const revenuePrevious = netRevenueInWindow(
    transactions,
    now - 60 * DAY_MS,
    now - 30 * DAY_MS,
  );

  const tx24hCurrent = transactions.filter((t) =>
    withinLastMs(t.createdAt, DAY_MS, now),
  ).length;
  const tx24hPrevious = transactions.filter((t) => {
    const ts = new Date(t.createdAt).getTime();
    return ts < now - DAY_MS && ts >= now - 2 * DAY_MS;
  }).length;

  const signups7dCurrent = players.filter((p) =>
    withinLastMs(p.joinedAt, 7 * DAY_MS, now),
  ).length;
  const signups7dPrevious = players.filter((p) => {
    const ts = new Date(p.joinedAt).getTime();
    return ts < now - 7 * DAY_MS && ts >= now - 14 * DAY_MS;
  }).length;

  const avgSessionMinutes =
    players.length === 0
      ? 0
      : players.reduce((sum, p) => {
          const perGame = p.gamesPlayed > 0 ? p.totalWagered / p.gamesPlayed : 0;
          return sum + Math.min(18, Math.max(4, perGame / 25));
        }, 0) / players.length;

  return {
    totalPlayers: players.length,
    activePlayers24h,
    totalRevenue: revenueCurrent,
    revenueDeltaPct: windowDeltaPct(revenueCurrent, revenuePrevious),
    transactions24h: tx24hCurrent,
    transactionsDeltaPct: windowDeltaPct(tx24hCurrent, tx24hPrevious),
    newSignups7d: signups7dCurrent,
    newSignupsDeltaPct: windowDeltaPct(signups7dCurrent, signups7dPrevious),
    averageSessionMinutes: Math.round(avgSessionMinutes * 10) / 10,
  };
}

export function computeRecentActivity(
  players: Player[],
  games: Game[],
  transactions: Transaction[],
  limit: number,
): ActivityEvent[] {
  const now = Date.now();
  const events: ActivityEvent[] = [];

  for (const t of transactions.slice(0, 400)) {
    if (t.type === "deposit" && t.status === "completed" && t.amount > 1500) {
      events.push({
        id: `ev_dep_${t.id}`,
        type: "deposit",
        message: `${t.playerName} deposited ${t.amount.toLocaleString()} CR`,
        timestamp: t.createdAt,
        severity: "good",
      });
    }
    if (t.type === "payout" && t.status === "completed" && t.amount > 1200) {
      events.push({
        id: `ev_win_${t.id}`,
        type: "big_win",
        message: `${t.playerName} won ${t.amount.toLocaleString()} CR on ${t.gameName ?? "a game"}`,
        timestamp: t.createdAt,
        severity: "warning",
      });
    }
    if (t.type === "withdrawal" && t.status === "failed") {
      events.push({
        id: `ev_wf_${t.id}`,
        type: "withdrawal",
        message: `Withdrawal failed for ${t.playerName} (${Math.abs(t.amount).toLocaleString()} CR)`,
        timestamp: t.createdAt,
        severity: "serious",
      });
    }
  }

  for (const p of players) {
    if (withinLastMs(p.joinedAt, 5 * DAY_MS, now)) {
      events.push({
        id: `ev_su_${p.id}`,
        type: "signup",
        message: `${p.displayName} signed up`,
        timestamp: p.joinedAt,
        severity: "good",
      });
    }
    if (p.status === "suspended" || p.status === "banned") {
      events.push({
        id: `ev_ban_${p.id}`,
        type: "suspension",
        message: `${p.displayName} was ${p.status}`,
        timestamp: p.lastActiveAt,
        severity: "critical",
      });
    }
  }

  for (const g of games) {
    if (withinLastMs(g.releaseDate, 45 * DAY_MS, now)) {
      events.push({
        id: `ev_game_${g.id}`,
        type: "game_added",
        message: `${g.name} was published to the catalog`,
        timestamp: g.releaseDate,
      });
    }
  }

  return events
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    .slice(0, limit);
}

export function computeRevenueTrend(
  transactions: Transaction[],
  days: number,
): TimeseriesPoint[] {
  const now = Date.now();
  const points: TimeseriesPoint[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const dayStart = now - (i + 1) * DAY_MS;
    const dayEnd = now - i * DAY_MS;
    points.push({
      date: new Date(dayEnd).toISOString().slice(0, 10),
      value: Math.max(0, netRevenueInWindow(transactions, dayStart, dayEnd)),
    });
  }
  return points;
}

export function computePlayerGrowth(players: Player[], days: number): TimeseriesPoint[] {
  const now = Date.now();
  const sortedJoinTimes = players
    .map((p) => new Date(p.joinedAt).getTime())
    .sort((a, b) => a - b);

  const points: TimeseriesPoint[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const cutoff = now - i * DAY_MS;
    let count = 0;
    for (const ts of sortedJoinTimes) {
      if (ts <= cutoff) count++;
      else break;
    }
    points.push({ date: new Date(cutoff).toISOString().slice(0, 10), value: count });
  }
  return points;
}

export function computeGamePopularity(games: Game[]): GamePopularity[] {
  return [...games]
    .sort((a, b) => b.totalSessions - a.totalSessions)
    .slice(0, 8)
    .map((g) => ({ gameId: g.id, gameName: g.name, sessions: g.totalSessions }));
}

/**
 * Retention needs per-session event history that this schema doesn't model
 * (see README "Known limitations"), so cohorts are synthesized from a fixed
 * seed rather than derived from players/transactions. Swap for a real query
 * against a `sessions` table if one is added.
 */
export function computeRetentionCohorts(seed = 4242): RetentionCohort[] {
  const rand = mulberry32(seed);
  const cohorts: RetentionCohort[] = [];
  for (let i = 5; i >= 0; i--) {
    const monthDate = new Date();
    monthDate.setMonth(monthDate.getMonth() - i);
    const day1 = 58 + Math.round(rand() * 14);
    const day7 = Math.round(day1 * (0.5 + rand() * 0.15));
    const day30 = Math.round(day7 * (0.35 + rand() * 0.2));
    cohorts.push({
      cohort: monthDate.toLocaleDateString("en-US", { month: "short", year: "2-digit" }),
      day0: 100,
      day1,
      day7,
      day30,
    });
  }
  return cohorts;
}
