"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, OctagonAlert } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card, CardBody, CardHeader, CardTitle } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { StatTile } from "@/components/dashboard/StatTile";
import { transactionStatusVisual } from "@/lib/status";
import { formatCredits, formatDateTime } from "@/lib/utils";
import { BUST_PCT_RANGE, DIFFICULTIES, LANE_COUNTS, RTP_OPTIONS } from "@/lib/crossing/settingsOptions";
import type { CrossingDifficulty, CrossingLiveStatus, CrossingSettings, Paginated, Transaction } from "@/lib/types";

const LIVE_POLL_MS = 2000;

const DIFFICULTY_LABELS: Record<CrossingDifficulty, string> = {
  easy: "Easy",
  medium: "Medium",
  hard: "Hard",
  hardcore: "Hardcore",
};

export default function CrossingControlsPage() {
  const [tick, setTick] = useState(0);

  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), LIVE_POLL_MS);
    return () => clearInterval(id);
  }, []);

  const { data: live, isLoading: liveLoading } = useApi<CrossingLiveStatus>(`/api/games/crossing/live?_r=${tick}`);
  const { data: txData, isLoading: txLoading } = useApi<Paginated<Transaction>>(
    `/api/transactions?search=${encodeURIComponent("Multiplier Crossing")}&pageSize=10&_r=${tick}`,
  );

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <Link
            href="/dashboard/games"
            className="inline-flex items-center gap-1 text-xs text-ink-muted hover:text-ink"
          >
            <ArrowLeft className="size-3.5" /> Games
          </Link>
          <h1 className="mt-1 text-xl font-semibold text-ink">Multiplier Crossing — Live Controls</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Live round monitor, global game settings, and an emergency stop for the road-crossing game.
          </p>
        </div>
      </div>

      <LiveRoundMonitor live={live} isLoading={liveLoading} onStopped={() => setTick((t) => t + 1)} />
      <SettingsPanel />

      <Card className="overflow-hidden">
        <CardHeader>
          <CardTitle>Recent transactions</CardTitle>
          <Link href="/dashboard/transactions?search=Multiplier+Crossing" className="text-xs text-accent hover:underline">
            View all →
          </Link>
        </CardHeader>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-3 font-medium">Player</th>
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium">Amount</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Date</th>
              </tr>
            </thead>
            <tbody>
              {txLoading || !txData ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="border-b border-line">
                    <td className="px-4 py-3" colSpan={5}>
                      <Skeleton className="h-6" />
                    </td>
                  </tr>
                ))
              ) : txData.items.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-10 text-center text-ink-muted">
                    No Multiplier Crossing transactions yet.
                  </td>
                </tr>
              ) : (
                txData.items.map((tx) => {
                  const visual = transactionStatusVisual(tx.status);
                  return (
                    <tr key={tx.id} className="border-b border-line last:border-0 hover:bg-page/60">
                      <td className="px-4 py-3 text-ink">{tx.playerName}</td>
                      <td className="px-4 py-3 capitalize text-ink-secondary">{tx.type}</td>
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
      </Card>
    </div>
  );
}

function LiveRoundMonitor({
  live,
  isLoading,
  onStopped,
}: {
  live: CrossingLiveStatus | null;
  isLoading: boolean;
  onStopped: () => void;
}) {
  const [stopping, setStopping] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  async function handleEmergencyStop() {
    const activeBets = live?.activeBets ?? 0;
    if (
      !window.confirm(
        activeBets > 0
          ? `Void and fully refund all ${activeBets} currently active round(s) platform-wide? This can't be undone.`
          : "There are no active rounds right now — stop anyway?",
      )
    ) {
      return;
    }
    setStopping(true);
    setResult(null);
    try {
      const res = await fetch("/api/games/crossing/emergency-stop", { method: "POST" });
      const body = await res.json().catch(() => null);
      if (!res.ok) throw new Error(body?.error ?? "Request failed.");
      setResult(`Voided ${body.voidedCount} round(s), refunded ${formatCredits(body.refundedTotal)}.`);
      onStopped();
    } catch (err) {
      setResult(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setStopping(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Live round monitor</CardTitle>
        <Button variant="danger" size="sm" onClick={handleEmergencyStop} disabled={stopping}>
          <OctagonAlert className="size-4" /> Emergency stop — refund all
        </Button>
      </CardHeader>
      <CardBody className="flex flex-col gap-4">
        {result && <p className="text-sm text-ink-secondary">{result}</p>}

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-2">
          <StatTile label="Active bets" value={String(live?.activeBets ?? 0)} />
          <StatTile label="Total wagered (live)" value={formatCredits(live?.totalWagered ?? 0)} />
        </div>

        <div className="overflow-x-auto rounded-lg border border-line">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-page/60 text-left text-xs text-ink-muted">
                <th className="px-4 py-2.5 font-medium">Player</th>
                <th className="px-4 py-2.5 font-medium">Bet</th>
                <th className="px-4 py-2.5 font-medium">Difficulty</th>
                <th className="px-4 py-2.5 font-medium">Lane</th>
                <th className="px-4 py-2.5 font-medium">Started</th>
              </tr>
            </thead>
            <tbody>
              {isLoading && !live ? (
                Array.from({ length: 3 }).map((_, i) => (
                  <tr key={i} className="border-b border-line last:border-0">
                    <td className="px-4 py-2.5" colSpan={5}>
                      <Skeleton className="h-5" />
                    </td>
                  </tr>
                ))
              ) : !live || live.rounds.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-ink-muted">
                    No rounds in flight right now.
                  </td>
                </tr>
              ) : (
                live.rounds.map((r) => (
                  <tr key={r.roundId} className="border-b border-line last:border-0 hover:bg-page/60">
                    <td className="px-4 py-2.5 text-ink">{r.playerName}</td>
                    <td className="px-4 py-2.5 tabular text-ink-secondary">{formatCredits(r.betAmount)}</td>
                    <td className="px-4 py-2.5 capitalize text-ink-secondary">{DIFFICULTY_LABELS[r.difficulty]}</td>
                    <td className="px-4 py-2.5 tabular font-medium text-good">
                      {r.currentLane} / {r.laneCount}
                    </td>
                    <td className="px-4 py-2.5 text-ink-secondary">{formatDateTime(r.startedAt)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </CardBody>
    </Card>
  );
}

function SettingsPanel() {
  const { data, isLoading } = useApi<{ settings: CrossingSettings }>("/api/games/crossing/settings");

  return (
    <Card>
      <CardHeader>
        <CardTitle>Game settings</CardTitle>
      </CardHeader>
      <CardBody>
        {isLoading || !data ? <Skeleton className="h-24" /> : <SettingsForm initial={data.settings} />}
      </CardBody>
    </Card>
  );
}

// Only mounted once `initial` is loaded (see SettingsPanel), so useState can
// seed straight from it — same pattern as the crash settings form.
function SettingsForm({ initial }: { initial: CrossingSettings }) {
  const [rtp, setRtp] = useState(initial.rtp);
  const [minBet, setMinBet] = useState(String(initial.minBet));
  const [maxBet, setMaxBet] = useState(String(initial.maxBet));
  const [maxWin, setMaxWin] = useState(String(initial.maxWin));
  const [bustPct, setBustPct] = useState<Record<CrossingDifficulty, string>>({
    easy: String(initial.easyBustPct),
    medium: String(initial.mediumBustPct),
    hard: String(initial.hardBustPct),
    hardcore: String(initial.hardcoreBustPct),
  });
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState(initial.updatedAt);

  async function handleSave() {
    setError(null);
    const minBetValue = Number(minBet);
    const maxBetValue = Number(maxBet);
    const maxWinValue = Number(maxWin);
    if (!Number.isInteger(minBetValue) || !Number.isInteger(maxBetValue) || !Number.isInteger(maxWinValue)) {
      setError("Min/max bet and max win must be whole numbers.");
      return;
    }
    setIsSaving(true);
    try {
      const res = await fetch("/api/games/crossing/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          rtp,
          minBet: minBetValue,
          maxBet: maxBetValue,
          maxWin: maxWinValue,
          easyBustPct: Number(bustPct.easy),
          mediumBustPct: Number(bustPct.medium),
          hardBustPct: Number(bustPct.hard),
          hardcoreBustPct: Number(bustPct.hardcore),
        }),
      });
      const body = await res.json().catch(() => null);
      if (!res.ok) throw new Error(body?.error ?? "Request failed.");
      setSavedAt(body.settings.updatedAt);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <p className="text-xs text-ink-muted">
          Changes apply to rounds started after saving — a round already in flight keeps the settings it started
          with.
        </p>
        <span className="shrink-0 text-xs text-ink-muted">Last updated {formatDateTime(savedAt)}</span>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">RTP</span>
          <select
            value={rtp}
            onChange={(e) => setRtp(Number(e.target.value))}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          >
            {RTP_OPTIONS.map((v) => (
              <option key={v} value={v}>
                {v}%
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Min bet (10–50)</span>
          <input
            type="number"
            min={10}
            max={50}
            value={minBet}
            onChange={(e) => setMinBet(e.target.value)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Max bet (100–1000)</span>
          <input
            type="number"
            min={100}
            max={1000}
            value={maxBet}
            onChange={(e) => setMaxBet(e.target.value)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-ink-secondary">Max win</span>
          <input
            type="number"
            min={1000}
            max={1000000}
            value={maxWin}
            onChange={(e) => setMaxWin(e.target.value)}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          />
        </label>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {DIFFICULTIES.map((difficulty) => {
          const range = BUST_PCT_RANGE[difficulty];
          return (
            <label key={difficulty} className="flex flex-col gap-1 text-sm">
              <span className="text-ink-secondary">
                {DIFFICULTY_LABELS[difficulty]} bust% ({LANE_COUNTS[difficulty]} lanes, {range.min}–{range.max})
              </span>
              <input
                type="number"
                min={range.min}
                max={range.max}
                step="0.1"
                value={bustPct[difficulty]}
                onChange={(e) => setBustPct((prev) => ({ ...prev, [difficulty]: e.target.value }))}
                className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
              />
            </label>
          );
        })}
      </div>

      {error && <p className="text-sm text-critical">{error}</p>}
      <div>
        <Button onClick={handleSave} disabled={isSaving}>
          {isSaving ? "Saving…" : "Save settings"}
        </Button>
      </div>
    </div>
  );
}
