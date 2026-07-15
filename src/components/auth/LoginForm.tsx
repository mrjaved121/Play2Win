"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Lock, Mail } from "lucide-react";
import { Button } from "@/components/ui/Button";

export function LoginForm({ redirectTo }: { redirectTo: string }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, rememberMe }),
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error ?? "Unable to sign in.");
        setIsSubmitting(false);
        return;
      }
      router.push(redirectTo);
      router.refresh();
    } catch {
      setError("Network error — is the dev server reachable?");
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex w-full flex-col gap-4">
      <div className="flex flex-col gap-1.5">
        <label htmlFor="email" className="text-sm font-medium text-ink-secondary">
          Email
        </label>
        <div className="relative">
          <Mail className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-ink-muted" />
          <input
            id="email"
            type="email"
            required
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@blackhole.dev"
            className="h-11 w-full rounded-lg border border-line bg-surface-raised pl-10 pr-3 text-sm text-ink placeholder:text-ink-muted outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
          />
        </div>
      </div>

      <div className="flex flex-col gap-1.5">
        <label htmlFor="password" className="text-sm font-medium text-ink-secondary">
          Password
        </label>
        <div className="relative">
          <Lock className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-ink-muted" />
          <input
            id="password"
            type="password"
            required
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••••"
            className="h-11 w-full rounded-lg border border-line bg-surface-raised pl-10 pr-3 text-sm text-ink placeholder:text-ink-muted outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
          />
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm text-ink-secondary select-none">
        <input
          type="checkbox"
          checked={rememberMe}
          onChange={(e) => setRememberMe(e.target.checked)}
          className="size-4 rounded border-line accent-[var(--bh-accent)]"
        />
        Remember me for 30 days
      </label>

      {error && (
        <div className="rounded-lg bg-critical/10 px-3 py-2 text-sm text-critical">
          {error}
        </div>
      )}

      <Button type="submit" disabled={isSubmitting} className="mt-1 w-full">
        {isSubmitting && <Loader2 className="size-4 animate-spin" />}
        Sign in
      </Button>
    </form>
  );
}
