import { validateCrossingSettingsPatch } from "@/lib/crossing/engine";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import type { CrossingSettingsRepository } from "@/lib/repositories/types";
import type { CrossingSettings } from "@/lib/types";

const SETTINGS_ROW_ID = "default";

interface CrossingSettingsRow {
  id: string;
  rtp: number;
  min_bet: number;
  max_bet: number;
  max_win: number;
  easy_bust_pct: number;
  medium_bust_pct: number;
  hard_bust_pct: number;
  hardcore_bust_pct: number;
  updated_at: string;
}

function toDomain(row: CrossingSettingsRow): CrossingSettings {
  return {
    rtp: Number(row.rtp),
    minBet: Number(row.min_bet),
    maxBet: Number(row.max_bet),
    maxWin: Number(row.max_win),
    easyBustPct: Number(row.easy_bust_pct),
    mediumBustPct: Number(row.medium_bust_pct),
    hardBustPct: Number(row.hard_bust_pct),
    hardcoreBustPct: Number(row.hardcore_bust_pct),
    updatedAt: row.updated_at,
  };
}

export const supabaseCrossingSettingsRepository: CrossingSettingsRepository = {
  async get() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("crossing_settings")
      .select("*")
      .eq("id", SETTINGS_ROW_ID)
      .single();
    if (error) throw new Error(`Supabase crossingSettings.get failed: ${error.message}`);
    return toDomain(data as CrossingSettingsRow);
  },

  async update(patch) {
    const supabase = getSupabaseServerClient();

    const { data: current, error: readError } = await supabase
      .from("crossing_settings")
      .select("*")
      .eq("id", SETTINGS_ROW_ID)
      .single();
    if (readError) throw new Error(`Supabase crossingSettings.update lookup failed: ${readError.message}`);
    const currentDomain = toDomain(current as CrossingSettingsRow);

    validateCrossingSettingsPatch(patch, currentDomain.rtp);
    const merged = { ...currentDomain, ...patch };
    if (merged.minBet >= merged.maxBet) {
      throw new Error("minBet must be less than maxBet");
    }

    const { data, error } = await supabase
      .from("crossing_settings")
      .update({
        rtp: merged.rtp,
        min_bet: merged.minBet,
        max_bet: merged.maxBet,
        max_win: merged.maxWin,
        easy_bust_pct: merged.easyBustPct,
        medium_bust_pct: merged.mediumBustPct,
        hard_bust_pct: merged.hardBustPct,
        hardcore_bust_pct: merged.hardcoreBustPct,
        updated_at: new Date().toISOString(),
      })
      .eq("id", SETTINGS_ROW_ID)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase crossingSettings.update failed: ${error.message}`);
    return toDomain(data as CrossingSettingsRow);
  },
};
