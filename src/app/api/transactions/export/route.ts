import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getTransactionsRepository } from "@/lib/repositories";
import { resolveFromParam } from "@/lib/http/dateRange";
import { toCsv } from "@/lib/utils";
import type { TransactionStatus, TransactionType } from "@/lib/types";

const EXPORT_ROW_CAP = 5000;

export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const search = searchParams.get("search") ?? undefined;
  const type = (searchParams.get("type") as TransactionType | null) ?? undefined;
  const status = (searchParams.get("status") as TransactionStatus | null) ?? undefined;
  const from = resolveFromParam(searchParams);
  const to = searchParams.get("to") ?? undefined;

  const { items } = await getTransactionsRepository().list({
    search,
    type,
    status,
    from,
    to,
    page: 1,
    pageSize: EXPORT_ROW_CAP,
  });

  const csv = toCsv(
    items.map((t) => ({
      id: t.id,
      player: t.playerName,
      type: t.type,
      status: t.status,
      amount_credits: t.amount,
      game: t.gameName ?? "",
      created_at: t.createdAt,
    })),
  );

  return new NextResponse(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="transactions-export.csv"`,
    },
  });
}
