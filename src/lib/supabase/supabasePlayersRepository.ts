import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapPlayerRow } from "@/lib/supabase/mappers";
import type { PlayersListParams, PlayersRepository } from "@/lib/repositories/types";

export const supabasePlayersRepository: PlayersRepository = {
  async list({ search, status, page, pageSize }: PlayersListParams) {
    const supabase = getSupabaseServerClient();
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = supabase
      .from("players")
      .select("*", { count: "exact" })
      .order("last_active_at", { ascending: false })
      .range(from, to);

    if (status) query = query.eq("status", status);
    if (search && search.trim()) {
      const q = search.trim();
      query = query.or(
        `display_name.ilike.%${q}%,email.ilike.%${q}%,id.ilike.%${q}%`,
      );
    }

    const { data, error, count } = await query;
    if (error) throw new Error(`Supabase players.list failed: ${error.message}`);
    return { items: (data ?? []).map(mapPlayerRow), total: count ?? 0 };
  },

  async getById(id: string) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase.from("players").select("*").eq("id", id).maybeSingle();
    if (error) throw new Error(`Supabase players.getById failed: ${error.message}`);
    return data ? mapPlayerRow(data) : null;
  },

  async updateStatus(id: string, status) {
    const supabase = getSupabaseServerClient();
    const { data, error } = await supabase
      .from("players")
      .update({ status })
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase players.updateStatus failed: ${error.message}`);
    return mapPlayerRow(data);
  },

  async adjustBalance(id: string, { amount, note }) {
    const supabase = getSupabaseServerClient();
    const { data: existing, error: findError } = await supabase
      .from("players")
      .select("credit_balance")
      .eq("id", id)
      .maybeSingle();
    if (findError) throw new Error(`Supabase players.adjustBalance lookup failed: ${findError.message}`);
    if (!existing) throw new Error(`Player ${id} not found`);

    const newBalance = Math.max(0, Number(existing.credit_balance) + amount);
    const { data, error } = await supabase
      .from("players")
      .update({ credit_balance: newBalance })
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new Error(`Supabase players.adjustBalance failed: ${error.message}`);

    const { error: txnError } = await supabase
      .from("transactions")
      .insert({ player_id: id, type: "bonus", status: "completed", amount, note: note ?? null });
    if (txnError) throw new Error(`Supabase players.adjustBalance transaction insert failed: ${txnError.message}`);

    return mapPlayerRow(data);
  },
};
