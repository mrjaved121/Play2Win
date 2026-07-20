"use client";

import { useState } from "react";
import { Plus, Pencil, Trash2, ChevronUp, ChevronDown } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { PurchaseGuideFormModal } from "@/components/purchase-guides/PurchaseGuideFormModal";
import { newsStatusVisual } from "@/lib/status";
import { formatDate } from "@/lib/utils";
import type { NewPurchaseGuideInput, PurchaseGuideEntry } from "@/lib/types";

export default function HowToBuyPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<PurchaseGuideEntry | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [reorderingId, setReorderingId] = useState<string | null>(null);

  const { data, isLoading } = useApi<{ guides: PurchaseGuideEntry[] }>(`/api/purchase-guides?_r=${refreshKey}`);

  function refresh() {
    setRefreshKey((k) => k + 1);
  }

  async function handleCreateOrUpdate(input: NewPurchaseGuideInput) {
    const url = editingItem ? `/api/purchase-guides/${editingItem.id}` : "/api/purchase-guides";
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

  async function handleDelete(item: PurchaseGuideEntry) {
    if (!window.confirm(`Remove "${item.title}"? This can't be undone.`)) return;
    setDeletingId(item.id);
    try {
      const res = await fetch(`/api/purchase-guides/${item.id}`, { method: "DELETE" });
      if (res.ok) refresh();
    } finally {
      setDeletingId(null);
    }
  }

  async function handleMove(item: PurchaseGuideEntry, direction: "up" | "down") {
    if (!data) return;
    const items = [...data.guides];
    const idx = items.findIndex((g) => g.id === item.id);
    const swapIdx = direction === "up" ? idx - 1 : idx + 1;
    if (idx < 0 || swapIdx < 0 || swapIdx >= items.length) return;

    [items[idx], items[swapIdx]] = [items[swapIdx], items[idx]];

    setReorderingId(item.id);
    try {
      const updates = items
        .map((g, i) => ({ item: g, order: i }))
        .filter(({ item: g, order }) => g.displayOrder !== order);
      await Promise.all(
        updates.map(({ item: g, order }) =>
          fetch(`/api/purchase-guides/${g.id}`, {
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
          <h1 className="text-xl font-semibold text-ink">How to Buy</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Manage the purchase-method and FAQ entries shown on the mobile app&apos;s How to Buy page. Plain text
            display only — not a payment system.
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
                Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i} className="border-b border-line">
                    <td className="px-4 py-3" colSpan={6}>
                      <Skeleton className="h-6" />
                    </td>
                  </tr>
                ))
              ) : data.guides.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-ink-muted">
                    No How to Buy entries yet.
                  </td>
                </tr>
              ) : (
                data.guides.map((item, i) => {
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
                            disabled={i === data.guides.length - 1 || isReordering}
                            aria-label={`Move "${item.title}" down`}
                            className="inline-flex size-7 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-ink cursor-pointer disabled:cursor-not-allowed disabled:opacity-30"
                          >
                            <ChevronDown className="size-4" />
                          </button>
                        </div>
                      </td>
                      <td className="px-4 py-3 max-w-[16rem] truncate font-medium text-ink">{item.title}</td>
                      <td className="px-4 py-3 max-w-md truncate text-ink-secondary">{item.content}</td>
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

      <PurchaseGuideFormModal
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
