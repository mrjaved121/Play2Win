"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, OctagonAlert } from "lucide-react";
import { useApi } from "@/lib/hooks/useApi";
import { Card, CardBody, CardHeader, CardTitle } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { Button } from "@/components/ui/Button";
import { StatTile } from "@/components/dashboard/StatTile";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { INSTANT_CRASH_RATE_OPTIONS, RTP_OPTIONS } from "@/lib/crash/settingsOptions";
import { transactionStatusVisual } from "@/lib/status";
import { formatCredits, formatDateTime } from "@/lib/utils";
import type { CrashLiveStatus, CrashSettings, Paginated, Transaction } from "@/lib/types";

const LIVE_POLL_MS = 2000;

/** Mirrors engine.ts's multiplierAtElapsed — duplicated here since that module pulls in Node's `crypto` and can't ship to the browser. */
function liveMultiplier(startedAt: string, growthRate: number, nowMs: number): number {
  const elapsedSeconds = (nowMs - new Date(startedAt).getTime()) / 1000;
  return Math.exp(growthRate * Math.max(0, elapsedSeconds));
}

export default function CrashControlsPage() {
  const [tick, setTick] = useState(0);
  const [nowMs, setNowMs] = useState(() => Date.now());

  useEffect(() => {
    const id = setInterval(() => {
      setNowMs(Date.now());
      setTick((t) => t + 1);
    }, LIVE_POLL_MS);
    return () => clearInterval(id);
  }, []);

  const { data: live, isLoading: liveLoading } = useApi<CrashLiveStatus>(`/api/games/crash/live?_r=${tick}`);
  const { data: txData, isLoading: txLoading } = useApi<Paginated<Transaction>>(
    `/api/transactions?search=${encodeURIComponent("Multiplier Climb")}&pageSize=10&_r=${tick}`,
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
          <h1 className="mt-1 text-xl font-semibold text-ink">Multiplier Climb — Live Controls</h1>
          <p className="mt-1 text-sm text-ink-secondary">
            Live round monitor, global game settings, and an emergency stop for the crash game.
          </p>
        </div>
      </div>

      <LiveRoundMonitor live={live} isLoading={liveLoading} nowMs={nowMs} onStopped={() => setTick((t) => t + 1)} />
      <SettingsPanel />

      <Card className="overflow-hidden">
        <CardHeader>
          <CardTitle>Recent transactions</CardTitle>
          <Link href="/dashboard/transactions?search=Multiplier+Climb" className="text-xs text-accent hover:underline">
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
                    No Multiplier Climb transactions yet.
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
  nowMs,
  onStopped,
}: {
  live: CrashLiveStatus | null;
  isLoading: boolean;
  nowMs: number;
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
      const res = await fetch("/api/games/crash/emergency-stop", { method: "POST" });
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
                <th className="px-4 py-2.5 font-medium">Multiplier</th>
                <th className="px-4 py-2.5 font-medium">Started</th>
              </tr>
            </thead>
            <tbody>
              {isLoading && !live ? (
                Array.from({ length: 3 }).map((_, i) => (
                  <tr key={i} className="border-b border-line last:border-0">
                    <td className="px-4 py-2.5" colSpan={4}>
                      <Skeleton className="h-5" />
                    </td>
                  </tr>
                ))
              ) : !live || live.rounds.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-ink-muted">
                    No rounds in flight right now.
                  </td>
                </tr>
              ) : (
                live.rounds.map((r) => (
                  <tr key={r.roundId} className="border-b border-line last:border-0 hover:bg-page/60">
                    <td className="px-4 py-2.5 text-ink">{r.playerName}</td>
                    <td className="px-4 py-2.5 tabular text-ink-secondary">{formatCredits(r.betAmount)}</td>
                    <td className="px-4 py-2.5 tabular font-medium text-good">
                      {liveMultiplier(r.startedAt, r.growthRate, nowMs).toFixed(2)}x
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
  const { data, isLoading } = useApi<{ settings: CrashSettings }>("/api/games/crash/settings");

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
// seed straight from it — no effect-based sync needed, same pattern as
// GameFormModal.
function SettingsForm({ initial }: { initial: CrashSettings }) {
  const [rtp, setRtp] = useState(initial.rtp);
  const [instantCrashRate, setInstantCrashRate] = useState(initial.instantCrashRate);
  const [minBet, setMinBet] = useState(String(initial.minBet));
  const [maxBet, setMaxBet] = useState(String(initial.maxBet));
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState(initial.updatedAt);

  async function handleSave() {
    setError(null);
    const minBetValue = Number(minBet);
    const maxBetValue = Number(maxBet);
    if (!Number.isInteger(minBetValue) || !Number.isInteger(maxBetValue)) {
      setError("Min/max bet must be whole numbers.");
      return;
    }
    setIsSaving(true);
    try {
      const res = await fetch("/api/games/crash/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rtp, instantCrashRate, minBet: minBetValue, maxBet: maxBetValue }),
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
          <span className="text-ink-secondary">Instant crash rate</span>
          <select
            value={instantCrashRate}
            onChange={(e) => setInstantCrashRate(Number(e.target.value))}
            className="h-10 rounded-lg border border-line bg-surface-raised px-3 text-ink outline-none focus:border-accent"
          >
            {INSTANT_CRASH_RATE_OPTIONS.map((v) => (
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
