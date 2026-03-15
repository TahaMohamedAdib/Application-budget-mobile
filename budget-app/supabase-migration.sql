-- SafeSpend Database Migration - Add missing columns and tables
-- Run this SQL in your Supabase SQL Editor AFTER the initial setup

-- ============================================
-- UPDATE profiles table with missing settings
-- ============================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS theme TEXT DEFAULT 'dark';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS template TEXT DEFAULT 'simple';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS subscription_active BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'FREE';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS net_worth_scope TEXT DEFAULT 'all';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS selected_account_id UUID;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS widgets JSONB DEFAULT '{"safeToSpend":true,"netWorth":true,"nextBill":true,"weeklySpending":false}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS goals TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_cash DECIMAL DEFAULT 0;

-- ============================================
-- UPDATE accounts table with missing columns
-- ============================================
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS bank_name TEXT;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS monthly_wage DECIMAL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS wage_day INTEGER;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS same_bank_transfer_fee DECIMAL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS diff_bank_transfer_fee DECIMAL DEFAULT 0;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS icon TEXT;

-- ============================================
-- UPDATE transactions table with missing columns
-- ============================================
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS merchant TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT false;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS recurring_rule_id UUID;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS fee_amount DECIMAL DEFAULT 0;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS is_fee BOOLEAN DEFAULT false;

-- ============================================
-- UPDATE recurring_rules with template fields
-- ============================================
ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS template_account_id UUID;
ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS template_to_account_id UUID;
ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS template_type TEXT DEFAULT 'expense';
ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS template_merchant TEXT;
ALTER TABLE recurring_rules ADD COLUMN IF NOT EXISTS template_is_recurring BOOLEAN DEFAULT true;

-- ============================================
-- CREATE budget_months table
-- ============================================
CREATE TABLE IF NOT EXISTS budget_months (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  month TEXT NOT NULL,
  category_id TEXT NOT NULL,
  planned_amount DECIMAL DEFAULT 0,
  spent_amount DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, month, category_id)
);

ALTER TABLE budget_months ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own budget_months" ON budget_months FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budget_months" ON budget_months FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budget_months" ON budget_months FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budget_months" ON budget_months FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- CREATE stock_holdings table (portfolio)
-- ============================================
CREATE TABLE IF NOT EXISTS stock_holdings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  ticker TEXT NOT NULL,
  company_name TEXT,
  quantity DECIMAL NOT NULL,
  buy_price DECIMAL NOT NULL,
  buy_date TIMESTAMPTZ,
  current_price DECIMAL NOT NULL,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  source TEXT DEFAULT 'trading.com',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE stock_holdings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own stock_holdings" ON stock_holdings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own stock_holdings" ON stock_holdings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own stock_holdings" ON stock_holdings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own stock_holdings" ON stock_holdings FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- CREATE portfolio_snapshots table
-- ============================================
CREATE TABLE IF NOT EXISTS portfolio_snapshots (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  date TEXT NOT NULL,
  total_value DECIMAL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

ALTER TABLE portfolio_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own portfolio_snapshots" ON portfolio_snapshots FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own portfolio_snapshots" ON portfolio_snapshots FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own portfolio_snapshots" ON portfolio_snapshots FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own portfolio_snapshots" ON portfolio_snapshots FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- CREATE user_categories table
-- ============================================
CREATE TABLE IF NOT EXISTS user_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  category_id TEXT NOT NULL,
  group_name TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT DEFAULT '#22c55e',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category_id)
);

ALTER TABLE user_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own user_categories" ON user_categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own user_categories" ON user_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own user_categories" ON user_categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own user_categories" ON user_categories FOR DELETE USING (auth.uid() = user_id);
