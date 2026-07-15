import { CheckCircle2, AlertTriangle, AlertOctagon, XCircle, Circle } from "lucide-react";
import type { StatusTone } from "@/lib/status";
import { cn } from "@/lib/utils";

const TONE_CLASSES: Record<StatusTone, string> = {
  good: "text-good bg-good/10",
  warning: "text-warning bg-warning/15",
  serious: "text-serious bg-serious/15",
  critical: "text-critical bg-critical/10",
  neutral: "text-ink-muted bg-ink-muted/10",
};

const TONE_ICONS: Record<StatusTone, typeof CheckCircle2> = {
  good: CheckCircle2,
  warning: AlertTriangle,
  serious: AlertOctagon,
  critical: XCircle,
  neutral: Circle,
};

export function StatusBadge({ tone, label }: { tone: StatusTone; label: string }) {
  const Icon = TONE_ICONS[tone];
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium",
        TONE_CLASSES[tone],
      )}
    >
      <Icon className="size-3.5" aria-hidden />
      {label}
    </span>
  );
}
