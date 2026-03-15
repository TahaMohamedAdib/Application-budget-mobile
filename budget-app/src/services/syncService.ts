import { supabase } from '../lib/supabase';
import {
  Account,
  Transaction,
  Goal,
  RecurringRule,
  UserSettings,
  BudgetMonth,
  StockHolding,
  PortfolioSnapshot,
} from '../types';

// ============================================
// PROFILE / SETTINGS
// ============================================

export async function loadProfile(userId: string): Promise<{
  settings: Partial<UserSettings>;
  totalCash: number;
} | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

  if (error || !data) return null;

  return {
    settings: {
      currency: data.currency || 'USD',
      payFrequency: data.pay_frequency || 'monthly',
      monthlyIncome: data.monthly_income || 0,
      onboardingComplete: data.onboarding_complete || false,
      theme: data.theme || 'dark',
      template: data.template || 'simple',
      subscriptionActive: data.subscription_active || false,
      subscriptionTier: data.subscription_tier || 'FREE',
      netWorthScope: data.net_worth_scope || 'all',
      selectedAccountId: data.selected_account_id || undefined,
      widgets: data.widgets || { safeToSpend: true, netWorth: true, nextBill: true, weeklySpending: false },
      goals: data.goals || [],
    },
    totalCash: data.total_cash || 0,
  };
}

export async function saveProfile(userId: string, settings: UserSettings, totalCash: number) {
  const { error } = await supabase
    .from('profiles')
    .upsert({
      id: userId,
      currency: settings.currency,
      pay_frequency: settings.payFrequency,
      monthly_income: settings.monthlyIncome,
      onboarding_complete: settings.onboardingComplete,
      theme: settings.theme,
      template: settings.template,
      subscription_active: settings.subscriptionActive,
      subscription_tier: settings.subscriptionTier,
      net_worth_scope: settings.netWorthScope,
      selected_account_id: settings.selectedAccountId || null,
      widgets: settings.widgets,
      goals: settings.goals,
      total_cash: totalCash,
      updated_at: new Date().toISOString(),
    });

  if (error) console.error('Error saving profile:', error);
}

// ============================================
// ACCOUNTS
// ============================================

export async function loadAccounts(userId: string): Promise<Account[]> {
  const { data, error } = await supabase
    .from('accounts')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error || !data) return [];

  return data.map((a: any) => ({
    id: a.id,
    type: a.type,
    name: a.name,
    balance: Number(a.balance),
    color: a.color || undefined,
    icon: a.icon || undefined,
    monthlyWage: a.monthly_wage ? Number(a.monthly_wage) : undefined,
    wageDay: a.wage_day || undefined,
    bankName: a.bank_name || undefined,
    sameBankTransferFee: a.same_bank_transfer_fee ? Number(a.same_bank_transfer_fee) : undefined,
    diffBankTransferFee: a.diff_bank_transfer_fee ? Number(a.diff_bank_transfer_fee) : undefined,
  }));
}

export async function saveAccount(userId: string, account: Account) {
  const { error } = await supabase
    .from('accounts')
    .upsert({
      id: account.id,
      user_id: userId,
      type: account.type,
      name: account.name,
      balance: account.balance,
      color: account.color || '#B8860B',
      icon: account.icon || null,
      monthly_wage: account.monthlyWage || 0,
      wage_day: account.wageDay || null,
      bank_name: account.bankName || null,
      same_bank_transfer_fee: account.sameBankTransferFee || 0,
      diff_bank_transfer_fee: account.diffBankTransferFee || 0,
      updated_at: new Date().toISOString(),
    });

  if (error) console.error('Error saving account:', error);
}

export async function deleteAccountDb(userId: string, accountId: string) {
  const { error } = await supabase
    .from('accounts')
    .delete()
    .eq('id', accountId)
    .eq('user_id', userId);

  if (error) console.error('Error deleting account:', error);
}

export async function saveAllAccounts(userId: string, accounts: Account[]) {
  // Delete all existing accounts for user, then insert fresh
  await supabase.from('accounts').delete().eq('user_id', userId);

  if (accounts.length === 0) return;

  const rows = accounts.map((a) => ({
    id: a.id,
    user_id: userId,
    type: a.type,
    name: a.name,
    balance: a.balance,
    color: a.color || '#B8860B',
    icon: a.icon || null,
    monthly_wage: a.monthlyWage || 0,
    wage_day: a.wageDay || null,
    bank_name: a.bankName || null,
    same_bank_transfer_fee: a.sameBankTransferFee || 0,
    diff_bank_transfer_fee: a.diffBankTransferFee || 0,
    updated_at: new Date().toISOString(),
  }));

  const { error } = await supabase.from('accounts').insert(rows);
  if (error) console.error('Error saving all accounts:', error);
}

// ============================================
// TRANSACTIONS
// ============================================

export async function loadTransactions(userId: string): Promise<Transaction[]> {
  const { data, error } = await supabase
    .from('transactions')
    .select('*')
    .eq('user_id', userId)
    .order('date', { ascending: true });

  if (error || !data) return [];

  return data.map((t: any) => ({
    id: t.id,
    date: t.date,
    amount: Number(t.amount),
    type: t.type,
    accountId: t.account_id || '',
    toAccountId: t.to_account_id || undefined,
    categoryId: t.category_id || undefined,
    note: t.note || undefined,
    merchant: t.merchant || undefined,
    isRecurring: t.is_recurring || false,
    recurringRuleId: t.recurring_rule_id || undefined,
    feeAmount: t.fee_amount ? Number(t.fee_amount) : undefined,
    isFee: t.is_fee || false,
  }));
}

export async function saveTransaction(userId: string, transaction: Transaction) {
  const { error } = await supabase
    .from('transactions')
    .upsert({
      id: transaction.id,
      user_id: userId,
      account_id: transaction.accountId || null,
      to_account_id: transaction.toAccountId || null,
      type: transaction.type,
      amount: transaction.amount,
      category_id: transaction.categoryId || null,
      note: transaction.note || null,
      date: transaction.date,
      merchant: transaction.merchant || null,
      is_recurring: transaction.isRecurring || false,
      recurring_rule_id: transaction.recurringRuleId || null,
      fee_amount: transaction.feeAmount || 0,
      is_fee: transaction.isFee || false,
    });

  if (error) console.error('Error saving transaction:', error);
}

export async function saveMultipleTransactions(userId: string, transactions: Transaction[]) {
  if (transactions.length === 0) return;

  const rows = transactions.map((t) => ({
    id: t.id,
    user_id: userId,
    account_id: t.accountId || null,
    to_account_id: t.toAccountId || null,
    type: t.type,
    amount: t.amount,
    category_id: t.categoryId || null,
    note: t.note || null,
    date: t.date,
    merchant: t.merchant || null,
    is_recurring: t.isRecurring || false,
    recurring_rule_id: t.recurringRuleId || null,
    fee_amount: t.feeAmount || 0,
    is_fee: t.isFee || false,
  }));

  const { error } = await supabase.from('transactions').upsert(rows);
  if (error) console.error('Error saving multiple transactions:', error);
}

export async function deleteTransactionDb(userId: string, transactionId: string) {
  const { error } = await supabase
    .from('transactions')
    .delete()
    .eq('id', transactionId)
    .eq('user_id', userId);

  if (error) console.error('Error deleting transaction:', error);
}

// ============================================
// GOALS
// ============================================

export async function loadGoals(userId: string): Promise<Goal[]> {
  const { data, error } = await supabase
    .from('goals')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error || !data) return [];

  return data.map((g: any) => ({
    id: g.id,
    type: g.type,
    name: g.name,
    targetAmount: Number(g.target_amount),
    currentAmount: Number(g.current_amount),
    targetDate: g.target_date || undefined,
    priority: g.priority || 1,
    categoryId: g.category_id || undefined,
    icon: g.icon || '🎯',
    color: g.color || '#B8860B',
  }));
}

export async function saveGoal(userId: string, goal: Goal) {
  const { error } = await supabase
    .from('goals')
    .upsert({
      id: goal.id,
      user_id: userId,
      type: goal.type,
      name: goal.name,
      target_amount: goal.targetAmount,
      current_amount: goal.currentAmount,
      target_date: goal.targetDate || null,
      priority: goal.priority,
      icon: goal.icon || null,
      color: goal.color || '#B8860B',
      updated_at: new Date().toISOString(),
    });

  if (error) console.error('Error saving goal:', error);
}

export async function deleteGoalDb(userId: string, goalId: string) {
  const { error } = await supabase
    .from('goals')
    .delete()
    .eq('id', goalId)
    .eq('user_id', userId);

  if (error) console.error('Error deleting goal:', error);
}

// ============================================
// RECURRING RULES
// ============================================

export async function loadRecurringRules(userId: string): Promise<RecurringRule[]> {
  const { data, error } = await supabase
    .from('recurring_rules')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error || !data) return [];

  return data.map((r: any) => ({
    id: r.id,
    cadence: r.cadence,
    nextDate: r.next_date,
    isActive: r.is_active,
    templateTransaction: {
      amount: Number(r.amount),
      type: r.template_type || 'expense',
      accountId: r.template_account_id || '',
      toAccountId: r.template_to_account_id || undefined,
      categoryId: r.category_id || undefined,
      note: r.note || undefined,
      merchant: r.template_merchant || undefined,
      isRecurring: true,
    },
  }));
}

export async function saveRecurringRule(userId: string, rule: RecurringRule) {
  const { error } = await supabase
    .from('recurring_rules')
    .upsert({
      id: rule.id,
      user_id: userId,
      cadence: rule.cadence,
      next_date: rule.nextDate,
      is_active: rule.isActive,
      amount: rule.templateTransaction.amount,
      category_id: rule.templateTransaction.categoryId || null,
      note: rule.templateTransaction.note || null,
      template_account_id: rule.templateTransaction.accountId || null,
      template_to_account_id: rule.templateTransaction.toAccountId || null,
      template_type: rule.templateTransaction.type || 'expense',
      template_merchant: rule.templateTransaction.merchant || null,
      template_is_recurring: true,
      updated_at: new Date().toISOString(),
    });

  if (error) console.error('Error saving recurring rule:', error);
}

export async function deleteRecurringRuleDb(userId: string, ruleId: string) {
  const { error } = await supabase
    .from('recurring_rules')
    .delete()
    .eq('id', ruleId)
    .eq('user_id', userId);

  if (error) console.error('Error deleting recurring rule:', error);
}

// ============================================
// BUDGET MONTHS
// ============================================

export async function loadBudgetMonths(userId: string): Promise<BudgetMonth[]> {
  const { data, error } = await supabase
    .from('budget_months')
    .select('*')
    .eq('user_id', userId);

  if (error || !data) return [];

  return data.map((b: any) => ({
    month: b.month,
    categoryId: b.category_id,
    plannedAmount: Number(b.planned_amount),
    spentAmount: Number(b.spent_amount),
  }));
}

export async function saveBudgetMonth(userId: string, budget: BudgetMonth) {
  const { error } = await supabase
    .from('budget_months')
    .upsert({
      user_id: userId,
      month: budget.month,
      category_id: budget.categoryId,
      planned_amount: budget.plannedAmount,
      spent_amount: budget.spentAmount,
    }, { onConflict: 'user_id,month,category_id' });

  if (error) console.error('Error saving budget month:', error);
}

// ============================================
// STOCK HOLDINGS (Portfolio)
// ============================================

export async function loadPortfolio(userId: string): Promise<StockHolding[]> {
  const { data, error } = await supabase
    .from('stock_holdings')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error || !data) return [];

  return data.map((h: any) => ({
    id: h.id,
    ticker: h.ticker,
    companyName: h.company_name || undefined,
    quantity: Number(h.quantity),
    buyPrice: Number(h.buy_price),
    buyDate: h.buy_date || undefined,
    currentPrice: Number(h.current_price),
    lastUpdated: h.last_updated || new Date().toISOString(),
    notes: h.notes || undefined,
    source: h.source || 'trading.com',
  }));
}

export async function saveHolding(userId: string, holding: StockHolding) {
  const { error } = await supabase
    .from('stock_holdings')
    .upsert({
      id: holding.id,
      user_id: userId,
      ticker: holding.ticker,
      company_name: holding.companyName || null,
      quantity: holding.quantity,
      buy_price: holding.buyPrice,
      buy_date: holding.buyDate || null,
      current_price: holding.currentPrice,
      last_updated: holding.lastUpdated,
      notes: holding.notes || null,
      source: holding.source || 'trading.com',
    });

  if (error) console.error('Error saving holding:', error);
}

export async function deleteHoldingDb(userId: string, holdingId: string) {
  const { error } = await supabase
    .from('stock_holdings')
    .delete()
    .eq('id', holdingId)
    .eq('user_id', userId);

  if (error) console.error('Error deleting holding:', error);
}

// ============================================
// PORTFOLIO SNAPSHOTS
// ============================================

export async function loadPortfolioSnapshots(userId: string): Promise<PortfolioSnapshot[]> {
  const { data, error } = await supabase
    .from('portfolio_snapshots')
    .select('*')
    .eq('user_id', userId)
    .order('date', { ascending: true });

  if (error || !data) return [];

  return data.map((s: any) => ({
    id: s.id,
    date: s.date,
    totalValue: Number(s.total_value),
  }));
}

export async function savePortfolioSnapshot(userId: string, snapshot: PortfolioSnapshot) {
  const { error } = await supabase
    .from('portfolio_snapshots')
    .upsert({
      id: snapshot.id,
      user_id: userId,
      date: snapshot.date,
      total_value: snapshot.totalValue,
    }, { onConflict: 'user_id,date' });

  if (error) console.error('Error saving portfolio snapshot:', error);
}

// ============================================
// FULL LOAD (on login)
// ============================================

export async function loadAllUserData(userId: string) {
  const [
    profileData,
    accounts,
    transactions,
    goals,
    recurringRules,
    budgetMonths,
    portfolio,
    portfolioSnapshots,
  ] = await Promise.all([
    loadProfile(userId),
    loadAccounts(userId),
    loadTransactions(userId),
    loadGoals(userId),
    loadRecurringRules(userId),
    loadBudgetMonths(userId),
    loadPortfolio(userId),
    loadPortfolioSnapshots(userId),
  ]);

  return {
    settings: profileData?.settings || {},
    totalCash: profileData?.totalCash || 0,
    accounts,
    transactions,
    goals,
    recurringRules,
    budgetMonths,
    portfolio,
    portfolioSnapshots,
  };
}

// ============================================
// FULL SAVE (bulk sync current state)
// ============================================

export async function saveAllUserData(
  userId: string,
  state: {
    settings: UserSettings;
    totalCash: number;
    accounts: Account[];
    transactions: Transaction[];
    goals: Goal[];
    recurringRules: RecurringRule[];
    budgetMonths: BudgetMonth[];
    portfolio: StockHolding[];
    portfolioSnapshots: PortfolioSnapshot[];
  }
) {
  await Promise.all([
    saveProfile(userId, state.settings, state.totalCash),
    saveAllAccounts(userId, state.accounts),
    saveMultipleTransactions(userId, state.transactions),
    ...state.goals.map((g) => saveGoal(userId, g)),
    ...state.recurringRules.map((r) => saveRecurringRule(userId, r)),
    ...state.budgetMonths.map((b) => saveBudgetMonth(userId, b)),
    ...state.portfolio.map((h) => saveHolding(userId, h)),
    ...state.portfolioSnapshots.map((s) => savePortfolioSnapshot(userId, s)),
  ]);
}
