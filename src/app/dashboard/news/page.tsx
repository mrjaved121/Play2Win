"use client";

import { useState } from "react";
import { Plus, Pencil, Trash2, ChevronUp, ChevronDown } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { NewsFormModal } from "@/components/news/NewsFormModal";
import { newsStatusVisual } from "@/lib/status";
import { formatDate } from "@/lib/utils";
import type { NewNewsInput, NewsItem } from "@/lib/types";

export default function NewsPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<NewsItem | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [reorderingId, setReorderingId] = useState<string | null>(null);

  const { data, isLoading } = useApi<{ news: NewsItem[] }>(`/api/news?_r=${refreshKey}`);

  function refresh() {
    setRefreshKey((k) => k + 1);
  }

  async function handleCreateOrUpdate(input: NewNewsInput) {
    const url = editingItem ? `/api/news/${editingItem.id}` : "/api/news";
    const method = editingItem ? "PATCH" : "POST";
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    const body = await res.json().catch(() => null);
    if (!res.ok) throw new Error(body?.error ?? "Request failed.");
    setModalOpen(false);
    setEditingItem(null);
    refresh();
  }

  async function handleDelete(item: NewsItem) {
    if (!window.confirm(`Remove "${item.title}"? This can't be undone.`)) return;
    setDeletingId(item.id);
    try {
      const res = await fetch(`/api/news/${item.id}`, { method: "DELETE" });
      if (res.ok) refresh();
    } finally {
      setDeletingId(null);
    }
  }

  async function handleMove(item: NewsItem, direction: "up" | "down") {
    if (!data) return;
    const items = [...data.news];
    const idx = items.findIndex((n) => n.id === item.id);
    const swapIdx = direction === "up" ? idx - 1 : idx + 1;
    if (idx < 0 || swapIdx < 0 || swapIdx >= items.length) return;

    [items[idx], items[swapIdx]] = [items[swapIdx], items[idx]];

    setReorderingId(item.id);
    try {
      const updates = items
        .map((n, i) => ({ item: n, order: i }))
        .filter(({ item: n, order }) => n.displayOrder !== order);
      await Promise.all(
        updates.map(({ item: n, order }) =>
          fetch(`/api/news/${n.id}`, {
            method: "PATCH",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ displayOrder: order }),
          }),
        ),
      );
      refresh();
    } finally {
      setReorderingId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-ink">Help & Support</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Manage the help & support entries shown in the mobile app.
          </p>
        </div>
        <Button
          onClick={() => {
            setEditingItem(null);
            setModalOpen(true);
          }}
        >
          <Plus className="size-4" /> Add entry
        </Button>
      </div>

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-3 font-medium">Order</th>
                <th className="px-4 py-3 font-medium">Title</th>
                <th className="px-4 py-3 font-medium">Content</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Updated</th>
                <th className="px-4 py-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading || !data ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="border-b border-line">
                    <td className="px-4 py-3" colSpan={6}>
                      <Skeleton className="h-6" />
                    </td>
                  </tr>
                ))
              ) : data.news.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-ink-muted">
                    No help & support entries yet.
                  </td>
                </tr>
              ) : (
                data.news.map((item, i) => {
                  const visual = newsStatusVisual(item.isActive);
                  const isReordering = reorderingId !== null;
                  return (
                    <tr key={item.id} className="border-b border-line last:border-0 hover:bg-page/60">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-0.5">
                          <button
                            onClick={() => handleMove(item, "up")}
                            disabled={i === 0 || isReordering}
                            aria-label={`Move "${item.title}" up`}
                            className="inline-flex size-7 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-ink cursor-pointer disabled:cursor-not-allowed disabled:opacity-30"
                          >
                            <ChevronUp className="size-4" />
                          </button>
                          <button
                            onClick={() => handleMove(item, "down")}
                            disabled={i === data.news.length - 1 || isReordering}
                            aria-label={`Move "${item.title}" down`}
                            className="inline-flex size-7 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-ink cursor-pointer disabled:cursor-not-allowed disabled:opacity-30"
                          >
                            <ChevronDown className="size-4" />
                          </button>
                        </div>
                      </td>
                      <td className="px-4 py-3 max-w-[16rem] truncate font-medium text-ink">
                        {item.title}
                      </td>
                      <td className="px-4 py-3 max-w-md truncate text-ink-secondary">
                        {item.content}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge tone={visual.tone} label={visual.label} />
                      </td>
                      <td className="px-4 py-3 text-ink-secondary">{formatDate(item.updatedAt)}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => {
                              setEditingItem(item);
                              setModalOpen(true);
                            }}
                            aria-label={`Edit ${item.title}`}
                            className="inline-flex size-8 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-ink cursor-pointer"
                          >
                            <Pencil className="size-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(item)}
                            disabled={deletingId === item.id}
                            aria-label={`Delete ${item.title}`}
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

      <NewsFormModal
        open={modalOpen}
        initial={editingItem}
        onClose={() => {
          setModalOpen(false);
          setEditingItem(null);
        }}
        onSubmit={handleCreateOrUpdate}
      />
    </div>
  );
}
