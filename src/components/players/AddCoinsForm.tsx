"use client";

import { useState, type FormEvent } from "react";
import { Button } from "@/components/ui/Button";

export function AddCoinsForm({
  onSubmit,
}: {
  onSubmit: (params: { amount: number; note?: string }) => Promise<void>;
}) {
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    const value = Number(amount);
    if (!Number.isFinite(value) || !Number.isInteger(value) || value === 0) {
      setError("Enter a non-zero whole number.");
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit({ amount: value, note: note.trim() || undefined });
      setAmount("");
      setNote("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-2">
      <div className="flex gap-2">
        <input
          type="number"
          step="1"
          placeholder="Amount (e.g. 500 or -100)"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="h-9 flex-1 rounded-lg border border-line bg-surface-raised px-3 text-sm text-ink outline-none focus:border-accent"
        />
        <Button type="submit" size="sm" disabled={isSubmitting}>
          Apply
        </Button>
      </div>
      <input
        type="text"
        placeholder="Reason (optional)"
        value={note}
        onChange={(e) => setNote(e.target.value)}
        className="h-9 rounded-lg border border-line bg-surface-raised px-3 text-sm text-ink outline-none focus:border-accent"
      />
      {error && <p className="text-xs text-critical">{error}</p>}
    </form>
  );
}
