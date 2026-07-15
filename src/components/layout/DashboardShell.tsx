"use client";

import { useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Menu, X, LogOut } from "lucide-react";
import { Sidebar } from "@/components/layout/Sidebar";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import type { AdminUser } from "@/lib/types";

export function DashboardShell({
  user,
  children,
}: {
  user: AdminUser;
  children: ReactNode;
}) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const router = useRouter();

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  return (
    <div className="flex min-h-screen">
      <aside className="hidden md:flex md:w-60 md:flex-col md:shrink-0 border-r border-line bg-surface">
        <div className="flex h-14 items-center gap-2 px-4 border-b border-line">
          <span className="inline-flex size-2 rounded-full bg-accent" aria-hidden />
          <span className="text-sm font-semibold text-ink">Blackhole Admin</span>
        </div>
        <Sidebar />
      </aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => setMobileOpen(false)}
            aria-hidden
          />
          <aside className="absolute left-0 top-0 h-full w-64 bg-surface border-r border-line">
            <div className="flex h-14 items-center justify-between px-4 border-b border-line">
              <span className="text-sm font-semibold text-ink">Blackhole Admin</span>
              <button
                onClick={() => setMobileOpen(false)}
                aria-label="Close navigation"
                className="text-ink-secondary hover:text-ink"
              >
                <X className="size-5" />
              </button>
            </div>
            <Sidebar onNavigate={() => setMobileOpen(false)} />
          </aside>
        </div>
      )}

      <div className="flex flex-1 flex-col min-w-0">
        <header className="flex h-14 items-center justify-between gap-3 border-b border-line bg-surface px-4">
          <button
            className="md:hidden text-ink-secondary hover:text-ink"
            onClick={() => setMobileOpen(true)}
            aria-label="Open navigation"
          >
            <Menu className="size-5" />
          </button>
          <div className="flex-1" />
          <ThemeToggle />
          <div className="flex items-center gap-3 pl-3 border-l border-line">
            <div className="text-right leading-tight hidden sm:block">
              <p className="text-sm font-medium text-ink">{user.name}</p>
              <p className="text-xs text-ink-muted capitalize">{user.role}</p>
            </div>
            <button
              onClick={handleLogout}
              aria-label="Sign out"
              className="inline-flex size-9 items-center justify-center rounded-lg text-ink-secondary hover:bg-page hover:text-critical transition-colors cursor-pointer"
            >
              <LogOut className="size-4.5" />
            </button>
          </div>
        </header>
        <main className="flex-1 p-4 md:p-6 w-full max-w-[1400px] mx-auto">{children}</main>
      </div>
    </div>
  );
}
