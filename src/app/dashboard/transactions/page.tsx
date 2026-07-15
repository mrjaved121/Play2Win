"use client";

import { useState } from "react";
import { Download } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { SearchInput } from "@/components/ui/SearchInput";
import { Pagination } from "@/components/ui/Pagination";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Button } from "@/components/ui/Button";
import { DateRangeChips } from "@/components/dashboard/DateRangeChips";
import { transactionStatusVisual } from "@/lib/status";
import { formatCredits, formatDateTime } from "@/lib/utils";
import type { Paginated, Transaction, TransactionStatus, TransactionType } from "@/lib/types";

const PAGE_SIZE = 15;

export default function TransactionsPage() {
  const [search, setSearch] = useState("");
  const [type, setType] = useState<TransactionType | "">("");
  const [status, setStatus] = useState<TransactionStatus | "">("");
  const [rangeDays, setRangeDays] = useState(0);
  const [page, setPage] = useState(1);

  const params = new URLSearchParams();
  if (search) params.set("search", search);
  if (type) params.set("type", type);
  if (status) params.set("status", status);
  if (rangeDays > 0) params.set("rangeDays", String(rangeDays));
  params.set("page", String(page));
  params.set("pageSize", String(PAGE_SIZE));

  const { data, isLoading } = useApi<Paginated<Transaction>>(`/api/transactions?${params.toString()}`);

  function handleExport() {
    const exportParams = new URLSearchParams(params);
    exportParams.delete("page");
    exportParams.delete("pageSize");
    window.location.href = `/api/transactions/export?${exportParams.toString()}`;
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-ink">Transactions</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Deposits, withdrawals, wagers, payouts, and bonuses across the platform.
          </p>
        </div>
        <Button variant="secondary" size="sm" onClick={handleExport}>
          <Download className="size-4" /> Export CSV
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <SearchInput
          placeholder="Search player, game, or transaction ID..."
          onDebouncedChange={(v) => {
            setSearch(v);
            setPage(1);
          }}
        />
        <select
          value={type}
          onChange={(e) => {
            setType(e.target.value as TransactionType | "");
            setPage(1);
          }}
          className="h-9 rounded-lg border border-line bg-surface-raised px-3 text-sm text-ink outline-none focus:border-accent"
        >
          <option value="">All types</option>
          <option value="deposit">Deposit</option>
          <option value="withdrawal">Withdrawal</option>
          <option value="wager">Wager</option>
          <option value="payout">Payout</option>
          <option value="bonus">Bonus</option>
        </select>
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value as TransactionStatus | "");
            setPage(1);
          }}
          className="h-9 rounded-lg border border-line bg-surface-raised px-3 text-sm text-ink outline-none focus:border-accent"
        >
          <option value="">All statuses</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="reversed">Reversed</option>
        </select>
        <DateRangeChips
          value={rangeDays}
          onChange={(v) => {
            setRangeDays(v);
            setPage(1);
          }}
        />
      </div>

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-3 font-medium">Transaction</th>
                <th className="px-4 py-3 font-medium">Player</th>
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium">Game</th>
                <th className="px-4 py-3 font-medium">Amount</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Date</th>
              </tr>
            </thead>
            <tbody>
              {isLoading || !data ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <tr key={i} className="border-b border-line">
                    <td className="px-4 py-3" colSpan={7}>
                      <Skeleton className="h-6" />
                    </td>
                  </tr>
                ))
              ) : data.items.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-10 text-center text-ink-muted">
                    No transactions match these filters.
                  </td>
                </tr>
              ) : (
                data.items.map((tx) => {
                  const visual = transactionStatusVisual(tx.status);
                  return (
                    <tr key={tx.id} className="border-b border-line last:border-0 hover:bg-page/60">
                      <td className="px-4 py-3 tabular text-ink-muted">{tx.id}</td>
                      <td className="px-4 py-3 text-ink">{tx.playerName}</td>
                      <td className="px-4 py-3 capitalize text-ink-secondary">{tx.type}</td>
                      <td className="px-4 py-3 text-ink-secondary">{tx.gameName ?? "—"}</td>
                      <td className="px-4 py-3 tabular text-ink">{formatCredits(tx.amount)}</td>
                      <td className="px-4 py-3">
                        <StatusBadge tone={visual.tone} label={visual.label} />
                      </td>
                      <td className="px-4 py-3 text-ink-secondary">{formatDateTime(tx.createdAt)}</td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
        <div className="px-4 pb-4">
          <Pagination page={page} pageSize={PAGE_SIZE} total={data?.total ?? 0} onPageChange={setPage} />
        </div>
      </Card>
    </div>
  );
}
