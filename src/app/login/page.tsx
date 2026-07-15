import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { SESSION_COOKIE, verifySessionToken } from "@/lib/auth/session";
import { LoginForm } from "@/components/auth/LoginForm";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ from?: string }>;
}) {
  const cookieStore = await cookies();
  const token = cookieStore.get(SESSION_COOKIE)?.value;
  const existingUser = await verifySessionToken(token);
  if (existingUser) redirect("/dashboard");

  const params = await searchParams;
  const redirectTo =
    params.from && params.from.startsWith("/dashboard") ? params.from : "/dashboard";

  return (
    <div className="flex min-h-screen flex-1">
      <div className="relative hidden flex-1 flex-col justify-between overflow-hidden bg-[#0d0d0d] px-12 py-10 text-white md:flex">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(circle at 30% 30%, rgba(57,135,229,0.35), transparent 45%)," +
              "radial-gradient(circle at 65% 70%, rgba(144,133,233,0.25), transparent 50%)," +
              "radial-gradient(circle at 50% 50%, #0d0d0d 0%, #050505 100%)",
          }}
        />
        <div className="relative z-10 flex items-center gap-2 text-sm font-semibold tracking-wide text-white/80">
          <span className="inline-flex size-2 rounded-full bg-[var(--bh-series-1)]" />
          PROJECT BLACKHOLE
        </div>
        <div className="relative z-10 max-w-md">
          <h1 className="text-3xl font-semibold leading-tight text-white">
            Admin console for the Blackhole research platform
          </h1>
          <p className="mt-3 text-sm leading-6 text-white/60">
            Monitor players, transactions, and game catalog activity across the
            prototype. All monetary figures are simulated research credits —
            no real-money processing is involved.
          </p>
        </div>
        <p className="relative z-10 text-xs text-white/40">
          MPhil thesis prototype &middot; internal use only
        </p>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center bg-page px-6 py-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex flex-col gap-1 md:hidden">
            <div className="flex items-center gap-2 text-sm font-semibold tracking-wide text-ink-secondary">
              <span className="inline-flex size-2 rounded-full bg-accent" />
              PROJECT BLACKHOLE
            </div>
          </div>

          <h2 className="text-xl font-semibold text-ink">Sign in to the admin console</h2>
          <p className="mt-1 text-sm text-ink-secondary">
            Use your administrator credentials to continue.
          </p>

          <div className="mt-6">
            <LoginForm redirectTo={redirectTo} />
          </div>

          <div className="mt-6 rounded-lg border border-line bg-surface-raised px-4 py-3 text-xs text-ink-secondary">
            <p className="font-medium text-ink">Demo access (mock data source)</p>
            <p className="mt-1 tabular">admin@blackhole.dev / BlackHole#2026</p>
            <p className="mt-1 text-ink-muted">
              Override via ADMIN_EMAIL / ADMIN_PASSWORD in .env.local, or set
              DATA_SOURCE=supabase to authenticate against Supabase instead.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
