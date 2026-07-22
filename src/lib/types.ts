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
export type GameEntryPoint = "slots" | "crash" | "wheel" | "scratch" | "crossing";

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
 * app-wide copy, for content that's genuinely a single block (unlike
 * PurchaseGuideEntry below, which is a managed list). Not currently used
 * by any admin page — kept as reusable infrastructure for the next
 * single-block content need. Not a payment system either way — just
 * admin-editable text the mobile app displays as-is.
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

/**
 * One "How to Buy Credits" entry (e.g. one payment method, or an FAQ
 * item) — same list-of-entries shape as NewsItem, backing the admin
 * How to Buy CMS and the mobile app's purchase-guide screen. Display-only
 * content, same as NewsItem — not a payment system.
 */
export interface PurchaseGuideEntry {
  id: string;
  title: string;
  content: string;
  isActive: boolean;
  displayOrder: number;
  createdAt: string;
  updatedAt: string;
}

export type NewPurchaseGuideInput = {
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
  /** The RTP/instant-crash-rate settings live when this round started — see engine.ts's computeCrashPoint doc comment. */
  rtp?: number;
  instantCrashRate?: number;
  /**
   * True only for a round an admin ended via the emergency-stop "refund
   * all" action (see CrashRepository.emergencyStopAll) — `status` is still
   * "crashed" (never "collected", since this isn't a win) but `payout`
   * equals the full bet back, not a genuine outcome. Never set by ordinary
   * gameplay, and never targets one player — see the repository doc
   * comment for why.
   */
  voided?: boolean;
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
  /** Where this round actually busted, win or lose — the provably-fair reveal, always populated once resolved. */
  crashPoint: number;
  winAmount: number;
  isWin: boolean;
  timestamp: string;
  /** See CrashRoundPublic.voided — an admin-refunded round, not a real win or loss. */
  voided?: boolean;
}

/** One row in the platform-wide crash leaderboard — no player id, just a display name. */
export interface CrashLeaderboardEntry {
  playerName: string;
  bet: number;
  multiplier: number;
  payout: number;
}

/** Platform-wide (not per-player) crash activity — backs the mobile app's "Leaderboard"/"Stats" tabs. */
export interface CrashLeaderboard {
  totalBets: number;
  totalWagered: number;
  totalPayout: number;
  topWins: CrashLeaderboardEntry[];
  topBets: CrashLeaderboardEntry[];
}

/**
 * Admin-adjustable, global (not per-player) Multiplier Climb parameters —
 * see src/lib/crash/engine.ts for the option sets/ranges these are
 * validated against and CrashSettingsRepository for storage. Changes only
 * affect rounds started *after* the change; an in-flight round keeps the
 * rtp/instantCrashRate it was minted with (see CrashRoundPublic).
 */
export interface CrashSettings {
  rtp: number;
  instantCrashRate: number;
  minBet: number;
  maxBet: number;
  updatedAt: string;
}

/**
 * One still-flying round, as shown in the admin "live round monitor" —
 * note there's no single platform-wide "current round": Multiplier Climb
 * gives each player their own independent flight (see
 * CrashRepository.placeBet's `findJoinableRound` doc comment), so this is
 * a snapshot across *all* players' currently-pending rounds at once.
 */
export interface CrashLiveRoundEntry {
  roundId: string;
  playerId: string;
  playerName: string;
  betAmount: number;
  startedAt: string;
  growthRate: number;
}

export interface CrashLiveStatus {
  rounds: CrashLiveRoundEntry[];
  activeBets: number;
  totalWagered: number;
  /** Server clock at response time — lets the admin UI compute "multiplier right now" without trusting its own clock. */
  serverTime: string;
}

export type CrossingDifficulty = "easy" | "medium" | "hard" | "hardcore";
export type CrossingRoundStatus = "pending" | "collected" | "busted";

/**
 * The full per-lane payout ladder for one difficulty tier — a pure function
 * of (rtp, bustPct, laneCount), so unlike a crash point it holds no secret
 * and is shown to the player before they bet (see engine.ts's buildLadder).
 */
export interface CrossingLadder {
  difficulty: CrossingDifficulty;
  laneCount: number;
  bustPct: number;
  /** ladder[i] = payout multiplier for surviving lane i+1. */
  ladder: number[];
}

/**
 * What a client is allowed to see about a round. `serverSeed` stays hidden
 * until the round resolves (busted or collected) — at that point it doubles
 * as the provably-fair reveal (verify: sha256(serverSeed) === serverSeedHash,
 * and replaying engine.ts's isLaneBust for lanes 1..currentLane reproduces
 * the exact survive/bust sequence this round actually played out).
 */
export interface CrossingRoundPublic {
  roundId: string;
  status: CrossingRoundStatus;
  difficulty: CrossingDifficulty;
  betAmount: number;
  laneCount: number;
  /** 0..laneCount — lanes survived so far. */
  currentLane: number;
  ladder: number[];
  clientSeed: string;
  serverSeedHash: string;
  startedAt: string;
  payout?: number;
  resolvedMultiplier?: number;
  serverSeed?: string;
  /** The rtp/bustPct settings live when this round started — snapshotted so a later settings change can't retroactively change a past round's reveal. */
  rtp?: number;
  bustPct?: number;
  /** See CrashRoundPublic.voided — same "admin emergency-stop refund", never a targeted individual outcome. */
  voided?: boolean;
}

/** One resolved round in a player's history strip. Only ever `collected`/`busted` — a `pending` round has no outcome yet. */
export interface CrossingHistoryEntry {
  roundId: string;
  bet: number;
  difficulty: CrossingDifficulty;
  lanesCleared: number;
  /** Cashed-out multiplier if won, 0 if busted. */
  multiplier: number;
  winAmount: number;
  isWin: boolean;
  timestamp: string;
  voided?: boolean;
}

/** One row in the platform-wide crossing leaderboard — no player id, just a display name. */
export interface CrossingLeaderboardEntry {
  playerName: string;
  bet: number;
  difficulty: CrossingDifficulty;
  multiplier: number;
  payout: number;
}

/** Platform-wide (not per-player) crossing activity — backs the mobile app's "live wins" ticker. */
export interface CrossingLeaderboard {
  totalBets: number;
  totalWagered: number;
  totalPayout: number;
  topWins: CrossingLeaderboardEntry[];
}

/**
 * Admin-adjustable, global (not per-player) Multiplier Crossing parameters —
 * see src/lib/crossing/engine.ts for the option sets/ranges these are
 * validated against. Changes only affect rounds started *after* the
 * change; an in-flight round keeps the rtp/bustPct it was minted with
 * (see CrossingRoundPublic).
 */
export interface CrossingSettings {
  rtp: number;
  minBet: number;
  maxBet: number;
  maxWin: number;
  easyBustPct: number;
  mediumBustPct: number;
  hardBustPct: number;
  hardcoreBustPct: number;
  updatedAt: string;
}

/** One in-progress round, as shown in the admin "live round monitor" — a snapshot across all players' currently-pending rounds. */
export interface CrossingLiveRoundEntry {
  roundId: string;
  playerId: string;
  playerName: string;
  difficulty: CrossingDifficulty;
  betAmount: number;
  currentLane: number;
  laneCount: number;
  startedAt: string;
}

export interface CrossingLiveStatus {
  rounds: CrossingLiveRoundEntry[];
  activeBets: number;
  totalWagered: number;
  serverTime: string;
}
