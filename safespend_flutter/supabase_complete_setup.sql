-- ============================================================
-- SafeSpend Flutter — Complete Supabase Setup
-- Paste this entire script in: Supabase → SQL Editor → Run
-- Safe to run multiple times (uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS)
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  currency TEXT DEFAULT 'USD',
  pay_frequency TEXT DEFAULT 'monthly',
  monthly_income DECIMAL DEFAULT 0,
  onboarding_complete BOOLEAN DEFAULT false,
  theme TEXT DEFAULT 'dark',
  template TEXT DEFAULT 'simple',
  subscription_active BOOLEAN DEFAULT false,
  subscription_tier TEXT DEFAULT 'FREE',
  net_worth_scope TEXT DEFAULT 'all',
  selected_account_id UUID,
  widgets JSONB DEFAULT '{"safeToSpend":true,"netWorth":true,"nextBill":true,"weeklySpending":false}',
  goals TEXT[] DEFAULT '{}',
  total_cash DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Users can view own profile') THEN
    CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Users can update own profile') THEN
    CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Users can insert own profile') THEN
    CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- ============================================================
-- 2. ACCOUNTS
-- ============================================================
CREATE TABLE IF NOT EXISTS accounts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  balance DECIMAL DEFAULT 0,
  color TEXT DEFAULT '#22c55e',
  icon TEXT,
  bank_name TEXT,
  monthly_wage DECIMAL DEFAULT 0,
  wage_day INTEGER,
  same_bank_transfer_fee DECIMAL DEFAULT 0,
  diff_bank_transfer_fee DECIMAL DEFAULT 0,
  include_in_net_worth BOOLEAN DEFAULT true,
  image_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='accounts' AND policyname='Users can view own accounts') THEN
    CREATE POLICY "Users can view own accounts" ON accounts FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='accounts' AND policyname='Users can insert own accounts') THEN
    CREATE POLICY "Users can insert own accounts" ON accounts FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='accounts' AND policyname='Users can update own accounts') THEN
    CREATE POLICY "Users can update own accounts" ON accounts FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='accounts' AND policyname='Users can delete own accounts') THEN
    CREATE POLICY "Users can delete own accounts" ON accounts FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 3. TRANSACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  account_id UUID REFERENCES accounts ON DELETE SET NULL,
  to_account_id UUID REFERENCES accounts ON DELETE SET NULL,
  type TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  category_id TEXT,
  note TEXT,
  description TEXT,
  merchant TEXT,
  date TIMESTAMPTZ DEFAULT NOW(),
  is_recurring BOOLEAN DEFAULT false,
  recurring_rule_id UUID,
  fee_amount DECIMAL DEFAULT 0,
  is_fee BOOLEAN DEFAULT false,
  image_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transactions' AND policyname='Users can view own transactions') THEN
    CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transactions' AND policyname='Users can insert own transactions') THEN
    CREATE POLICY "Users can insert own transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transactions' AND policyname='Users can update own transactions') THEN
    CREATE POLICY "Users can update own transactions" ON transactions FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transactions' AND policyname='Users can delete own transactions') THEN
    CREATE POLICY "Users can delete own transactions" ON transactions FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 4. GOALS
-- ============================================================
CREATE TABLE IF NOT EXISTS goals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  target_amount DECIMAL NOT NULL,
  current_amount DECIMAL DEFAULT 0,
  target_date TIMESTAMPTZ,
  priority INTEGER DEFAULT 1,
  icon TEXT,
  color TEXT DEFAULT '#22c55e',
  category_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='goals' AND policyname='Users can view own goals') THEN
    CREATE POLICY "Users can view own goals" ON goals FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='goals' AND policyname='Users can insert own goals') THEN
    CREATE POLICY "Users can insert own goals" ON goals FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='goals' AND policyname='Users can update own goals') THEN
    CREATE POLICY "Users can update own goals" ON goals FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='goals' AND policyname='Users can delete own goals') THEN
    CREATE POLICY "Users can delete own goals" ON goals FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 5. RECURRING RULES
-- ============================================================
CREATE TABLE IF NOT EXISTS recurring_rules (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  cadence TEXT NOT NULL,
  next_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  amount DECIMAL NOT NULL,
  category_id TEXT,
  note TEXT,
  template_account_id UUID,
  template_to_account_id UUID,
  template_type TEXT DEFAULT 'expense',
  template_merchant TEXT,
  template_is_recurring BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recurring_rules ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='recurring_rules' AND policyname='Users can view own recurring_rules') THEN
    CREATE POLICY "Users can view own recurring_rules" ON recurring_rules FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='recurring_rules' AND policyname='Users can insert own recurring_rules') THEN
    CREATE POLICY "Users can insert own recurring_rules" ON recurring_rules FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='recurring_rules' AND policyname='Users can update own recurring_rules') THEN
    CREATE POLICY "Users can update own recurring_rules" ON recurring_rules FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='recurring_rules' AND policyname='Users can delete own recurring_rules') THEN
    CREATE POLICY "Users can delete own recurring_rules" ON recurring_rules FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 6. STOCK HOLDINGS (Portfolio)
-- ============================================================
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

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='stock_holdings' AND policyname='Users can view own stock_holdings') THEN
    CREATE POLICY "Users can view own stock_holdings" ON stock_holdings FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='stock_holdings' AND policyname='Users can insert own stock_holdings') THEN
    CREATE POLICY "Users can insert own stock_holdings" ON stock_holdings FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='stock_holdings' AND policyname='Users can update own stock_holdings') THEN
    CREATE POLICY "Users can update own stock_holdings" ON stock_holdings FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='stock_holdings' AND policyname='Users can delete own stock_holdings') THEN
    CREATE POLICY "Users can delete own stock_holdings" ON stock_holdings FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 7. USER CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS user_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  category_id TEXT NOT NULL,
  group_name TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT DEFAULT '#22c55e',
  budget_limit DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category_id)
);

ALTER TABLE user_categories ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_categories' AND policyname='Users can view own user_categories') THEN
    CREATE POLICY "Users can view own user_categories" ON user_categories FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_categories' AND policyname='Users can insert own user_categories') THEN
    CREATE POLICY "Users can insert own user_categories" ON user_categories FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_categories' AND policyname='Users can update own user_categories') THEN
    CREATE POLICY "Users can update own user_categories" ON user_categories FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_categories' AND policyname='Users can delete own user_categories') THEN
    CREATE POLICY "Users can delete own user_categories" ON user_categories FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 8. BUDGET MONTHS
-- ============================================================
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

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='budget_months' AND policyname='Users can view own budget_months') THEN
    CREATE POLICY "Users can view own budget_months" ON budget_months FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='budget_months' AND policyname='Users can insert own budget_months') THEN
    CREATE POLICY "Users can insert own budget_months" ON budget_months FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='budget_months' AND policyname='Users can update own budget_months') THEN
    CREATE POLICY "Users can update own budget_months" ON budget_months FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='budget_months' AND policyname='Users can delete own budget_months') THEN
    CREATE POLICY "Users can delete own budget_months" ON budget_months FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================
-- 9. AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 10. STORAGE BUCKETS (logos + receipts)
-- ============================================================

-- Create 'receipts' bucket (transaction photos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('receipts', 'receipts', true, 10485760, ARRAY['image/jpeg','image/png','image/webp','image/gif','image/heic'])
ON CONFLICT (id) DO NOTHING;

-- Create 'logos' bucket (account logos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('logos', 'logos', true, 5242880, ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

-- RLS policies for 'receipts'
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Receipts public read') THEN
    CREATE POLICY "Receipts public read" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Receipts user upload') THEN
    CREATE POLICY "Receipts user upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Receipts user update') THEN
    CREATE POLICY "Receipts user update" ON storage.objects FOR UPDATE USING (bucket_id = 'receipts' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Receipts user delete') THEN
    CREATE POLICY "Receipts user delete" ON storage.objects FOR DELETE USING (bucket_id = 'receipts' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
END $$;

-- RLS policies for 'logos'
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Logos public read') THEN
    CREATE POLICY "Logos public read" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Logos user upload') THEN
    CREATE POLICY "Logos user upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Logos user update') THEN
    CREATE POLICY "Logos user update" ON storage.objects FOR UPDATE USING (bucket_id = 'logos' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND schemaname='storage' AND policyname='Logos user delete') THEN
    CREATE POLICY "Logos user delete" ON storage.objects FOR DELETE USING (bucket_id = 'logos' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
END $$;
