import { getSupabaseServerClient } from "@/lib/supabase/client";
import { mapTransactionRow } from "@/lib/supabase/mappers";
import type {
  TransactionsListParams,
  TransactionsRepository,
} from "@/lib/repositories/types";

export const supabaseTransactionsRepository: TransactionsRepository = {
  async list({ search, type, status, from, to, page, pageSize }: TransactionsListParams) {
    const supabase = getSupabaseServerClient();
    const rangeFrom = (page - 1) * pageSize;
    const rangeTo = rangeFrom + pageSize - 1;

    let query = supabase
      .from("transactions")
      .select("*, players(display_name), games(name)", { count: "exact" })
      .order("created_at", { ascending: false })
      .range(rangeFrom, rangeTo);

    if (type) query = query.eq("type", type);
    if (status) query = query.eq("status", status);
    if (from) query = query.gte("created_at", from);
    if (to) query = query.lte("created_at", to);
    if (search && search.trim()) {
      const q = search.trim();
      query = query.or(`id.ilike.%${q}%`);
    }

    const { data, error, count } = await query;
    if (error) throw new Error(`Supabase transactions.list failed: ${error.message}`);
    return { items: (data ?? []).map(mapTransactionRow), total: count ?? 0 };
  },
};
