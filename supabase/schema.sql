-- Project Blackhole Admin Dashboard — Supabase schema
--
-- Run this in the Supabase SQL editor (Project -> SQL Editor -> New query)
-- before setting DATA_SOURCE=supabase in .env.local. It matches the column
-- names src/lib/supabase/mappers.ts expects.

create extension if not exists pgcrypto;

create table if not exists players (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  email text not null unique,
  status text not null default 'active' check (status in ('active', 'suspended', 'banned')),
  vip_tier text not null default 'bronze' check (vip_tier in ('bronze', 'silver', 'gold', 'platinum')),
  credit_balance numeric not null default 0,
  total_wagered numeric not null default 0,
  total_deposited numeric not null default 0,
  games_played integer not null default 0,
  country text not null default 'Unknown',
  joined_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);

create table if not exists games (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('slots', 'table', 'arcade', 'puzzle')),
  status text not null default 'active' check (status in ('active', 'disabled', 'maintenance')),
  rtp numeric not null check (rtp > 0 and rtp <= 100),
  total_sessions integer not null default 0,
  total_wagered numeric not null default 0,
  total_payout numeric not null default 0,
  release_date date not null default current_date,
  accent_seed integer not null default 0,
  -- Which built-in mobile-app screen this row plays as, if any. Null means
  -- a "coming soon" catalog entry with no real screen behind it yet. See
  -- src/app/api/public/games (the Lobby's catalog feed).
  app_entry_point text check (app_entry_point in ('slots', 'crash', 'wheel', 'scratch'))
);

create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  game_id uuid references games(id) on delete set null,
  type text not null check (type in ('deposit', 'withdrawal', 'wager', 'payout', 'bonus')),
  status text not null default 'completed' check (status in ('completed', 'pending', 'failed', 'reversed')),
  amount numeric not null,
  -- Freeform context for admin-initiated transactions (e.g. why a 'bonus'
  -- balance adjustment was made) — null for ordinary gameplay transactions.
  note text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_created_at_idx on transactions (created_at desc);
create index if not exists transactions_player_id_idx on transactions (player_id);

-- Powers the admin "Help & Support" page: short text entries shown in the
-- mobile app, ordered by display_order (ties broken by newest first).
create table if not exists news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists news_display_order_idx on news (display_order, created_at desc);

-- Generic keyed singleton text content — one row per named piece of
-- app-wide copy, editable from admin. Not currently used by any admin
-- page (see purchase_guides below for the "How to Buy" CMS, which needed
-- a list of entries rather than one singleton block) — kept as reusable
-- infrastructure for the next single-block content need. Not a payment
-- system either way — just admin-editable text the mobile app displays
-- as-is.
create table if not exists app_content (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  title text,
  content text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Powers the admin "How to Buy" CMS: multiple purchase-method/FAQ entries
-- shown in the mobile app, same shape/ordering as `news` above. Not a
-- payment system — just admin-editable text (src/app/dashboard/how-to-buy).
create table if not exists purchase_guides (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists purchase_guides_display_order_idx on purchase_guides (display_order, created_at desc);

-- Multiplier Climb (crash game): players get an extra guest_id so the
-- mobile app's public gameplay API (src/app/api/games/crash/*) can
-- find-or-create a player row without an admin-style signup, and rounds
-- get their own table. See src/lib/crash/engine.ts for the provably-fair
-- crash-point algorithm and src/lib/supabase/supabaseCrashRepository.ts
-- for how these are read/written.
alter table players add column if not exists guest_id text unique;

-- Once a player signs in via Supabase Auth (see blackhole_app's
-- features/auth), src/app/api/public/players/link links their verified
-- identity to this guest_id's player row so admin can find/credit a real,
-- portable account instead of an anonymous per-device guest. One canonical
-- player row per auth account; every gameplay call after that resolves by
-- this user_id (see src/lib/supabase/playerResolution.ts) rather than
-- guest_id, which is what makes balances portable across devices.
alter table players add column if not exists user_id uuid references auth.users(id) on delete set null;
create unique index if not exists players_user_id_idx on players (user_id) where user_id is not null;

-- The slot machine's server-side mirror (see supabaseSlotsRepository.ts).
-- Null (not 0) means this player has never synced a spin yet — the first
-- sync seeds it from the device's existing local balance instead of
-- resetting it, since the slot machine had local-only progress before
-- this column existed. Kept separate from credit_balance (Multiplier
-- Climb's economy) deliberately — the two games' coins aren't merged.
alter table players add column if not exists slot_balance numeric;

create table if not exists crash_rounds (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  bet_amount numeric not null,
  growth_rate numeric not null,
  crash_point numeric not null,
  -- The RTP/instant-crash-rate settings live when this round started (see
  -- src/lib/crash/engine.ts's computeCrashPoint) — stored per-round, not
  -- read from crash_settings at reveal time, so a later settings change
  -- can't retroactively change what a past round's provably-fair reveal is
  -- supposed to reproduce.
  rtp numeric not null default 95,
  instant_crash_rate numeric not null default 6,
  server_seed text not null,
  server_seed_hash text not null,
  status text not null default 'pending' check (status in ('pending', 'collected', 'crashed')),
  payout numeric,
  resolved_multiplier numeric,
  started_at timestamptz not null default now(),
  resolved_at timestamptz,
  -- True only for a round an admin ended via the emergency-stop "refund
  -- all" action (src/app/api/games/crash/emergency-stop) — status is still
  -- 'crashed' (never a win) but payout equals the full bet back rather
  -- than a genuine outcome. See CrashRepository.emergencyStopAll.
  voided boolean not null default false
);

create index if not exists crash_rounds_player_id_idx on crash_rounds (player_id);

-- Admin-adjustable, global (not per-player) Multiplier Climb parameters —
-- see src/lib/crash/engine.ts for the option sets/ranges these are
-- validated against and supabaseCrashSettingsRepository.ts for how this
-- singleton row is read/written. Changes only affect rounds started after
-- the change — see crash_rounds.rtp/instant_crash_rate above.
create table if not exists crash_settings (
  id text primary key default 'default',
  rtp numeric not null default 95,
  instant_crash_rate numeric not null default 6,
  min_bet numeric not null default 20,
  max_bet numeric not null default 500,
  updated_at timestamptz not null default now()
);

insert into crash_settings (id) values ('default') on conflict (id) do nothing;

-- Slot machine spin log (see supabaseSlotsRepository.ts). The actual RNG
-- outcome is decided client-side (unchanged game logic, see the mobile
-- app's SpinEngine) — this table is the audit trail + balance ledger, not
-- what decides a spin.
create table if not exists spin_history (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  bet integer not null,
  win_amount integer not null default 0,
  is_win boolean not null default false,
  jackpot_hit boolean not null default false,
  outcome text not null,
  symbols text[] not null,
  created_at timestamptz not null default now()
);

create index if not exists spin_history_player_id_idx on spin_history (player_id, created_at desc);

-- Shared round log for server-authoritative "single decision" games —
-- Lucky Wheel and Scratch Card (see src/lib/games/wheel.ts,
-- src/lib/games/scratch.ts, supabaseGameRoundRepository.ts). Unlike
-- crash_rounds, every row here resolves instantly in one request — there's
-- no pending/collect step — so there's no status column.
create table if not exists game_rounds (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  game_type text not null check (game_type in ('wheel', 'scratch')),
  bet_amount integer not null,
  win_amount integer not null default 0,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists game_rounds_player_id_idx on game_rounds (player_id, created_at desc);

-- Admins authenticate via Supabase Auth (auth.users). This table supplies
-- the display name + role the dashboard shows; supabaseAuthRepository looks
-- up a row here after auth.signInWithPassword succeeds, and treats a missing
-- row as "not provisioned as an admin" (sign-in denied).
create table if not exists admin_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null default 'admin' check (role in ('superadmin', 'admin', 'analyst'))
);

-- The app talks to Supabase with the service-role key (server-only route
-- handlers, never shipped to the browser), which bypasses RLS by design.
-- Enable RLS with no public policies so these tables stay inaccessible to
-- the anon/authenticated roles used by any future client-side access.
alter table players enable row level security;
alter table games enable row level security;
alter table transactions enable row level security;
alter table admin_profiles enable row level security;
alter table crash_rounds enable row level security;
alter table crash_settings enable row level security;
alter table news enable row level security;
alter table spin_history enable row level security;
alter table app_content enable row level security;
alter table game_rounds enable row level security;
alter table purchase_guides enable row level security;

-- After creating an admin user (Supabase Dashboard -> Authentication -> Add
-- user, or supabase.auth.admin.createUser), provision them as an admin:
--
--   insert into admin_profiles (user_id, name, role)
--   values ('<auth-user-uuid>', 'Jane Doe', 'admin');
