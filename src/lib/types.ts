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
  /**
   * Stable device-generated id sent by mobile-game API clients (e.g. the
   * "Multiplier Climb" crash game) that never went through admin-facing
   * signup. Undefined for players seeded/managed only through this
   * dashboard. See CrashRepository.getOrCreatePlayerBalance.
   */
  guestId?: string;
  /**
   * Supabase Auth user id, set once this player has signed in via the
   * mobile app's real login/signup (see CrashRepository.linkAccount).
   * Undefined means this row is still an anonymous guest — admins should
   * treat its balance as tied to one device, not a portable account.
   */
  userId?: string;
  /**
   * The slot machine's server-side balance — a separate economy from
   * `creditBalance` (Multiplier Climb's), see SlotsRepository. Undefined
   * means this player has never synced a spin yet.
   */
  slotBalance?: number;
}

export interface SlotSpinEntry {
  id: string;
  playerId: string;
  bet: number;
  winAmount: number;
  isWin: boolean;
  isJackpot: boolean;
  outcome: string;
  symbols: string[];
  createdAt: string;
}

export interface SlotStats {
  totalSpins: number;
  totalWagered: number;
  totalWon: number;
  winCount: number;
  jackpotCount: number;
  netResult: number;
}

/** Lucky Wheel and Scratch Card — both server-authoritative "single decision" games sharing one round log. */
export type GameRoundType = "wheel" | "scratch";

export interface GameRoundEntry {
  id: string;
  playerId: string;
  gameType: GameRoundType;
  betAmount: number;
  winAmount: number;
  /** Game-specific shape — a WheelResult or ScratchResult (see src/lib/games/*.ts) — opaque to admin, stored as-is. */
  result: unknown;
  createdAt: string;
}

export interface GameRoundStats {
  totalRounds: number;
  totalWagered: number;
  totalWon: number;
  winCount: number;
  netResult: number;
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
  /** Freeform context for admin-initiated transactions, e.g. why a balance adjustment was made. */
  note?: string;
  createdAt: string;
}

export type GameCategory = "slots" | "table" | "arcade" | "puzzle";
export type GameStatus = "active" | "disabled" | "maintenance";
/** Which built-in mobile-app screen this catalog entry plays as, if any — see the Lobby's public catalog feed. */
export type GameEntryPoint = "slots" | "crash" | "wheel" | "scratch";

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
  /** Undefined means this is a "coming soon" catalog entry with no playable screen behind it yet. */
  appEntryPoint?: GameEntryPoint;
}

export type NewGameInput = {
  name: string;
  category: GameCategory;
  status: GameStatus;
  rtp: number;
  releaseDate: string;
  /** "" (not just omitted) is how the form's "None" option explicitly clears this on PATCH — see the games API routes. */
  appEntryPoint?: GameEntryPoint | "";
};

// "Help & Support" entries shown in the mobile app. Backed by the `news`
// table/repository name (kept from the original schema) — only the
// admin-facing labels changed.
export interface NewsItem {
  id: string;
  title: string;
  content: string;
  isActive: boolean;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}

export type NewNewsInput = {
  title: string;
  content: string;
  isActive: boolean;
};

/**
 * Generic keyed singleton text content — one row per named piece of
 * app-wide copy. First use: `key: "purchase_instructions"` ("How to Buy
 * Credits"). Not a payment system — just admin-editable text the mobile
 * app displays as-is.
 */
export interface AppContent {
  key: string;
  title: string;
  content: string;
  isActive: boolean;
  updatedAt: string;
}

export type AppContentInput = {
  title: string;
  content: string;
  isActive: boolean;
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

// ---------------------------------------------------------------------
// Multiplier Climb (crash game) — the game logic and round state live
// server-side here; the mobile app is just an API client (see
// src/lib/crash/engine.ts and src/lib/repositories/types.ts).
// ---------------------------------------------------------------------

export type CrashRoundStatus = "pending" | "collected" | "crashed";

/**
 * What a client is allowed to see about a round. While `status` is
 * "pending", `crashPoint`/`serverSeed` are withheld (that's the whole
 * point — the client can't know when it'll crash); they're only
 * populated once the round resolves, at which point they double as the
 * provably-fair reveal (verify: sha256(serverSeed) === serverSeedHash,
 * and recomputing computeCrashPoint(serverSeed, roundId) reproduces
 * crashPoint).
 */
export interface CrashRoundPublic {
  roundId: string;
  status: CrashRoundStatus;
  betAmount: number;
  startedAt: string;
  growthRate: number;
  serverSeedHash: string;
  payout?: number;
  resolvedMultiplier?: number;
  crashPoint?: number;
  serverSeed?: string;
}

/**
 * One resolved round in a player's crash history, as shown in the mobile
 * app's round history strip. Only ever covers `collected`/`crashed`
 * rounds — a `pending` round has no multiplier/outcome yet.
 */
export interface CrashHistoryEntry {
  roundId: string;
  bet: number;
  /** Cashed-out multiplier if won, or the crash point if lost. */
  multiplier: number;
  winAmount: number;
  isWin: boolean;
  timestamp: string;
}
