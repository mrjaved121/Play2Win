import {
  UserPlus,
  ArrowDownCircle,
  ArrowUpCircle,
  Trophy,
  Ban,
  Gamepad2,
  type LucideIcon,
} from "lucide-react";
import { formatRelativeTime, cn } from "@/lib/utils";
import type { ActivityEvent, ActivitySeverity } from "@/lib/types";

const TYPE_ICON: Record<ActivityEvent["type"], LucideIcon> = {
  signup: UserPlus,
  deposit: ArrowDownCircle,
  withdrawal: ArrowUpCircle,
  big_win: Trophy,
  suspension: Ban,
  game_added: Gamepad2,
};

const SEVERITY_CLASSES: Record<ActivitySeverity, string> = {
  good: "text-good bg-good/10",
  warning: "text-warning bg-warning/15",
  serious: "text-serious bg-serious/15",
  critical: "text-critical bg-critical/10",
};

export function ActivityFeed({ events }: { events: ActivityEvent[] }) {
  if (events.length === 0) {
    return <p className="py-6 text-center text-sm text-ink-muted">No recent activity.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {events.map((event) => {
        const Icon = TYPE_ICON[event.type];
        const severityClass = event.severity
          ? SEVERITY_CLASSES[event.severity]
          : "text-ink-muted bg-ink-muted/10";
        return (
          <li key={event.id} className="flex items-start gap-3">
            <span className={cn("mt-0.5 inline-flex size-7 shrink-0 items-center justify-center rounded-full", severityClass)}>
              <Icon className="size-3.5" aria-hidden />
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-sm text-ink">{event.message}</p>
              <p className="text-xs text-ink-muted">{formatRelativeTime(event.timestamp)}</p>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
