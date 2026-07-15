"use client";

import { useState } from "react";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { GameFormModal } from "@/components/games/GameFormModal";
import { gameStatusVisual } from "@/lib/status";
import { formatCompactNumber, formatCredits, formatDate } from "@/lib/utils";
import type { Game, NewGameInput } from "@/lib/types";

export default function GamesPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingGame, setEditingGame] = useState<Game | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const { data, isLoading } = useApi<{ games: Game[] }>(`/api/games?_r=${refreshKey}`);

  function refresh() {
    setRefreshKey((k) => k + 1);
  }

  async function handleCreateOrUpdate(input: NewGameInput) {
    const url = editingGame ? `/api/games/${editingGame.id}` : "/api/games";
    const method = editingGame ? "PATCH" : "POST";
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const body = await res.json().catch(() => null);
    if (!res.ok) throw new Error(body?.error ?? "Request failed.");
    setModalOpen(false);
    setEditingGame(null);
    refresh();
  }

  async function handleDelete(game: Game) {
    if (!window.confirm(`Remove "${game.name}" from the catalog? This can't be undone.`)) return;
    setDeletingId(game.id);
    try {
      const res = await fetch(`/api/games/${game.id}`, { method: "DELETE" });
      if (res.ok) refresh();
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-ink">Games</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Manage the game catalog, RTP configuration, and availability.
          </p>
        </div>
        <Button
          onClick={() => {
            setEditingGame(null);
            setModalOpen(true);
          }}
        >
          <Plus className="size-4" /> Add game
        </Button>
      </div>

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-3 font-medium">Game</th>
                <th className="px-4 py-3 font-medium">Category</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">RTP</th>
                <th className="px-4 py-3 font-medium">Sessions</th>
                <th className="px-4 py-3 font-medium">Net revenue</th>
                <th className="px-4 py-3 font-medium">Released</th>
                <th className="px-4 py-3 font-medium">Actions</th>
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
              ) : data.games.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-10 text-center text-ink-muted">
                    No games in the catalog yet.
                  </td>
                </tr>
              ) : (
                data.games.map((game) => {
                  const visual = gameStatusVisual(game.status);
                  const netRevenue = game.totalWagered - game.totalPayout;
                  return (
                    <tr key={game.id} className="border-b border-line last:border-0 hover:bg-page/60">
                      <td className="px-4 py-3 font-medium text-ink">{game.name}</td>
                      <td className="px-4 py-3 capitalize text-ink-secondary">{game.category}</td>
                      <td className="px-4 py-3">
                        <StatusBadge tone={visual.tone} label={visual.label} />
                      </td>
                      <td className="px-4 py-3 tabular text-ink-secondary">{game.rtp.toFixed(1)}%</td>
                      <td className="px-4 py-3 tabular text-ink-secondary">
                        {formatCompactNumber(game.totalSessions)}
                      </td>
                      <td className="px-4 py-3 tabular text-ink">{formatCredits(netRevenue)}</td>
                      <td className="px-4 py-3 text-ink-secondary">{formatDate(game.releaseDate)}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => {
                              setEditingGame(game);
                              setModalOpen(true);
                            }}
                            aria-label={`Edit ${game.name}`}
                            className="inline-flex size-8 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-ink cursor-pointer"
                          >
                            <Pencil className="size-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(game)}
                            disabled={deletingId === game.id}
                            aria-label={`Delete ${game.name}`}
                            className="inline-flex size-8 items-center justify-center rounded-lg text-ink-secondary hover:bg-critical/10 hover:text-critical cursor-pointer disabled:opacity-50"
                          >
                            <Trash2 className="size-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </Card>

      <GameFormModal
        open={modalOpen}
        initial={editingGame}
        onClose={() => {
          setModalOpen(false);
          setEditingGame(null);
        }}
        onSubmit={handleCreateOrUpdate}
      />
    </div>
  );
}
