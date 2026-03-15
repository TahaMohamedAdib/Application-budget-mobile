export type AccountType = 'bank' | 'savings' | 'investment' | 'debt';

// Bank account types (count toward free limit)
export const BANK_ACCOUNT_TYPES: AccountType[] = ['bank', 'savings', 'debt'];

export interface Account {
  id: string;
  type: AccountType;
  name: string;
  balance: number;
  color?: string;
  icon?: string;
  monthlyWage?: number; // Auto-added monthly income/salary
  wageDay?: number; // Day of month wage is added (1-31)
  bankName?: string; // Bank institution name (e.g., 'BNP Paribas', 'Société Générale')
  sameBankTransferFee?: number; // Fee for transfers within same bank
  diffBankTransferFee?: number; // Fee for transfers to different bank
}

// Subscription tiers
export type SubscriptionTier = 'FREE' | 'PREMIUM' | 'VIP';

export const FREE_BANK_ACCOUNT_LIMIT = 2;

// Stock Portfolio (Compte Titres)
export interface StockHolding {
  id: string;
  ticker: string;
  companyName?: string;
  quantity: number;
  buyPrice: number;
  buyDate?: string;
  currentPrice: number;
  lastUpdated: string;
  notes?: string;
  source: 'trading.com';
}

// Portfolio historical snapshots for chart
export interface PortfolioSnapshot {
  id: string;
  date: string;
  totalValue: number;
}

// Chart time range options
export type ChartTimeRange = '1W' | '1M' | '3M' | '1Y' | 'ALL';

// Net Worth View Scope
export type NetWorthScope = 'selected' | 'all' | 'all_with_portfolio';

// Widget Types
export type WidgetType = 'safe_to_spend' | 'net_worth' | 'next_bill' | 'weekly_spending';

export interface WidgetSettings {
  safeToSpend: boolean;
  netWorth: boolean;
  nextBill: boolean;
  weeklySpending: boolean;
}

export type TransactionType = 'expense' | 'income' | 'transfer' | 'withdrawal';

export interface Transaction {
  id: string;
  date: string;
  amount: number;
  type: TransactionType;
  accountId: string;
  toAccountId?: string;
  categoryId?: string;
  note?: string;
  merchant?: string;
  isRecurring?: boolean;
  recurringRuleId?: string;
  feeAmount?: number; // Transfer fee charged
  isFee?: boolean; // Whether this transaction is a fee record
}

export type CategoryGroup = 'fixed' | 'variable' | 'future' | 'wealth';

export interface Category {
  id: string;
  group: CategoryGroup;
  name: string;
  icon: string;
  color: string;
}

export interface BudgetMonth {
  month: string;
  categoryId: string;
  plannedAmount: number;
  spentAmount: number;
}

export type GoalType = 'sinking' | 'savings' | 'debt';

export interface Goal {
  id: string;
  type: GoalType;
  name: string;
  targetAmount: number;
  targetDate?: string;
  currentAmount: number;
  priority: number;
  categoryId?: string;
  icon: string;
  color: string;
}

export type RecurringCadence = 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly';

export interface RecurringRule {
  id: string;
  cadence: RecurringCadence;
  nextDate: string;
  templateTransaction: Omit<Transaction, 'id' | 'date'>;
  isActive: boolean;
}

export type PayFrequency = 'weekly' | 'biweekly' | 'monthly' | 'irregular';

export type Currency = 'USD' | 'EUR' | 'GBP' | 'CAD' | 'AUD';

export type BudgetTemplate = 'simple' | 'saver' | 'investor';

export type ThemeMode = 'light' | 'dark' | 'system';

export interface UserSettings {
  currency: Currency;
  payFrequency: PayFrequency;
  monthlyIncome: number;
  template: BudgetTemplate;
  onboardingComplete: boolean;
  subscriptionActive: boolean;
  subscriptionTier: SubscriptionTier;
  goals: string[];
  theme: ThemeMode;
  netWorthScope: NetWorthScope;
  selectedAccountId?: string;
  widgets: WidgetSettings;
}

export interface OnboardingData {
  selectedGoals: string[];
  payFrequency: PayFrequency;
  monthlyIncome: number;
  currency: Currency;
  template: BudgetTemplate;
  bankName: string;
  accountName: string;
  currentBalance: number;
  wageAmount: number;
  wageDay: number;
}
