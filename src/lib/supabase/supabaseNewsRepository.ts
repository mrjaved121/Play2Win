import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapNewsRow } from "@/lib/supabase/mappers";
import type { NewsRepository } from "@/lib/repositories/types";

export const supabaseNewsRepository: NewsRepository = {
  async list() {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("news")
      .select("*")
      .order("display_order", { ascending: true })
      .order("created_at", { ascending: false });
    if (error) throw new Error(`Supabase news.list failed: ${error.message}`);
    return (data ?? []).map(mapNewsRow);
  },

  async create(input) {
    const supabase = getSupabaseServerClient();
    const { data: maxRow } = await supabase
      .from("news")
      .select("display_order")
      .order("display_order", { ascending: false })
      .limit(1)
      .maybeSingle();
    const nextOrder = (maxRow?.display_order ?? -1) + 1;

    const { data, error } = await supabase
      .from("news")
      .insert({
        title: input.title,
        content: input.content,
        is_active: input.isActive,
        display_order: nextOrder,
      })
      .select("*")
      .single();
    if (error) throw new Error(`Supabase news.create failed: ${error.message}`);
    return mapNewsRow(data);
  },

  async update(id, patch) {
    const supabase = getSupabaseServerClient();
    const columnPatch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (patch.title !== undefined) columnPatch.title = patch.title;
    if (patch.content !== undefined) columnPatch.content = patch.content;
    if (patch.isActive !== undefined) columnPatch.is_active = patch.isActive;
    if (patch.displayOrder !== undefined) columnPatch.display_order = patch.displayOrder;

    const { data, error } = await supabase
      .from("news")
      .update(columnPatch)
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase news.update failed: ${error.message}`);
    return mapNewsRow(data);
  },

  async remove(id) {
    const supabase = getSupabaseServerClient();
    const { error } = await supabase.from("news").delete().eq("id", id);
    if (error) throw new Error(`Supabase news.remove failed: ${error.message}`);
  },
};
