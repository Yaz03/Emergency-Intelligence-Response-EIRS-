-- ============================================================
-- MediQR – Admin Role Migration
-- Adds 'admin' to the valid roles
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. Drop old constraint and add new one that includes 'admin'
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS valid_role;
ALTER TABLE public.user_roles
  ADD CONSTRAINT valid_role CHECK (role IN ('patient', 'paramedic', 'admin'));

-- 2. Allow authenticated users to update roles (for admin user management)
CREATE POLICY "Admins can update roles"
  ON public.user_roles FOR UPDATE
  USING (auth.role() = 'authenticated');

-- 3. Allow authenticated users to delete roles
CREATE POLICY "Admins can delete roles"
  ON public.user_roles FOR DELETE
  USING (auth.role() = 'authenticated');

-- 4. Allow authenticated users to insert roles (for promoting users)
-- Drop existing insert policy first, then create a more permissive one
DROP POLICY IF EXISTS "Users can insert own role" ON public.user_roles;
CREATE POLICY "Authenticated can insert roles"
  ON public.user_roles FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- 5. TO MAKE A USER AN ADMIN, run:
-- UPDATE public.user_roles SET role = 'admin' WHERE user_id = '<USER_UUID>';
