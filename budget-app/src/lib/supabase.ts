import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://timctayytkcvxvpukvlq.supabase.co';
const supabaseAnonKey = 'sb_publishable_zjVPzao230UvG97ap_uSPQ_vlNYZiKt';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Types for database tables
export interface DbProfile {
  id: string;
  email: string;
  currency: string;
  pay_frequency: string;
  monthly_income: number;
  onboarding_complete: boolean;
  created_at: string;
  updated_at: string;
}

export interface DbAccount {
  id: string;
  user_id: string;
  type: string;
  name: string;
  balance: number;
  color: string;
  created_at: string;
  updated_at: string;
}

export interface DbTransaction {
  id: string;
  user_id: string;
  account_id: string | null;
  to_account_id: string | null;
  type: string;
  amount: number;
  category_id: string | null;
  note: string | null;
  date: string;
  created_at: string;
}

export interface DbGoal {
  id: string;
  user_id: string;
  type: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date: string | null;
  priority: number;
  icon: string | null;
  color: string;
  created_at: string;
  updated_at: string;
}

export interface DbRecurringRule {
  id: string;
  user_id: string;
  cadence: string;
  next_date: string;
  is_active: boolean;
  amount: number;
  category_id: string | null;
  note: string | null;
  created_at: string;
  updated_at: string;
}
