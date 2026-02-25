-- ============================================================
-- MediQR – Admin Dashboard v2 Migration
-- Adds city and completed_time columns
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Add city column to incidents (for faster city-based queries)
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS city TEXT;

-- Add completed_time to incidents (for response time calculation)
ALTER TABLE public.incidents ADD COLUMN IF NOT EXISTS completed_time TIMESTAMPTZ;

-- Add city column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS city TEXT DEFAULT '';
