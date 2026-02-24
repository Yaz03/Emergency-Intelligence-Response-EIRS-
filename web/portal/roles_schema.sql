-- ============================================================
-- MediQR – User Roles Schema
-- This separates patient app users from paramedic/healthcare users
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. USER ROLES TABLE
create table if not exists public.user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade unique not null,
  role       text not null default 'patient',
  created_at timestamptz default now()
);

-- Constraint: role must be 'patient' or 'paramedic'
alter table public.user_roles
  add constraint valid_role check (role in ('patient', 'paramedic'));

alter table public.user_roles enable row level security;

-- Anyone can read roles (needed for login check)
create policy "Anyone can read roles"
  on public.user_roles for select
  using (true);

-- Only authenticated users can insert their own role
create policy "Users can insert own role"
  on public.user_roles for insert
  with check (auth.uid() = user_id);


-- 2. AUTO-ASSIGN 'patient' ROLE ON SIGNUP
-- This trigger automatically gives new users the 'patient' role
create or replace function public.handle_new_user_role()
returns trigger as $$
begin
  insert into public.user_roles (user_id, role)
  values (new.id, 'patient');
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if it exists, then create
drop trigger if exists on_auth_user_created_role on auth.users;
create trigger on_auth_user_created_role
  after insert on auth.users
  for each row execute procedure public.handle_new_user_role();


-- 3. TO MAKE A USER A PARAMEDIC, run:
-- update public.user_roles set role = 'paramedic' where user_id = '<USER_UUID>';
--
-- Or find the user first:
-- select u.id, u.email, r.role
-- from auth.users u
-- join public.user_roles r on r.user_id = u.id;
