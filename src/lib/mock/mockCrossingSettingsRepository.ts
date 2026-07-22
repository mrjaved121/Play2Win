import {
  DEFAULT_BUST_PCT,
  DEFAULT_MAX_BET,
  DEFAULT_MAX_WIN,
  DEFAULT_MIN_BET,
  DEFAULT_RTP,
  validateCrossingSettingsPatch,
} from "@/lib/crossing/engine";
import { mockLatency } from "@/lib/mock/delay";
import type { CrossingSettingsRepository } from "@/lib/repositories/types";
import type { CrossingSettings } from "@/lib/types";

// Module-level singleton, same "resets on restart" tradeoff as the rest of
// the mock data layer (see mockCrashSettingsRepository.ts).
const settings: CrossingSettings = {
  rtp: DEFAULT_RTP,
  minBet: DEFAULT_MIN_BET,
  maxBet: DEFAULT_MAX_BET,
  maxWin: DEFAULT_MAX_WIN,
  easyBustPct: DEFAULT_BUST_PCT.easy,
  mediumBustPct: DEFAULT_BUST_PCT.medium,
  hardBustPct: DEFAULT_BUST_PCT.hard,
  hardcoreBustPct: DEFAULT_BUST_PCT.hardcore,
  updatedAt: new Date().toISOString(),
};

export const mockCrossingSettingsRepository: CrossingSettingsRepository = {
  async get() {
    await mockLatency();
    return { ...settings };
  },

  async update(patch) {
    await mockLatency();
    validateCrossingSettingsPatch(patch, settings.rtp);
    const next: CrossingSettings = { ...settings, ...patch, updatedAt: new Date().toISOString() };
    if (next.minBet >= next.maxBet) {
      throw new Error("minBet must be less than maxBet");
    }
    Object.assign(settings, next);
    return { ...settings };
  },
};
