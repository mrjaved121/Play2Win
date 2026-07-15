import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapGameRow } from "@/lib/supabase/mappers";
import type { GamesRepository } from "@/lib/repositories/types";

export const supabaseGamesRepository: GamesRepository = {
  async list() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("games")
      .select("*")
      .order("release_date", { ascending: false });
    if (error) throw new Error(`Supabase games.list failed: ${error.message}`);
    return (data ?? []).map(mapGameRow);
  },

  async create(input) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("games")
      .insert({
        name: input.name,
        category: input.category,
        status: input.status,
        rtp: input.rtp,
        release_date: input.releaseDate,
        total_sessions: 0,
        total_wagered: 0,
        total_payout: 0,
        accent_seed: Math.floor(Math.random() * 12),
      })
      .select("*")
      .single();
    if (error) throw new Error(`Supabase games.create failed: ${error.message}`);
    return mapGameRow(data);
  },

  async update(id, patch) {
    const supabase = getSupabaseServerClient();
    const columnPatch: Record<string, unknown> = {};
    if (patch.name !== undefined) columnPatch.name = patch.name;
    if (patch.category !== undefined) columnPatch.category = patch.category;
    if (patch.status !== undefined) columnPatch.status = patch.status;
    if (patch.rtp !== undefined) columnPatch.rtp = patch.rtp;
    if (patch.releaseDate !== undefined) columnPatch.release_date = patch.releaseDate;

    const { data, error } = await supabase
      .from("games")
      .update(columnPatch)
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase games.update failed: ${error.message}`);
    return mapGameRow(data);
  },

  async remove(id) {
    const supabase = getSupabaseServerClient();
    const { error } = await supabase.from("games").delete().eq("id", id);
    if (error) throw new Error(`Supabase games.remove failed: ${error.message}`);
  },
};
