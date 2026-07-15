# Project Blackhole — Admin Dashboard

Admin console for the *Project Blackhole* research prototype (MPhil thesis).
Manage players, transactions, and the game catalog, and review platform
analytics. All monetary figures are a simulated in-platform currency
("credits") — there is no real-money processing anywhere in this app.

## Tech stack

- [Next.js 16](https://nextjs.org/) (App Router) + TypeScript
- Tailwind CSS v4
- [Supabase](https://supabase.com/) (Postgres + Auth) — optional, see below
- Recharts for charts

## Quick start

```bash
npm install
npm run dev
```

Open http://localhost:3000 — you'll be redirected to `/login`. The app runs
entirely offline out of the box against an in-memory mock dataset (340
players, 12 games, ~2,400 transactions), so no setup is required to explore
it.

**Demo login:**

```
admin@blackhole.dev / BlackHole#2026
```

Override these via `ADMIN_EMAIL` / `ADMIN_PASSWORD` in `.env.local` (copy
`.env.example` to get started).

## Project structure

```
src/
  app/
    login/               Login page
    dashboard/           Protected pages (Overview, Players, Transactions, Games, Analytics)
    api/                 Route handlers the dashboard pages call
  components/
    ui/                  Generic building blocks (Button, Card, Modal, Drawer, ...)
    charts/              Recharts wrappers (revenue, growth, popularity, retention)
    layout/               Sidebar + DashboardShell
    dashboard/ players/ games/ auth/   Feature-specific components
  lib/
    types.ts             Domain types shared by every layer
    repositories/        Repository interfaces + the mock/Supabase switch
    mock/                In-memory seeded dataset + mock repository impls
    supabase/            Supabase client + repository impls (real Postgres)
    analytics/compute.ts Pure aggregation math shared by both adapters
    auth/                Session cookie signing + verification, API-route guard
```

## How the data layer swaps (mock ⇄ Supabase)

Every page and API route talks to a `PlayersRepository` / `TransactionsRepository`
/ `GamesRepository` / `AnalyticsRepository` / `AuthRepository` interface
(`src/lib/repositories/types.ts`). `src/lib/repositories/index.ts` picks the
mock or Supabase implementation based on the `DATA_SOURCE` env var — nothing
in the UI or API routes changes when you switch.

- `DATA_SOURCE=mock` (default): reads/writes an in-memory dataset seeded from
  `src/lib/mock/seedData.ts`. Resets on server restart.
- `DATA_SOURCE=supabase`: reads/writes real Postgres tables via
  `@supabase/supabase-js`, using the schema below.

## Connecting Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Open the SQL editor and run [`supabase/schema.sql`](supabase/schema.sql).
   It creates `players`, `games`, `transactions`, and `admin_profiles`, with
   RLS enabled and no public policies (the app talks to Supabase with the
   service-role key from server-only route handlers, which bypasses RLS by
   design).
3. Create an admin user under **Authentication → Add user**, then provision
   them by inserting a row into `admin_profiles` (see the comment at the
   bottom of `schema.sql`).
4. Copy `.env.example` to `.env.local` and fill in:
   ```
   DATA_SOURCE=supabase
   SUPABASE_URL=https://<project>.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
   ```
5. Seed some data (the dashboard doesn't generate Supabase rows for you —
   insert a handful of `players`/`games`/`transactions` rows to get started,
   or write a small seed script against the same schema).
6. Restart the dev server.

## Environment variables

| Variable | Used by | Purpose |
|---|---|---|
| `DATA_SOURCE` | server | `mock` (default) or `supabase` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | mock auth | Demo admin credentials |
| `SESSION_SECRET` | auth | HMAC key signing the admin session cookie — set a long random value outside local dev |
| `SUPABASE_URL` | supabase adapters | Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | supabase adapters | Server-only key, bypasses RLS |
| `SUPABASE_ANON_KEY` | supabase adapters | Fallback if you'd rather not use the service role key |

## Known limitations

- **Retention cohorts are synthetic.** Computing real day-1/7/30 retention
  needs per-session event history, which this schema doesn't model. Both
  adapters return a fixed-seed synthetic cohort table
  (`computeRetentionCohorts` in `src/lib/analytics/compute.ts`) — swap it for
  a real query if you add a `sessions` table.
- **Supabase analytics queries are unbounded scans**, capped at 10,000 rows
  per table. Fine at prototype scale; back with materialized views or
  Postgres RPCs before this handles production traffic.
- **CSV export caps at 5,000 rows** per request (`/api/transactions/export`).
- The auth session is a small home-grown signed cookie (see
  `src/lib/auth/session.ts`), not Supabase's own SSR session — this keeps the
  mock and Supabase code paths identical. Swap in `@supabase/ssr` if you want
  Supabase to own sessions end-to-end.

## Scripts

```bash
npm run dev     # start the dev server
npm run build   # production build
npm run start   # run the production build
npm run lint    # eslint
```
