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
  accent_seed integer not null default 0
);

create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  game_id uuid references games(id) on delete set null,
  type text not null check (type in ('deposit', 'withdrawal', 'wager', 'payout', 'bonus')),
  status text not null default 'completed' check (status in ('completed', 'pending', 'failed', 'reversed')),
  amount numeric not null,
  created_at timestamptz not null default now()
);

create index if not exists transactions_created_at_idx on transactions (created_at desc);
create index if not exists transactions_player_id_idx on transactions (player_id);

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

-- After creating an admin user (Supabase Dashboard -> Authentication -> Add
-- user, or supabase.auth.admin.createUser), provision them as an admin:
--
--   insert into admin_profiles (user_id, name, role)
--   values ('<auth-user-uuid>', 'Jane Doe', 'admin');
