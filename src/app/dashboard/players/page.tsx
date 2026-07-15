"use client";

import { useState } from "react";
import { useApi } from "@/lib/hooks/useApi";
import { Card } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { SearchInput } from "@/components/ui/SearchInput";
import { Pagination } from "@/components/ui/Pagination";
import { Drawer } from "@/components/ui/Drawer";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { PlayerStatusSelect } from "@/components/players/PlayerStatusSelect";
import { playerStatusVisual } from "@/lib/status";
import { formatDate, formatFullCredits, formatCredits, formatRelativeTime } from "@/lib/utils";
import type { Paginated, Player, PlayerStatus } from "@/lib/types";

const PAGE_SIZE = 10;

export default function PlayersPage() {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<PlayerStatus | "">("");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);
  const [selected, setSelected] = useState<Player | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const params = new URLSearchParams();
  if (search) params.set("search", search);
  if (status) params.set("status", status);
  params.set("page", String(page));
  params.set("pageSize", String(PAGE_SIZE));
  params.set("_r", String(refreshKey));

  const { data, isLoading } = useApi<Paginated<Player>>(`/api/players?${params.toString()}`);

  async function handleStatusChange(playerId: string, newStatus: PlayerStatus) {
    setUpdatingId(playerId);
    try {
      const res = await fetch(`/api/players/${playerId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      if (res.ok) {
        setRefreshKey((k) => k + 1);
        setSelected((prev) => (prev && prev.id === playerId ? { ...prev, status: newStatus } : prev));
      }
    } finally {
      setUpdatingId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-ink">Players</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Search, review, and moderate player accounts.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <SearchInput
            placeholder="Search name, email, or ID..."
            onDebouncedChange={(v) => {
              setSearch(v);
              setPage(1);
            }}
          />
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as PlayerStatus | "");
              setPage(1);
            }}
            className="h-9 rounded-lg border border-line bg-surface-raised px-3 text-sm text-ink outline-none focus:border-accent"
          >
            <option value="">All statuses</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="banned">Banned</option>
          </select>
        </div>
      </div>

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-3 font-medium">Player</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">VIP tier</th>
                <th className="px-4 py-3 font-medium">Balance</th>
                <th className="px-4 py-3 font-medium">Total wagered</th>
                <th className="px-4 py-3 font-medium">Country</th>
                <th className="px-4 py-3 font-medium">Last active</th>
                <th className="px-4 py-3 font-medium">Action</th>
              </tr>
            </thead>
            <tbody>
              {isLoading || !data ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="border-b border-line">
                    <td className="px-4 py-3" colSpan={8}>
                      <Skeleton className="h-6" />
                    </td>
                  </tr>
                ))
              ) : data.items.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-10 text-center text-ink-muted">
                    No players match these filters.
                  </td>
                </tr>
              ) : (
                data.items.map((player) => {
                  const visual = playerStatusVisual(player.status);
                  return (
                    <tr
                      key={player.id}
                      className="border-b border-line last:border-0 hover:bg-page/60 cursor-pointer"
                      onClick={() => setSelected(player)}
                    >
                      <td className="px-4 py-3">
                        <p className="font-medium text-ink">{player.displayName}</p>
                        <p className="text-xs text-ink-muted">{player.email}</p>
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge tone={visual.tone} label={visual.label} />
                      </td>
                      <td className="px-4 py-3 capitalize text-ink-secondary">{player.vipTier}</td>
                      <td className="px-4 py-3 tabular text-ink">{formatFullCredits(player.creditBalance)}</td>
                      <td className="px-4 py-3 tabular text-ink-secondary">{formatCredits(player.totalWagered)}</td>
                      <td className="px-4 py-3 text-ink-secondary">{player.country}</td>
                      <td className="px-4 py-3 text-ink-secondary">{formatRelativeTime(player.lastActiveAt)}</td>
                      <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
                        <PlayerStatusSelect
                          value={player.status}
                          disabled={updatingId === player.id}
                          onChange={(newStatus) => handleStatusChange(player.id, newStatus)}
                        />
                      </td>
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

      <Drawer open={!!selected} onClose={() => setSelected(null)} title="Player details">
        {selected && (
          <div className="flex flex-col gap-5">
            <div>
              <p className="text-lg font-semibold text-ink">{selected.displayName}</p>
              <p className="text-sm text-ink-muted">{selected.email}</p>
              <p className="mt-1 text-xs text-ink-muted">{selected.id}</p>
            </div>

            <div className="flex items-center justify-between rounded-lg border border-line px-3 py-2">
              <span className="text-sm text-ink-secondary">Account status</span>
              <PlayerStatusSelect
                value={selected.status}
                disabled={updatingId === selected.id}
                onChange={(newStatus) => handleStatusChange(selected.id, newStatus)}
              />
            </div>

            <dl className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <dt className="text-ink-muted">VIP tier</dt>
                <dd className="mt-0.5 capitalize text-ink">{selected.vipTier}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Country</dt>
                <dd className="mt-0.5 text-ink">{selected.country}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Credit balance</dt>
                <dd className="mt-0.5 tabular text-ink">{formatFullCredits(selected.creditBalance)}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Total deposited</dt>
                <dd className="mt-0.5 tabular text-ink">{formatFullCredits(selected.totalDeposited)}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Total wagered</dt>
                <dd className="mt-0.5 tabular text-ink">{formatFullCredits(selected.totalWagered)}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Games played</dt>
                <dd className="mt-0.5 tabular text-ink">{selected.gamesPlayed.toLocaleString()}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Joined</dt>
                <dd className="mt-0.5 text-ink">{formatDate(selected.joinedAt)}</dd>
              </div>
              <div>
                <dt className="text-ink-muted">Last active</dt>
                <dd className="mt-0.5 text-ink">{formatRelativeTime(selected.lastActiveAt)}</dd>
              </div>
            </dl>
          </div>
        )}
      </Drawer>
    </div>
  );
}
