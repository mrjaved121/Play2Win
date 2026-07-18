import {
  DEFAULT_INSTANT_CRASH_RATE,
  DEFAULT_MAX_BET,
  DEFAULT_MIN_BET,
  DEFAULT_RTP,
  validateCrashSettingsPatch,
} from "@/lib/crash/engine";
import { mockLatency } from "@/lib/mock/delay";
import type { CrashSettingsRepository } from "@/lib/repositories/types";
import type { CrashSettings } from "@/lib/types";

// Module-level singleton, same "resets on restart" tradeoff as the rest of
// the mock data layer (see mockCrashRepository.ts's `rounds` Map).
const settings: CrashSettings = {
  rtp: DEFAULT_RTP,
  instantCrashRate: DEFAULT_INSTANT_CRASH_RATE,
  minBet: DEFAULT_MIN_BET,
  maxBet: DEFAULT_MAX_BET,
  updatedAt: new Date().toISOString(),
};

export const mockCrashSettingsRepository: CrashSettingsRepository = {
  async get() {
    await mockLatency();
    return { ...settings };
  },

  async update(patch) {
    await mockLatency();
    validateCrashSettingsPatch(patch);
    const next: CrashSettings = { ...settings, ...patch, updatedAt: new Date().toISOString() };
    if (next.minBet >= next.maxBet) {
      throw new Error("minBet must be less than maxBet");
    }
    Object.assign(settings, next);
    return { ...settings };
  },
};
