"use client";

import { useState, type FormEvent } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import type { NewPurchaseGuideInput, PurchaseGuideEntry } from "@/lib/types";

interface PurchaseGuideFormModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (input: NewPurchaseGuideInput) => Promise<void>;
  initial?: PurchaseGuideEntry | null;
}

// The form fields live in this shell that only mounts while the modal is
// open, so useState can initialize straight from `initial` — remounting on
// every open/close is what resets the fields, no effect required.
export function PurchaseGuideFormModal({ open, onClose, onSubmit, initial }: PurchaseGuideFormModalProps) {
  return (
    <Modal open={open} onClose={onClose} title={initial ? "Edit entry" : "Add entry"}>
      {open && <PurchaseGuideForm initial={initial} onClose={onClose} onSubmit={onSubmit} />}
    </Modal>
  );
}

function PurchaseGuideForm({
  initial,
  onClose,
  onSubmit,
}: {
  initial?: PurchaseGuideEntry | null;
  onClose: () => void;
  onSubmit: (input: NewPurchaseGuideInput) => Promise<void>;
}) {
  const [title, setTitle] = useState(initial?.title ?? "");
  const [content, setContent] = useState(initial?.content ?? "");
  const [isActive, setIsActive] = useState(initial?.isActive ?? true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!title.trim()) {
      setError("Title is required.");
      return;
    }
    if (!content.trim()) {
      setError("Content is required.");
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit({ title: title.trim(), content: content.trim(), isActive });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      <label className="flex flex-col gap-1 text-sm">
        <span className="text-ink-secondary">Title</span>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Bank Transfer"
          className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
        />
      </label>

      <label className="flex flex-col gap-1 text-sm">
        <span className="text-ink-secondary">Content</span>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          rows={6}
          placeholder="Instructions shown to players for this purchase method..."
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

      <div className="mt-2 flex justify-end gap-2">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {initial ? "Save changes" : "Add entry"}
        </Button>
      </div>
    </form>
  );
}
