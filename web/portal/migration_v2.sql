-- ============================================================
-- MediQR – Profile Table Migration
-- Adds: medical_notes, 2nd emergency contact, avatar_index
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS medical_notes text DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contact_2_name text DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contact_2_phone text DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contact_2_relation text DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_index integer DEFAULT 0;
