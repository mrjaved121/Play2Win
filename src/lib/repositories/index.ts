import { mockPlayersRepository } from "@/lib/mock/mockPlayersRepository";
import { mockTransactionsRepository } from "@/lib/mock/mockTransactionsRepository";
import { mockGamesRepository } from "@/lib/mock/mockGamesRepository";
import { mockNewsRepository } from "@/lib/mock/mockNewsRepository";
import { mockAnalyticsRepository } from "@/lib/mock/mockAnalyticsRepository";
import { mockAuthRepository } from "@/lib/mock/mockAuthRepository";
import { mockCrashRepository } from "@/lib/mock/mockCrashRepository";
import { mockCrashSettingsRepository } from "@/lib/mock/mockCrashSettingsRepository";
import { mockSlotsRepository } from "@/lib/mock/mockSlotsRepository";
import { mockAppContentRepository } from "@/lib/mock/mockAppContentRepository";
import { mockGameRoundRepository } from "@/lib/mock/mockGameRoundRepository";
import { supabasePlayersRepository } from "@/lib/supabase/supabasePlayersRepository";
import { supabaseTransactionsRepository } from "@/lib/supabase/supabaseTransactionsRepository";
import { supabaseGamesRepository } from "@/lib/supabase/supabaseGamesRepository";
import { supabaseNewsRepository } from "@/lib/supabase/supabaseNewsRepository";
import { supabaseAnalyticsRepository } from "@/lib/supabase/supabaseAnalyticsRepository";
import { supabaseAuthRepository } from "@/lib/supabase/supabaseAuthRepository";
import { supabaseCrashRepository } from "@/lib/supabase/supabaseCrashRepository";
import { supabaseCrashSettingsRepository } from "@/lib/supabase/supabaseCrashSettingsRepository";
import { supabaseSlotsRepository } from "@/lib/supabase/supabaseSlotsRepository";
import { supabaseAppContentRepository } from "@/lib/supabase/supabaseAppContentRepository";
import { supabaseGameRoundRepository } from "@/lib/supabase/supabaseGameRoundRepository";
import type {
  AnalyticsRepository,
  AppContentRepository,
  AuthRepository,
  CrashRepository,
  CrashSettingsRepository,
  GameRoundRepository,
  GamesRepository,
  NewsRepository,
  PlayersRepository,
  SlotsRepository,
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

export function getNewsRepository(): NewsRepository {
  return isSupabaseDataSource() ? supabaseNewsRepository : mockNewsRepository;
}

export function getAnalyticsRepository(): AnalyticsRepository {
  return isSupabaseDataSource() ? supabaseAnalyticsRepository : mockAnalyticsRepository;
}

export function getAuthRepository(): AuthRepository {
  return isSupabaseDataSource() ? supabaseAuthRepository : mockAuthRepository;
}

export function getCrashRepository(): CrashRepository {
  return isSupabaseDataSource() ? supabaseCrashRepository : mockCrashRepository;
}

export function getCrashSettingsRepository(): CrashSettingsRepository {
  return isSupabaseDataSource() ? supabaseCrashSettingsRepository : mockCrashSettingsRepository;
}

export function getSlotsRepository(): SlotsRepository {
  return isSupabaseDataSource() ? supabaseSlotsRepository : mockSlotsRepository;
}

export function getAppContentRepository(): AppContentRepository {
  return isSupabaseDataSource() ? supabaseAppContentRepository : mockAppContentRepository;
}

export function getGameRoundRepository(): GameRoundRepository {
  return isSupabaseDataSource() ? supabaseGameRoundRepository : mockGameRoundRepository;
}
