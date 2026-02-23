-- ============================================================
-- MediQR – Supabase Database Schema
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. PROFILES TABLE
-- Stores medical profile data for each user.
create table if not exists public.profiles (
  id           bigint generated always as identity primary key,
  user_id      uuid references auth.users(id) on delete cascade not null unique,
  full_name             text not null default '',
  date_of_birth         text not null default '',
  blood_group           text not null default '',
  allergies             text not null default '',
  medications           text not null default '',
  medical_conditions    text not null default '',
  emergency_contact_name   text not null default '',
  emergency_contact_phone  text not null default '',
  emergency_contact_relation text not null default '',
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Users can only read/write their own profile
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = user_id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = user_id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = user_id);


-- 2. EMERGENCY INCIDENTS TABLE
-- Stores emergency alert records with GPS data.
create table if not exists public.emergency_incidents (
  id           bigint generated always as identity primary key,
  user_id      uuid references auth.users(id) on delete cascade not null,
  latitude     double precision not null,
  longitude    double precision not null,
  timestamp    text not null,
  notes        text,
  status       text not null default 'triggered',
  created_at   timestamptz default now()
);

-- Enable Row Level Security
alter table public.emergency_incidents enable row level security;

-- Users can only read/write their own incidents
create policy "Users can view own incidents"
  on public.emergency_incidents for select
  using (auth.uid() = user_id);

create policy "Users can insert own incidents"
  on public.emergency_incidents for insert
  with check (auth.uid() = user_id);
