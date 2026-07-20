import type {
  ActivityEvent,
  AdminUser,
  AppContent,
  AppContentInput,
  CrashHistoryEntry,
  CrashLeaderboard,
  CrashLiveStatus,
  CrashRoundPublic,
  CrashSettings,
  Game,
  GamePopularity,
  GameRoundEntry,
  GameRoundStats,
  GameRoundType,
  KpiSummary,
  NewGameInput,
  NewNewsInput,
  NewPurchaseGuideInput,
  NewsItem,
  Paginated,
  Player,
  PlayerStatus,
  PurchaseGuideEntry,
  RetentionCohort,
  SlotSpinEntry,
  SlotStats,
  Transaction,
  TransactionStatus,
  TransactionType,
  TimeseriesPoint,
} from "@/lib/types";

export interface PlayersListParams {
  search?: string;
  status?: PlayerStatus;
  page: number;
  pageSize: number;
}

export interface PlayersRepository {
  list(params: PlayersListParams): Promise<Paginated<Player>>;
  getById(id: string): Promise<Player | null>;
  updateStatus(id: string, status: PlayerStatus): Promise<Player>;
  /**
   * Credits (positive `amount`) or debits (negative) a player's balance,
   * clamped at 0, and records a `bonus`-type transaction for the audit
   * trail. Used by the admin "Add coins" action.
   */
  adjustBalance(id: string, params: { amount: number; note?: string }): Promise<Player>;
}

export interface TransactionsListParams {
  search?: string;
  type?: TransactionType;
  status?: TransactionStatus;
  from?: string;
  to?: string;
  page: number;
  pageSize: number;
}

export interface TransactionsRepository {
  list(params: TransactionsListParams): Promise<Paginated<Transaction>>;
}

export interface GamesRepository {
  list(): Promise<Game[]>;
  create(input: NewGameInput): Promise<Game>;
  update(id: string, patch: Partial<Game>): Promise<Game>;
  remove(id: string): Promise<void>;
}

/** Backs the admin "Help & Support" page (mobile-app text entries). */
export interface NewsRepository {
  list(): Promise<NewsItem[]>;
  create(input: NewNewsInput): Promise<NewsItem>;
  update(id: string, patch: Partial<NewsItem>): Promise<NewsItem>;
  remove(id: string): Promise<void>;
}

/** Backs the admin "How to Buy" CMS (mobile-app purchase-guide entries) — same shape/pattern as NewsRepository. */
export interface PurchaseGuideRepository {
  list(): Promise<PurchaseGuideEntry[]>;
  create(input: NewPurchaseGuideInput): Promise<PurchaseGuideEntry>;
  update(id: string, patch: Partial<PurchaseGuideEntry>): Promise<PurchaseGuideEntry>;
  remove(id: string): Promise<void>;
}

export interface AnalyticsRepository {
  getKpiSummary(): Promise<KpiSummary>;
  getRecentActivity(limit: number): Promise<ActivityEvent[]>;
  getRevenueTrend(days: number): Promise<TimeseriesPoint[]>;
  getPlayerGrowth(days: number): Promise<TimeseriesPoint[]>;
  getGamePopularity(): Promise<GamePopularity[]>;
  getRetentionCohorts(): Promise<RetentionCohort[]>;
}

export interface AuthRepository {
  signIn(email: string, password: string): Promise<AdminUser | null>;
}

/**
 * Server-side implementation of the Multiplier Climb crash game. The
 * mobile app never computes a crash point or a payout itself — it only
 * calls these operations and renders whatever they return. All methods
 * throw a plain `Error` (message is safe to surface to the client) on
 * invalid input/state — see the API routes under
 * src/app/api/games/crash/ for how those get mapped to HTTP responses.
 */
export interface CrashRepository {
  /**
   * Fetches (creating on first sight) the current balance. `accessToken`,
   * when present and valid, always takes priority over `guestId` — that's
   * what makes a signed-in account's balance portable across devices
   * instead of pinned to whichever device's guestId originally earned it.
   * An invalid/expired token falls back to `guestId` rather than erroring.
   */
  getOrCreatePlayerBalance(params: {
    guestId: string;
    accessToken?: string;
  }): Promise<{ playerId: string; balance: number }>;

  /**
   * Deducts betAmount and starts a new round. The returned round's
   * crashPoint/serverSeed are withheld until it resolves.
   */
  placeBet(params: { guestId: string; betAmount: number; accessToken?: string }): Promise<{
    round: CrashRoundPublic;
    balance: number;
  }>;

  /**
   * Cashes out `roundId`. If the (hidden) crash time has already passed,
   * settles it as a loss instead — a player can't out-run a slow network
   * request past the crash point.
   */
  collect(params: { guestId: string; roundId: string; accessToken?: string }): Promise<{
    round: CrashRoundPublic;
    balance: number;
  }>;

  /** Reconciliation after the app backgrounds/reopens mid-round. */
  getState(params: {
    guestId: string;
    roundId: string;
    accessToken?: string;
  }): Promise<CrashRoundPublic | null>;

  /**
   * Ensures a canonical player row exists for `userId`, adopting this
   * device's guest balance into it the *first* time an account links
   * (so signing up doesn't erase progress already made as a guest).
   * Idempotent, and safe to call from any device: once linked, every
   * gameplay call authenticates by `accessToken` (see the other methods),
   * so a second device automatically reaches the same account balance
   * without needing its own guest progress merged in.
   */
  linkAccount(params: {
    guestId: string;
    userId: string;
    email: string;
    displayName?: string;
  }): Promise<{ playerId: string; balance: number }>;

  /**
   * A player's past resolved rounds (collected or crashed), most recent
   * first — backs the mobile app's round history strip. `pending` rounds
   * are never included.
   */
  getHistory(params: {
    guestId: string;
    accessToken?: string;
    page: number;
    pageSize: number;
  }): Promise<Paginated<CrashHistoryEntry>>;

  /** Platform-wide activity + top rounds — no guestId/accessToken, this isn't per-player. */
  getLeaderboard(): Promise<CrashLeaderboard>;

  /** Admin-only: every currently still-flying round across all players — backs the live round monitor. */
  getLiveRounds(): Promise<CrashLiveStatus>;

  /**
   * Admin-only emergency stop: voids and fully refunds every currently
   * still-flying round platform-wide (never a targeted win/loss for one
   * player — see the doc comment on CrashRoundPublic.voided). Meant for
   * "something's wrong, pause the game" situations, not for shaping any
   * individual round's outcome.
   */
  emergencyStopAll(): Promise<{ voidedCount: number; refundedTotal: number }>;
}

/**
 * Admin-adjustable global Multiplier Climb parameters — see
 * src/lib/crash/engine.ts for validation rules and src/lib/types.ts's
 * CrashSettings for field docs.
 */
export interface CrashSettingsRepository {
  get(): Promise<CrashSettings>;
  /** Validates against engine.ts's option sets/ranges (throws a plain, client-safe Error on failure) before persisting. */
  update(patch: Partial<Pick<CrashSettings, "rtp" | "instantCrashRate" | "minBet" | "maxBet">>): Promise<CrashSettings>;
}

/**
 * Server-side counterpart to the slot machine. Unlike CrashRepository,
 * the RNG/payout decision itself still happens client-side (unchanged —
 * see the mobile app's SpinEngine); this repository only records what
 * already happened and keeps a server-side mirror of the balance, so it
 * never "rejects" a spin the way `CrashRepository.placeBet` can.
 */
export interface SlotsRepository {
  /**
   * Records one already-resolved spin and returns the authoritative new
   * balance. `clientBalance` (the player's local balance right after this
   * spin) seeds the server balance the *first* time this player syncs —
   * after that, the server is authoritative and `clientBalance` is
   * ignored. Same `accessToken`-over-`guestId` resolution as
   * CrashRepository; see playerResolution.ts.
   */
  recordSpin(params: {
    guestId: string;
    accessToken?: string;
    bet: number;
    winAmount: number;
    isWin: boolean;
    isJackpot: boolean;
    outcome: string;
    symbols: string[];
    clientBalance: number;
  }): Promise<{ balance: number }>;

  getStats(playerId: string): Promise<SlotStats>;

  getHistory(playerId: string, params: { page: number; pageSize: number }): Promise<Paginated<SlotSpinEntry>>;
}

/** Backs generic keyed singleton text content (e.g. "How to Buy Credits"). */
export interface AppContentRepository {
  /** Null if this key has never been saved yet. */
  getByKey(key: string): Promise<AppContent | null>;
  /** Creates the row on first save, updates it otherwise. */
  upsert(key: string, input: AppContentInput): Promise<AppContent>;
}

/**
 * Unified backend for Lucky Wheel and Scratch Card — both are
 * server-authoritative "single decision" games (bet in, one RNG
 * resolution, result out), unlike CrashRepository (multi-step
 * bet/collect) or SlotsRepository (outcome decided client-side). The
 * actual RNG lives in src/lib/games/wheel.ts and scratch.ts; this
 * repository is the shared bet-validate/balance/transaction/logging
 * plumbing around whichever one `gameType` selects.
 */
export interface GameRoundRepository {
  play(params: {
    gameType: GameRoundType;
    guestId: string;
    accessToken?: string;
    bet: number;
  }): Promise<{ result: unknown; winAmount: number; newBalance: number; transactionId: string }>;

  getStats(playerId: string, gameType: GameRoundType): Promise<GameRoundStats>;

  getHistory(
    playerId: string,
    gameType: GameRoundType,
    params: { page: number; pageSize: number },
  ): Promise<Paginated<GameRoundEntry>>;
}
