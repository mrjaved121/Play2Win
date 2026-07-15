import type {
  ActivityEvent,
  AdminUser,
  Game,
  GamePopularity,
  KpiSummary,
  NewGameInput,
  Paginated,
  Player,
  PlayerStatus,
  RetentionCohort,
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
