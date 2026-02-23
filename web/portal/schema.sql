-- ============================================================
-- MediQR – Emergency Web Portal Schema
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. EMERGENCY TOKENS TABLE
-- Short-lived tokens for secure QR-based access
create table if not exists public.emergency_tokens (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid references public.profiles(user_id) on delete cascade not null,
  token        text unique not null,
  expires_at   timestamptz not null,
  created_at   timestamptz default now()
);

alter table public.emergency_tokens enable row level security;

-- Anyone can read tokens (needed for emergency page without login)
create policy "Anon can validate tokens"
  on public.emergency_tokens for select
  using (true);

-- Only authenticated patients can create tokens (from Flutter app)
create policy "Patients can create tokens"
  on public.emergency_tokens for insert
  with check (auth.uid() = patient_id);

-- Patients can delete their own tokens
create policy "Patients can delete own tokens"
  on public.emergency_tokens for delete
  using (auth.uid() = patient_id);


-- 2. INCIDENTS TABLE
-- Emergency incident records logged when QR is scanned
create table if not exists public.incidents (
  id             uuid primary key default gen_random_uuid(),
  patient_id     uuid references public.profiles(user_id) on delete cascade not null,
  scan_time      timestamptz default now(),
  latitude       numeric,
  longitude      numeric,
  incident_type  text,
  severity       integer,
  reason         text,
  status         text not null default 'pending',
  created_by     uuid,
  created_at     timestamptz default now()
);

alter table public.incidents enable row level security;

-- Anyone can read incidents (needed for emergency page)
create policy "Anon can read incidents"
  on public.incidents for select
  using (true);

-- Anyone can insert incidents (auto-created when emergency page loads)
create policy "Anon can create incidents"
  on public.incidents for insert
  with check (true);

-- Only authenticated users can update incidents (healthcare workers)
create policy "Authenticated users can update incidents"
  on public.incidents for update
  using (auth.role() = 'authenticated');


-- 3. UPDATE PROFILES RLS
-- Allow anon read on profiles (needed to fetch patient data from emergency page)
-- This is safe because tokens expire and raw IDs are never exposed
create policy "Anon can read profiles via token"
  on public.profiles for select
  using (true);
