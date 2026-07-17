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

## Mobile Game API — Multiplier Climb (crash game)

Unlike the slot machine in the mobile app (which is entirely client-side),
**Multiplier Climb**'s game logic lives here. The mobile app is a thin API
client: it never picks a crash point or computes a payout itself, it just
renders whatever these endpoints return.

- `GET  /api/games/crash/balance?guestId=` — fetch (creating on first
  sight) a guest player's credit balance.
- `POST /api/games/crash/bet` — `{ guestId, betAmount }`. Deducts the bet,
  starts a round, and returns `{ round, balance }`. `round.crashPoint` and
  `round.serverSeed` are withheld while `status: "pending"` — that's the
  whole mechanic. The client renders the climbing multiplier itself from
  `round.startedAt` + `round.growthRate` (`multiplier = e^(growthRate *
  secondsElapsed)`, see `src/lib/crash/engine.ts`) without polling.
- `POST /api/games/crash/collect` — `{ guestId, roundId }`. Cashes out.
  If the round's hidden crash time already passed, it's settled as a loss
  instead (a slow request can't out-run the crash). On resolution, the
  response reveals `crashPoint` + `serverSeed` — provably fair: anyone can
  independently confirm `sha256(serverSeed) === serverSeedHash` (given at
  bet time) and that re-deriving the crash point from `(serverSeed,
  roundId)` reproduces `crashPoint`.
- `GET /api/games/crash/state?guestId=&roundId=` — reconciliation after
  the app backgrounds/reopens mid-round.

These routes are public (no admin session, permissive CORS) and identify
players by a client-generated `guestId` rather than a login — the
`CrashRepository` interface (`src/lib/repositories/types.ts`) auto-creates
a `players` row on first bet. Bets/payouts write real `wager`/`payout`
transactions against the *same* players/transactions tables the rest of
this dashboard reads, so a round played on the phone shows up immediately
in Players, Transactions and Analytics here — no separate data path to
keep in sync. `DATA_SOURCE=mock` keeps rounds/players in an in-memory Map
(resets on server restart, same tradeoff as the rest of the mock layer);
`DATA_SOURCE=supabase` persists to the `crash_rounds` table (added by
`supabase/schema.sql`) plus the existing `players`/`transactions` tables.

Point the mobile app at this server with `--dart-define=API_BASE_URL=...`
(see `blackhole_app`'s README) — e.g. `http://10.0.2.2:3000` to reach a
`next dev` server running on the host machine from the Android emulator.

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
