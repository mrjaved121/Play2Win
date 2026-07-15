import { LayoutDashboard, Users, ArrowLeftRight, Gamepad2, BarChart3 } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
  { href: "/dashboard/players", label: "Players", icon: Users },
  { href: "/dashboard/transactions", label: "Transactions", icon: ArrowLeftRight },
  { href: "/dashboard/games", label: "Games", icon: Gamepad2 },
  { href: "/dashboard/analytics", label: "Analytics", icon: BarChart3 },
] as const;
