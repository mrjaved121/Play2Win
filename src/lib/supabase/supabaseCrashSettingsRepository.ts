import { validateCrashSettingsPatch } from "@/lib/crash/engine";
import { getSupabaseServerClient } from "@/lib/supabase/client";
import type { CrashSettingsRepository } from "@/lib/repositories/types";
import type { CrashSettings } from "@/lib/types";

const SETTINGS_ROW_ID = "default";

interface CrashSettingsRow {
  id: string;
  rtp: number;
  instant_crash_rate: number;
  min_bet: number;
  max_bet: number;
  updated_at: string;
}

function toDomain(row: CrashSettingsRow): CrashSettings {
  return {
    rtp: Number(row.rtp),
    instantCrashRate: Number(row.instant_crash_rate),
    minBet: Number(row.min_bet),
    maxBet: Number(row.max_bet),
    updatedAt: row.updated_at,
  };
}

export const supabaseCrashSettingsRepository: CrashSettingsRepository = {
  async get() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("crash_settings")
      .select("*")
      .eq("id", SETTINGS_ROW_ID)
      .single();
    if (error) throw new Error(`Supabase crashSettings.get failed: ${error.message}`);
    return toDomain(data as CrashSettingsRow);
  },

  async update(patch) {
    validateCrashSettingsPatch(patch);
    const supabase = getSupabaseServerClient();

    const { data: current, error: readError } = await supabase
      .from("crash_settings")
      .select("*")
      .eq("id", SETTINGS_ROW_ID)
      .single();
    if (readError) throw new Error(`Supabase crashSettings.update lookup failed: ${readError.message}`);
    const merged = { ...toDomain(current as CrashSettingsRow), ...patch };
    if (merged.minBet >= merged.maxBet) {
      throw new Error("minBet must be less than maxBet");
    }

    const { data, error } = await supabase
      .from("crash_settings")
      .update({
        rtp: merged.rtp,
        instant_crash_rate: merged.instantCrashRate,
        min_bet: merged.minBet,
        max_bet: merged.maxBet,
        updated_at: new Date().toISOString(),
      })
      .eq("id", SETTINGS_ROW_ID)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase crashSettings.update failed: ${error.message}`);
    return toDomain(data as CrashSettingsRow);
  },
};
