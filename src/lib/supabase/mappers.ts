// snake_case (Postgres) <-> camelCase (app) row mappers for the Supabase adapters.
import type {
  AppContent,
  Game,
  GameRoundEntry,
  NewsItem,
  Player,
  PurchaseGuideEntry,
  SlotSpinEntry,
  Transaction,
} from "@/lib/types";

export function mapPlayerRow(row: Record<string, unknown>): Player {
  return {
    id: row.id as string,
    displayName: row.display_name as string,
    email: row.email as string,
    status: row.status as Player["status"],
    vipTier: row.vip_tier as Player["vipTier"],
    creditBalance: Number(row.credit_balance),
    totalWagered: Number(row.total_wagered),
    totalDeposited: Number(row.total_deposited),
    gamesPlayed: Number(row.games_played),
    country: row.country as string,
    joinedAt: row.joined_at as string,
    lastActiveAt: row.last_active_at as string,
    guestId: (row.guest_id as string | null) ?? undefined,
    userId: (row.user_id as string | null) ?? undefined,
    slotBalance: row.slot_balance != null ? Number(row.slot_balance) : undefined,
  };
}

export function mapSlotSpinRow(row: Record<string, unknown>): SlotSpinEntry {
  return {
    id: row.id as string,
    playerId: row.player_id as string,
    bet: Number(row.bet),
    winAmount: Number(row.win_amount),
    isWin: Boolean(row.is_win),
    isJackpot: Boolean(row.jackpot_hit),
    outcome: row.outcome as string,
    symbols: (row.symbols as string[] | null) ?? [],
    createdAt: row.created_at as string,
  };
}

export function mapGameRoundRow(row: Record<string, unknown>): GameRoundEntry {
  return {
    id: row.id as string,
    playerId: row.player_id as string,
    gameType: row.game_type as GameRoundEntry["gameType"],
    betAmount: Number(row.bet_amount),
    winAmount: Number(row.win_amount),
    result: row.result,
    createdAt: row.created_at as string,
  };
}

export function mapGameRow(row: Record<string, unknown>): Game {
  return {
    id: row.id as string,
    name: row.name as string,
    category: row.category as Game["category"],
    status: row.status as Game["status"],
    rtp: Number(row.rtp),
    totalSessions: Number(row.total_sessions),
    totalWagered: Number(row.total_wagered),
    totalPayout: Number(row.total_payout),
    releaseDate: row.release_date as string,
    accentSeed: Number(row.accent_seed ?? 0),
    appEntryPoint: (row.app_entry_point as Game["appEntryPoint"] | null) ?? undefined,
  };
}

export function mapNewsRow(row: Record<string, unknown>): NewsItem {
  return {
    id: row.id as string,
    title: row.title as string,
    content: row.content as string,
    isActive: Boolean(row.is_active),
    displayOrder: Number(row.display_order),
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function mapPurchaseGuideRow(row: Record<string, unknown>): PurchaseGuideEntry {
  return {
    id: row.id as string,
    title: row.title as string,
    content: row.content as string,
    isActive: Boolean(row.is_active),
    displayOrder: Number(row.display_order),
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function mapAppContentRow(row: Record<string, unknown>): AppContent {
  return {
    key: row.key as string,
    title: (row.title as string | null) ?? "",
    content: (row.content as string | null) ?? "",
    isActive: Boolean(row.is_active),
    updatedAt: row.updated_at as string,
  };
}

export function mapTransactionRow(row: Record<string, unknown>): Transaction {
  const playerRel = row.players as { display_name?: string } | null | undefined;
  const gameRel = row.games as { name?: string } | null | undefined;
  return {
    id: row.id as string,
    playerId: row.player_id as string,
    playerName: playerRel?.display_name ?? (row.player_name as string) ?? "Unknown",
    type: row.type as Transaction["type"],
    status: row.status as Transaction["status"],
    amount: Number(row.amount),
    gameId: (row.game_id as string) ?? undefined,
    gameName: gameRel?.name ?? (row.game_name as string | undefined),
    note: (row.note as string | null) ?? undefined,
    createdAt: row.created_at as string,
  };
}
