import { mockPlayersRepository } from "@/lib/mock/mockPlayersRepository";
import { mockTransactionsRepository } from "@/lib/mock/mockTransactionsRepository";
import { mockGamesRepository } from "@/lib/mock/mockGamesRepository";
import { mockAnalyticsRepository } from "@/lib/mock/mockAnalyticsRepository";
import { mockAuthRepository } from "@/lib/mock/mockAuthRepository";
import { supabasePlayersRepository } from "@/lib/supabase/supabasePlayersRepository";
import { supabaseTransactionsRepository } from "@/lib/supabase/supabaseTransactionsRepository";
import { supabaseGamesRepository } from "@/lib/supabase/supabaseGamesRepository";
import { supabaseAnalyticsRepository } from "@/lib/supabase/supabaseAnalyticsRepository";
import { supabaseAuthRepository } from "@/lib/supabase/supabaseAuthRepository";
import type {
  AnalyticsRepository,
  AuthRepository,
  GamesRepository,
  PlayersRepository,
  TransactionsRepository,
} from "@/lib/repositories/types";

/**
 * Server-only data-source switch. DATA_SOURCE=supabase requires SUPABASE_URL
 * + SUPABASE_SERVICE_ROLE_KEY (see README.md). Defaults to the in-memory mock
 * data set so the dashboard runs fully offline out of the box.
 */
function isSupabaseDataSource(): boolean {
  return process.env.DATA_SOURCE === "supabase";
}

export function getPlayersRepository(): PlayersRepository {
  return isSupabaseDataSource() ? supabasePlayersRepository : mockPlayersRepository;
}

export function getTransactionsRepository(): TransactionsRepository {
  return isSupabaseDataSource() ? supabaseTransactionsRepository : mockTransactionsRepository;
}

export function getGamesRepository(): GamesRepository {
  return isSupabaseDataSource() ? supabaseGamesRepository : mockGamesRepository;
}

export function getAnalyticsRepository(): AnalyticsRepository {
  return isSupabaseDataSource() ? supabaseAnalyticsRepository : mockAnalyticsRepository;
}

export function getAuthRepository(): AuthRepository {
  return isSupabaseDataSource() ? supabaseAuthRepository : mockAuthRepository;
}
