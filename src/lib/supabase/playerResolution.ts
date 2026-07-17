import type { SupabaseClient } from "@supabase/supabase-js";
import { STARTING_BALANCE } from "@/lib/crash/engine";

/**
 * Shared by every game's Supabase repository (crash, slots, ...) — one
 * `players` row per guest device / account, holding each game's own
 * balance column (`credit_balance` for Multiplier Climb, `slot_balance`
 * for the slot machine, ...) so admin sees one player with all their
 * activity rather than a disconnected row per game.
 */
export interface PlayerRow {
  id: string;
  credit_balance: number;
  slot_balance: number | null;
  total_wagered: number;
  games_played: number;
  display_name: string;
}

export async function findOrCreateGuestPlayer(supabase: SupabaseClient, guestId: string): Promise<PlayerRow> {
  const { data: existing, error: findError } = await supabase
    .from("players")
    .select("*")
    .eq("guest_id", guestId)
    .maybeSingle();
  if (findError) throw new Error(`Supabase resolvePlayer.guest lookup failed: ${findError.message}`);
  if (existing) return existing as PlayerRow;

  const { data: created, error: insertError } = await supabase
    .from("players")
    .insert({
      display_name: `Guest ${guestId.slice(0, 6)}`,
      email: `${guestId}@guest.blackhole.local`,
      guest_id: guestId,
      credit_balance: STARTING_BALANCE,
    })
    .select("*")
    .single();
  if (insertError) throw new Error(`Supabase resolvePlayer.guest create failed: ${insertError.message}`);
  return created as PlayerRow;
}

/**
 * Ensures a canonical player row exists for `userId`, adopting the given
 * device's guest row (and its balances) the first time this account links
 * — see CrashRepository.linkAccount's doc comment.
 */
export async function findOrCreateAccountPlayer(
  supabase: SupabaseClient,
  params: { userId: string; email: string; displayName?: string; guestId?: string },
): Promise<PlayerRow> {
  const { userId, email, displayName, guestId } = params;
  const { data: existing, error: findError } = await supabase
    .from("players")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle();
  if (findError) throw new Error(`Supabase resolvePlayer.account lookup failed: ${findError.message}`);
  if (existing) return existing as PlayerRow;

  if (guestId) {
    const { data: guestRow, error: guestError } = await supabase
      .from("players")
      .select("*")
      .eq("guest_id", guestId)
      .maybeSingle();
    if (guestError) {
      throw new Error(`Supabase resolvePlayer.account guest lookup failed: ${guestError.message}`);
    }
    if (guestRow) {
      const { data, error } = await supabase
        .from("players")
        .update({ user_id: userId, email, display_name: displayName ?? guestRow.display_name })
        .eq("id", guestRow.id)
        .select("*")
        .single();
      if (error) throw new Error(`Supabase resolvePlayer.account promote failed: ${error.message}`);
      return data as PlayerRow;
    }
  }

  const { data, error } = await supabase
    .from("players")
    .insert({
      display_name: displayName ?? email.split("@")[0],
      email,
      user_id: userId,
      credit_balance: STARTING_BALANCE,
    })
    .select("*")
    .single();
  if (error) throw new Error(`Supabase resolvePlayer.account create failed: ${error.message}`);
  return data as PlayerRow;
}

/**
 * Resolves which player row a request acts on. A valid `accessToken`
 * (verified here — never trusted from the client beyond the token itself)
 * always wins, which is what makes balance portable across devices once
 * signed in. Falls back to `guestId` when there's no token or it's
 * invalid/expired, so a stale session degrades to local guest play
 * instead of failing the request.
 */
export async function resolvePlayer(
  supabase: SupabaseClient,
  guestId: string,
  accessToken?: string,
): Promise<PlayerRow> {
  if (accessToken) {
    const { data, error } = await supabase.auth.getUser(accessToken);
    if (!error && data.user?.email) {
      return findOrCreateAccountPlayer(supabase, {
        userId: data.user.id,
        email: data.user.email,
        displayName: (data.user.user_metadata?.full_name as string | undefined) ?? undefined,
        guestId,
      });
    }
  }
  return findOrCreateGuestPlayer(supabase, guestId);
}
