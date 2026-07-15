// Domain types for Project Blackhole Admin Dashboard.
// All monetary fields are in "credits" — a simulated in-platform currency used
// for this research prototype. No real payment processing is involved.

export type PlayerStatus = "active" | "suspended" | "banned";
export type VipTier = "bronze" | "silver" | "gold" | "platinum";

export interface Player {
  id: string;
  displayName: string;
  email: string;
  status: PlayerStatus;
  vipTier: VipTier;
  creditBalance: number;
  totalWagered: number;
  totalDeposited: number;
  gamesPlayed: number;
  country: string;
  joinedAt: string;
  lastActiveAt: string;
}

export type TransactionType =
  | "deposit"
  | "withdrawal"
  | "wager"
  | "payout"
  | "bonus";
export type TransactionStatus = "completed" | "pending" | "failed" | "reversed";

export interface Transaction {
  id: string;
  playerId: string;
  playerName: string;
  type: TransactionType;
  status: TransactionStatus;
  amount: number;
  gameId?: string;
  gameName?: string;
  createdAt: string;
}

export type GameCategory = "slots" | "table" | "arcade" | "puzzle";
export type GameStatus = "active" | "disabled" | "maintenance";

export interface Game {
  id: string;
  name: string;
  category: GameCategory;
  status: GameStatus;
  rtp: number;
  totalSessions: number;
  totalWagered: number;
  totalPayout: number;
  releaseDate: string;
  accentSeed: number;
}

export type NewGameInput = {
  name: string;
  category: GameCategory;
  status: GameStatus;
  rtp: number;
  releaseDate: string;
};

export interface TimeseriesPoint {
  date: string;
  value: number;
}

export interface KpiSummary {
  totalPlayers: number;
  activePlayers24h: number;
  totalRevenue: number;
  revenueDeltaPct: number;
  transactions24h: number;
  transactionsDeltaPct: number;
  newSignups7d: number;
  newSignupsDeltaPct: number;
  averageSessionMinutes: number;
}

export type ActivitySeverity = "good" | "warning" | "serious" | "critical";

export interface ActivityEvent {
  id: string;
  type:
    | "signup"
    | "deposit"
    | "withdrawal"
    | "big_win"
    | "suspension"
    | "game_added";
  message: string;
  timestamp: string;
  severity?: ActivitySeverity;
}

export interface GamePopularity {
  gameId: string;
  gameName: string;
  sessions: number;
}

export interface RetentionCohort {
  cohort: string;
  day0: number;
  day1: number;
  day7: number;
  day30: number;
}

export type AdminRole = "superadmin" | "admin" | "analyst";

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: AdminRole;
}

export interface Paginated<T> {
  items: T[];
  total: number;
}
