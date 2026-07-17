"use client";

import { useState, type FormEvent } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import type { Game, GameCategory, GameEntryPoint, GameStatus, NewGameInput } from "@/lib/types";

interface GameFormModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (input: NewGameInput) => Promise<void>;
  initial?: Game | null;
}

const CATEGORIES: GameCategory[] = ["slots", "table", "arcade", "puzzle"];
const STATUSES: GameStatus[] = ["active", "disabled", "maintenance"];
const ENTRY_POINTS: Array<{ value: GameEntryPoint | ""; label: string }> = [
  { value: "", label: "None (coming soon)" },
  { value: "slots", label: "Slot Machine" },
  { value: "crash", label: "Multiplier Climb" },
  { value: "wheel", label: "Lucky Wheel" },
  { value: "scratch", label: "Scratch Card" },
];

function toDateInputValue(iso: string): string {
  return iso.slice(0, 10);
}

// The form fields live in this shell that only mounts while the modal is
// open, so useState can initialize straight from `initial` — remounting on
// every open/close is what resets the fields, no effect required.
export function GameFormModal({ open, onClose, onSubmit, initial }: GameFormModalProps) {
  return (
    <Modal open={open} onClose={onClose} title={initial ? "Edit game" : "Add game"}>
      {open && <GameForm initial={initial} onClose={onClose} onSubmit={onSubmit} />}
    </Modal>
  );
}

function GameForm({
  initial,
  onClose,
  onSubmit,
}: {
  initial?: Game | null;
  onClose: () => void;
  onSubmit: (input: NewGameInput) => Promise<void>;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [category, setCategory] = useState<GameCategory>(initial?.category ?? "slots");
  const [status, setStatus] = useState<GameStatus>(initial?.status ?? "active");
  const [rtp, setRtp] = useState(initial ? String(initial.rtp) : "96.0");
  const [releaseDate, setReleaseDate] = useState(() =>
    initial ? toDateInputValue(initial.releaseDate) : new Date().toISOString().slice(0, 10),
  );
  const [appEntryPoint, setAppEntryPoint] = useState<GameEntryPoint | "">(initial?.appEntryPoint ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    const rtpValue = Number(rtp);
    if (!name.trim()) {
      setError("Name is required.");
      return;
    }
    if (!Number.isFinite(rtpValue) || rtpValue <= 0 || rtpValue > 100) {
      setError("RTP must be a number between 0 and 100.");
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit({ name: name.trim(), category, status, rtp: rtpValue, releaseDate, appEntryPoint });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      <label className="flex flex-col gap-1 text-sm">
        <span className="text-ink-secondary">Name</span>
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
        />
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Category</span>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value as GameCategory)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c[0].toUpperCase() + c.slice(1)}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Status</span>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as GameStatus)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          >
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s[0].toUpperCase() + s.slice(1)}
              </option>
            ))}
          </select>
        </label>
      </div>

      <label className="flex flex-col gap-1 text-sm">
        <span className="text-ink-secondary">Available in app as</span>
        <select
          value={appEntryPoint}
          onChange={(e) => setAppEntryPoint(e.target.value as GameEntryPoint | "")}
          className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
        >
          {ENTRY_POINTS.map((ep) => (
            <option key={ep.value} value={ep.value}>
              {ep.label}
            </option>
          ))}
        </select>
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">RTP (%)</span>
          <input
            type="number"
            step="0.1"
            min="0"
            max="100"
            value={rtp}
            onChange={(e) => setRtp(e.target.value)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Release date</span>
          <input
            type="date"
            value={releaseDate}
            onChange={(e) => setReleaseDate(e.target.value)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          />
        </label>
      </div>

      {error && <p className="text-sm text-critical">{error}</p>}

      <div className="mt-2 flex justify-end gap-2">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {initial ? "Save changes" : "Add game"}
        </Button>
      </div>
    </form>
  );
}
