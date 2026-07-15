import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/requireAdmin";
import { getTransactionsRepository } from "@/lib/repositories";
import { resolveFromParam } from "@/lib/http/dateRange";
import type { TransactionStatus, TransactionType } from "@/lib/types";

export async function GET(request: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const { searchParams } = new URL(request.url);
  const search = searchParams.get("search") ?? undefined;
  const type = (searchParams.get("type") as TransactionType | null) ?? undefined;
  const status = (searchParams.get("status") as TransactionStatus | null) ?? undefined;
  const from = resolveFromParam(searchParams);
  const to = searchParams.get("to") ?? undefined;
  const page = Number(searchParams.get("page") ?? 1);
  const pageSize = Number(searchParams.get("pageSize") ?? 20);

  const result = await getTransactionsRepository().list({
    search,
    type,
    status,
    from,
    to,
    page,
    pageSize,
  });
  return NextResponse.json(result);
}
