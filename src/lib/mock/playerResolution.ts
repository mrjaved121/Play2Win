import { STARTING_BALANCE } from "@/lib/crash/engine";
import { seedPlayers } from "@/lib/mock/seedData";
import type { Player } from "@/lib/types";

let nextGuestSeq = 1;

/**
 * Shared by every game's mock repository (mirrors
 * src/lib/supabase/playerResolution.ts) so a guest device gets one
 * consistent player row — with the same STARTING_BALANCE credit_balance
 * default — regardless of which game it plays first.
 */
export function findOrCreateGuestPlayer(guestId: string): Player {
  const existing = seedPlayers.find((p) => p.guestId === guestId);
  if (existing) return existing;

  const now = new Date().toISOString();
  const player: Player = {
    id: `pl_g${(nextGuestSeq++).toString().padStart(5, "0")}`,
    guestId,
    displayName: `Guest ${guestId.slice(0, 6)}`,
    email: `${guestId}@guest.blackhole.local`,
    status: "active",
    vipTier: "bronze",
    creditBalance: STARTING_BALANCE,
    totalWagered: 0,
    totalDeposited: 0,
    gamesPlayed: 0,
    country: "Unknown",
    joinedAt: now,
    lastActiveAt: now,
  };
  seedPlayers.push(player);
  return player;
}
