import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapAppContentRow } from "@/lib/supabase/mappers";
import type { AppContentRepository } from "@/lib/repositories/types";

export const supabaseAppContentRepository: AppContentRepository = {
  async getByKey(key) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.from("app_content").select("*").eq("key", key).maybeSingle();
    if (error) throw new Error(`Supabase appContent.getByKey failed: ${error.message}`);
    return data ? mapAppContentRow(data) : null;
  },

  async upsert(key, input) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("app_content")
      .upsert(
        {
          key,
          title: input.title,
          content: input.content,
          is_active: input.isActive,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "key" },
      )
      .select("*")
      .single();
    if (error) throw new Error(`Supabase appContent.upsert failed: ${error.message}`);
    return mapAppContentRow(data);
  },
};
