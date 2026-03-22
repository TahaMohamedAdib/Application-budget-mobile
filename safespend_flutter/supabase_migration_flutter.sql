-- SafeSpend Flutter Migration
-- Run this SQL in your Supabase SQL Editor to add columns required by the Flutter app
-- This is safe to run multiple times (uses IF NOT EXISTS)

-- ============================================
-- accounts: add include_in_net_worth flag
-- ============================================
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS include_in_net_worth BOOLEAN DEFAULT true;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS image_path TEXT;

-- ============================================
-- user_categories: add budget_limit for spending caps
-- ============================================
ALTER TABLE user_categories ADD COLUMN IF NOT EXISTS budget_limit DECIMAL DEFAULT 0;

-- ============================================
-- goals: add category_id for linking goals to categories
-- ============================================
ALTER TABLE goals ADD COLUMN IF NOT EXISTS category_id TEXT;

-- ============================================
-- transactions: add image_path for receipt photos
-- ============================================
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS image_path TEXT;

-- ============================================
-- stock_holdings: ensure buy_date column exists
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stock_holdings' AND column_name = 'buy_date'
  ) THEN
    ALTER TABLE stock_holdings ADD COLUMN buy_date TIMESTAMPTZ;
  END IF;
END $$;

-- Add title to stock_holdings (for custom holding names)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'stock_holdings' AND column_name = 'title'
  ) THEN
    ALTER TABLE stock_holdings ADD COLUMN title TEXT;
  END IF;
END $$;

-- ============================================
-- accounts: salary auto-credit columns
-- ============================================
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS salary_amount NUMERIC;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS salary_day INTEGER;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS last_salary_date TEXT;

-- ============================================
-- transactions: expense sub-type (subscription / bill)
-- ============================================
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS expense_sub_type TEXT;
