import type { GameStatus, PlayerStatus, TransactionStatus } from "@/lib/types";

export type StatusTone = "good" | "warning" | "serious" | "critical" | "neutral";

export interface StatusVisual {
  tone: StatusTone;
  label: string;
}

export function playerStatusVisual(status: PlayerStatus): StatusVisual {
  switch (status) {
    case "active":
      return { tone: "good", label: "Active" };
    case "suspended":
      return { tone: "warning", label: "Suspended" };
    case "banned":
      return { tone: "critical", label: "Banned" };
  }
}

export function transactionStatusVisual(status: TransactionStatus): StatusVisual {
  switch (status) {
    case "completed":
      return { tone: "good", label: "Completed" };
    case "pending":
      return { tone: "warning", label: "Pending" };
    case "failed":
      return { tone: "critical", label: "Failed" };
    case "reversed":
      return { tone: "serious", label: "Reversed" };
  }
}

export function gameStatusVisual(status: GameStatus): StatusVisual {
  switch (status) {
    case "active":
      return { tone: "good", label: "Active" };
    case "maintenance":
      return { tone: "warning", label: "Maintenance" };
    case "disabled":
      return { tone: "neutral", label: "Disabled" };
  }
}

export function newsStatusVisual(isActive: boolean): StatusVisual {
  return isActive ? { tone: "good", label: "Active" } : { tone: "neutral", label: "Inactive" };
}
