-- ============================================================
-- MediQR – Admin Users Table
-- Separate table for admin accounts
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. ADMIN USERS TABLE
CREATE TABLE IF NOT EXISTS public.admin_users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  name       TEXT NOT NULL DEFAULT '',
  email      TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Anyone can read (needed for login check from anon key)
CREATE POLICY "Anyone can read admin_users"
  ON public.admin_users FOR SELECT
  USING (true);

-- Only authenticated users can insert/update/delete
CREATE POLICY "Authenticated can manage admin_users"
  ON public.admin_users FOR ALL
  USING (auth.role() = 'authenticated');


-- 2. TO ADD AN ADMIN, run:
--
-- First find the user's UUID:
--   SELECT id, email FROM auth.users WHERE email = 'admin@example.com';
--
-- Then insert:
--   INSERT INTO public.admin_users (user_id, name, email)
--   VALUES ('<UUID>', 'Admin Name', 'admin@example.com');
