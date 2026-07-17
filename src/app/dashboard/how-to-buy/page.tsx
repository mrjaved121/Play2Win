"use client";

import { useEffect, useState } from "react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { formatDateTime } from "@/lib/utils";
import type { AppContent } from "@/lib/types";

const CONTENT_KEY = "purchase_instructions";

export default function HowToBuyPage() {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [updatedAt, setUpdatedAt] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    let cancelled = false;
    fetch(`/api/app-content/${CONTENT_KEY}`)
      .then((res) => res.json())
      .then((body) => {
        if (cancelled) return;
        const existing: AppContent | null = body?.content ?? null;
        if (existing) {
          setTitle(existing.title);
          setContent(existing.content);
          setIsActive(existing.isActive);
          setUpdatedAt(existing.updatedAt);
        } else {
          setTitle("How to Buy Credits");
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  async function handleSave() {
    setIsSaving(true);
    setError(null);
    setSaved(false);
    try {
      const res = await fetch(`/api/app-content/${CONTENT_KEY}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, content, isActive }),
      });
      const body = await res.json().catch(() => null);
      if (!res.ok) throw new Error(body?.error ?? "Failed to save.");
      setUpdatedAt(body.content.updatedAt);
      setSaved(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <div className="flex max-w-2xl flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-ink">How to Buy Credits</h1>
        <p className="mt-1 text-sm text-ink-secondary">
          Instructions shown to players in the mobile app. Plain text display only — not a payment system.
        </p>
      </div>

      <Card className="p-5">
        {isLoading ? (
          <p className="text-sm text-ink-muted">Loading...</p>
        ) : (
          <div className="flex flex-col gap-3">
            <label className="flex flex-col gap-1 text-sm">
              <span className="text-ink-secondary">Title</span>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
              />
            </label>

            <label className="flex flex-col gap-1 text-sm">
              <span className="text-ink-secondary">Content</span>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                rows={10}
                placeholder="e.g. Contact us at support@example.com or +1 555-0100 to arrange a top-up."
                className="resize-none rounded-lg border border-line bg-surface-raised px-3 py-2 text-ink outline-none focus:border-accent"
              />
            </label>

            <label className="flex items-center gap-2 text-sm text-ink-secondary">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="size-4 rounded border-line accent-accent"
              />
              Active (visible in the mobile app)
            </label>

            {error && <p className="text-sm text-critical">{error}</p>}
            {saved && !error && <p className="text-sm text-good">Saved.</p>}
            {updatedAt && <p className="text-xs text-ink-muted">Last updated {formatDateTime(updatedAt)}</p>}

            <div className="mt-2 flex justify-end">
              <Button onClick={handleSave} disabled={isSaving}>
                {isSaving ? "Saving..." : "Save"}
              </Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
