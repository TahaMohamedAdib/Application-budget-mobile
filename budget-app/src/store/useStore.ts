import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { v4 as uuidv4 } from 'uuid';
import {
  Account,
  Transaction,
  Category,
  BudgetMonth,
  Goal,
  RecurringRule,
  UserSettings,
  OnboardingData,
  CategoryGroup,
  StockHolding,
  PortfolioSnapshot,
  BANK_ACCOUNT_TYPES,
  FREE_BANK_ACCOUNT_LIMIT,
  NetWorthScope,
  WidgetSettings,
} from '../types';
import { defaultCategories } from '../data/categories';
import * as sync from '../services/syncService';

interface AppState {
  // Internal: current logged-in user id for sync
  _userId: string | null;

  accounts: Account[];
  transactions: Transaction[];
  categories: Category[];
  budgetMonths: BudgetMonth[];
  goals: Goal[];
  recurringRules: RecurringRule[];
  settings: UserSettings;
  onboardingStep: number;
  onboardingData: OnboardingData;
  
  // Cash (from withdrawals, not an account)
  totalCash: number;

  // Portfolio (Compte Titres)
  portfolio: StockHolding[];
  portfolioSnapshots: PortfolioSnapshot[];

  // Sync Actions
  loadFromDatabase: (userId: string) => Promise<void>;
  clearData: () => void;

  // Actions
  setOnboardingStep: (step: number) => void;
  updateOnboardingData: (data: Partial<OnboardingData>) => void;
  completeOnboarding: () => void;
  
  addAccount: (account: Omit<Account, 'id'>) => void;
  updateAccount: (id: string, account: Partial<Account>) => void;
  deleteAccount: (id: string) => void;
  
  addTransaction: (transaction: Omit<Transaction, 'id'>) => void;
  updateTransaction: (id: string, transaction: Partial<Transaction>) => void;
  deleteTransaction: (id: string) => void;
  
  addGoal: (goal: Omit<Goal, 'id'>) => void;
  updateGoal: (id: string, goal: Partial<Goal>) => void;
  deleteGoal: (id: string) => void;
  contributeToGoal: (id: string, amount: number) => void;
  
  setBudget: (month: string, categoryId: string, amount: number) => void;
  
  addRecurringRule: (rule: Omit<RecurringRule, 'id'>) => void;
  updateRecurringRule: (id: string, rule: Partial<RecurringRule>) => void;
  deleteRecurringRule: (id: string) => void;
  
  updateSettings: (settings: Partial<UserSettings>) => void;
  
  // Portfolio Actions
  addHolding: (holding: Omit<StockHolding, 'id'>) => void;
  updateHolding: (id: string, holding: Partial<StockHolding>) => void;
  deleteHolding: (id: string) => void;
  updateHoldingPrice: (id: string, price: number) => void;
  addPortfolioSnapshot: () => void;
  getPortfolioSnapshots: (range: string) => PortfolioSnapshot[];
  
  // Wage processing
  processMonthlyWages: () => void;
  
  // Computed
  getTotalBalance: () => number;
  getNetWorth: () => number;
  getNetWorthByScope: (scope: NetWorthScope, selectedAccountId?: string) => number;
  getPortfolioValue: () => number;
  getPortfolioPL: () => number;
  getBankAccountCount: () => number;
  canAddBankAccount: () => boolean;
  isVip: () => boolean;
  getSafeToSpendToday: () => number;
  getSafeToSpendMonth: () => number;
  getMonthlyExpenses: (month: string) => number;
  getMonthlyIncome: (month: string) => number;
  getCategorySpending: (categoryId: string, month: string) => number;
  getTransactionsByCategory: (group: CategoryGroup) => Transaction[];
  getNextBillDue: () => { name: string; amount: number; date: string } | null;
  getWeeklySpending: () => { thisWeek: number; lastWeek: number };
  getFeesForMonth: (month: string) => number;
  getFeesForYear: (year: string) => number;
  getTotalFees: () => number;
}

const initialWidgetSettings: WidgetSettings = {
  safeToSpend: true,
  netWorth: true,
  nextBill: true,
  weeklySpending: false,
};

const initialSettings: UserSettings = {
  currency: 'USD',
  payFrequency: 'monthly',
  monthlyIncome: 0,
  template: 'simple',
  onboardingComplete: false,
  subscriptionActive: false,
  subscriptionTier: 'FREE',
  goals: [],
  theme: 'dark',
  netWorthScope: 'all',
  selectedAccountId: undefined,
  widgets: initialWidgetSettings,
};

const initialOnboardingData: OnboardingData = {
  selectedGoals: [],
  payFrequency: 'monthly',
  monthlyIncome: 0,
  currency: 'USD',
  template: 'simple',
  bankName: '',
  accountName: '',
  currentBalance: 0,
  wageAmount: 0,
  wageDay: 1,
};

export const useStore = create<AppState>()(
  persist(
    (set, get) => ({
      _userId: null,
      accounts: [],
      transactions: [],
      categories: defaultCategories,
      budgetMonths: [],
      goals: [],
      recurringRules: [],
      settings: initialSettings,
      onboardingStep: 0,
      onboardingData: initialOnboardingData,
      totalCash: 0,
      portfolio: [],
      portfolioSnapshots: [],

      loadFromDatabase: async (userId: string) => {
        set({ _userId: userId });
        try {
          const data = await sync.loadAllUserData(userId);
          
          // Only overwrite if DB has data (onboarding complete)
          if (data.settings.onboardingComplete) {
            set({
              settings: { ...initialSettings, ...data.settings } as UserSettings,
              totalCash: data.totalCash,
              accounts: data.accounts,
              transactions: data.transactions,
              goals: data.goals,
              recurringRules: data.recurringRules,
              budgetMonths: data.budgetMonths,
              portfolio: data.portfolio,
              portfolioSnapshots: data.portfolioSnapshots,
            });
          } else {
            // New user or not onboarded yet — check if local state has onboarding done
            // If so, push local data to DB (first-time sync)
            const localState = get();
            if (localState.settings.onboardingComplete) {
              await sync.saveAllUserData(userId, {
                settings: localState.settings,
                totalCash: localState.totalCash,
                accounts: localState.accounts,
                transactions: localState.transactions,
                goals: localState.goals,
                recurringRules: localState.recurringRules,
                budgetMonths: localState.budgetMonths,
                portfolio: localState.portfolio,
                portfolioSnapshots: localState.portfolioSnapshots,
              });
            }
          }
        } catch (err) {
          console.error('[Store] loadFromDatabase failed:', err);
        }
      },

      clearData: () => {
        set({
          _userId: null,
          accounts: [],
          transactions: [],
          budgetMonths: [],
          goals: [],
          recurringRules: [],
          settings: initialSettings,
          onboardingStep: 0,
          onboardingData: initialOnboardingData,
          totalCash: 0,
          portfolio: [],
          portfolioSnapshots: [],
        });
      },

      setOnboardingStep: (step) => set({ onboardingStep: step }),
      
      updateOnboardingData: (data) =>
        set((state) => ({
          onboardingData: { ...state.onboardingData, ...data },
        })),
      
      completeOnboarding: () => {
        const { onboardingData, _userId } = get();
        const newAccount: Account = {
          id: uuidv4(),
          type: 'bank',
          name: onboardingData.accountName || 'Main Account',
          balance: onboardingData.currentBalance || 0,
          color: '#B8860B',
          bankName: onboardingData.bankName || undefined,
          monthlyWage: onboardingData.wageAmount || undefined,
          wageDay: onboardingData.wageDay || undefined,
        };
        const newSettings = {
          ...get().settings,
          currency: onboardingData.currency,
          payFrequency: onboardingData.payFrequency,
          monthlyIncome: onboardingData.wageAmount || onboardingData.monthlyIncome,
          template: onboardingData.template,
          onboardingComplete: true,
          subscriptionActive: true,
        };
        set({
          settings: newSettings,
          accounts: [newAccount],
        });
        // Sync to DB
        if (_userId) {
          sync.saveProfile(_userId, newSettings as UserSettings, 0);
          sync.saveAccount(_userId, newAccount);
        }
      },

      addAccount: (account) => {
        const newAccount = { ...account, id: uuidv4() };
        set((state) => ({
          accounts: [...state.accounts, newAccount],
        }));
        const { _userId } = get();
        if (_userId) sync.saveAccount(_userId, newAccount as Account);
      },
      
      updateAccount: (id, account) => {
        set((state) => ({
          accounts: state.accounts.map((a) =>
            a.id === id ? { ...a, ...account } : a
          ),
        }));
        const { _userId, accounts } = get();
        const updated = accounts.find((a) => a.id === id);
        if (_userId && updated) sync.saveAccount(_userId, updated);
      },
      
      deleteAccount: (id) => {
        const { _userId } = get();
        set((state) => ({
          accounts: state.accounts.filter((a) => a.id !== id),
        }));
        if (_userId) sync.deleteAccountDb(_userId, id);
      },

      addTransaction: (transaction) => {
        const id = uuidv4();
        set((state) => {
          const newTransactions = [...state.transactions];
          let newAccounts = [...state.accounts];
          
          const accountIndex = newAccounts.findIndex(
            (a) => a.id === transaction.accountId
          );
          
          // Use the fee amount provided by the user
          const feeAmount = transaction.feeAmount || 0;
          
          // Add the main transaction
          newTransactions.push({ ...transaction, id });
          
          // Cash expense: deduct from totalCash, not from any account
          if (transaction.type === 'expense' && transaction.accountId === 'cash') {
            return { transactions: newTransactions, accounts: newAccounts, totalCash: state.totalCash - transaction.amount };
          }

          if (accountIndex !== -1) {
            if (transaction.type === 'expense') {
              newAccounts[accountIndex] = {
                ...newAccounts[accountIndex],
                balance: newAccounts[accountIndex].balance - transaction.amount,
              };
            } else if (transaction.type === 'income') {
              newAccounts[accountIndex] = {
                ...newAccounts[accountIndex],
                balance: newAccounts[accountIndex].balance + transaction.amount,
              };
            } else if (transaction.type === 'transfer') {
              // Deduct transfer amount + fee from source account
              newAccounts[accountIndex] = {
                ...newAccounts[accountIndex],
                balance: newAccounts[accountIndex].balance - transaction.amount - feeAmount,
              };
              // If transferring to own account, add to destination
              if (transaction.toAccountId) {
                const toAccountIndex = newAccounts.findIndex(
                  (a) => a.id === transaction.toAccountId
                );
                if (toAccountIndex !== -1) {
                  newAccounts[toAccountIndex] = {
                    ...newAccounts[toAccountIndex],
                    balance: newAccounts[toAccountIndex].balance + transaction.amount,
                  };
                }
              }
              
              // Create a separate fee transaction for tracking
              if (feeAmount > 0) {
                newTransactions.push({
                  id: uuidv4(),
                  date: transaction.date || new Date().toISOString(),
                  amount: feeAmount,
                  type: 'expense',
                  accountId: transaction.accountId,
                  note: `Transfer fee`,
                  merchant: 'Bank Transfer Fee',
                  isFee: true,
                });
              }
            } else if (transaction.type === 'withdrawal') {
              // Withdrawal: deduct from bank account (+ fee), add to totalCash
              newAccounts[accountIndex] = {
                ...newAccounts[accountIndex],
                balance: newAccounts[accountIndex].balance - transaction.amount - feeAmount,
              };
              
              // Create a separate fee transaction for tracking
              if (feeAmount > 0) {
                newTransactions.push({
                  id: uuidv4(),
                  date: transaction.date || new Date().toISOString(),
                  amount: feeAmount,
                  type: 'expense',
                  accountId: transaction.accountId,
                  note: `Withdrawal fee`,
                  merchant: 'Bank Withdrawal Fee',
                  isFee: true,
                });
              }
            }
          }
          
          // If withdrawal, increment totalCash
          const newTotalCash = transaction.type === 'withdrawal'
            ? state.totalCash + transaction.amount
            : state.totalCash;
          
          return { transactions: newTransactions, accounts: newAccounts, totalCash: newTotalCash };
        });
        // Sync to DB after state update
        const { _userId, transactions: allTx, accounts: allAcc, totalCash: cash } = get();
        if (_userId) {
          // Sync new transactions (could be main + fee)
          const newTxs = allTx.filter((t) => t.id === id || (t.isFee && t.date === (transaction.date || new Date().toISOString())));
          sync.saveMultipleTransactions(_userId, newTxs.length > 0 ? newTxs : [{ ...transaction, id }]);
          // Sync updated account balances
          sync.saveAllAccounts(_userId, allAcc);
          // Sync totalCash
          sync.saveProfile(_userId, get().settings, cash);
        }
      },
      
      updateTransaction: (id, transaction) => {
        set((state) => ({
          transactions: state.transactions.map((t) =>
            t.id === id ? { ...t, ...transaction } : t
          ),
        }));
        const { _userId, transactions: allTx } = get();
        const updated = allTx.find((t) => t.id === id);
        if (_userId && updated) sync.saveTransaction(_userId, updated);
      },
      
      deleteTransaction: (id) => {
        const { _userId } = get();
        set((state) => ({
          transactions: state.transactions.filter((t) => t.id !== id),
        }));
        if (_userId) sync.deleteTransactionDb(_userId, id);
      },

      addGoal: (goal) => {
        const newGoal = { ...goal, id: uuidv4() };
        set((state) => ({
          goals: [...state.goals, newGoal],
        }));
        const { _userId } = get();
        if (_userId) sync.saveGoal(_userId, newGoal as Goal);
      },
      
      updateGoal: (id, goal) => {
        set((state) => ({
          goals: state.goals.map((g) => (g.id === id ? { ...g, ...goal } : g)),
        }));
        const { _userId, goals } = get();
        const updated = goals.find((g) => g.id === id);
        if (_userId && updated) sync.saveGoal(_userId, updated);
      },
      
      deleteGoal: (id) => {
        const { _userId } = get();
        set((state) => ({
          goals: state.goals.filter((g) => g.id !== id),
        }));
        if (_userId) sync.deleteGoalDb(_userId, id);
      },
      
      contributeToGoal: (id, amount) => {
        set((state) => ({
          goals: state.goals.map((g) =>
            g.id === id ? { ...g, currentAmount: g.currentAmount + amount } : g
          ),
        }));
        const { _userId, goals } = get();
        const updated = goals.find((g) => g.id === id);
        if (_userId && updated) sync.saveGoal(_userId, updated);
      },

      setBudget: (month, categoryId, amount) => {
        set((state) => {
          const existingIndex = state.budgetMonths.findIndex(
            (b) => b.month === month && b.categoryId === categoryId
          );
          
          if (existingIndex !== -1) {
            const newBudgetMonths = [...state.budgetMonths];
            newBudgetMonths[existingIndex] = {
              ...newBudgetMonths[existingIndex],
              plannedAmount: amount,
            };
            return { budgetMonths: newBudgetMonths };
          }
          
          return {
            budgetMonths: [
              ...state.budgetMonths,
              { month, categoryId, plannedAmount: amount, spentAmount: 0 },
            ],
          };
        });
        const { _userId } = get();
        if (_userId) sync.saveBudgetMonth(_userId, { month, categoryId, plannedAmount: amount, spentAmount: 0 });
      },

      addRecurringRule: (rule) => {
        const newRule = { ...rule, id: uuidv4() };
        set((state) => ({
          recurringRules: [...state.recurringRules, newRule],
        }));
        const { _userId } = get();
        if (_userId) sync.saveRecurringRule(_userId, newRule as RecurringRule);
      },
      
      updateRecurringRule: (id, rule) => {
        set((state) => ({
          recurringRules: state.recurringRules.map((r) =>
            r.id === id ? { ...r, ...rule } : r
          ),
        }));
        const { _userId, recurringRules } = get();
        const updated = recurringRules.find((r) => r.id === id);
        if (_userId && updated) sync.saveRecurringRule(_userId, updated);
      },
      
      deleteRecurringRule: (id) => {
        const { _userId } = get();
        set((state) => ({
          recurringRules: state.recurringRules.filter((r) => r.id !== id),
        }));
        if (_userId) sync.deleteRecurringRuleDb(_userId, id);
      },

      updateSettings: (settings) => {
        set((state) => ({
          settings: { ...state.settings, ...settings },
        }));
        const { _userId, settings: fullSettings, totalCash } = get();
        if (_userId) sync.saveProfile(_userId, fullSettings, totalCash);
      },

      getTotalBalance: () => {
        const { accounts } = get();
        return accounts
          .filter((a) => a.type !== 'debt')
          .reduce((sum, a) => sum + a.balance, 0);
      },

      getNetWorth: () => {
        const { accounts } = get();
        const assets = accounts
          .filter((a) => a.type !== 'debt')
          .reduce((sum, a) => sum + a.balance, 0);
        const debts = accounts
          .filter((a) => a.type === 'debt')
          .reduce((sum, a) => sum + Math.abs(a.balance), 0);
        return assets - debts;
      },

      getSafeToSpendMonth: () => {
        const { settings, transactions, goals, recurringRules, categories } = get();
        const now = new Date();
                
        // Get fixed bills for this month
        const fixedCategories = categories.filter((c) => c.group === 'fixed');
        const fixedCategoryIds = fixedCategories.map((c) => c.id);
        
        const fixedBillsThisMonth = recurringRules
          .filter((r) => {
            const nextDate = new Date(r.nextDate);
            return (
              r.isActive &&
              r.templateTransaction.categoryId &&
              fixedCategoryIds.includes(r.templateTransaction.categoryId) &&
              nextDate.getMonth() === now.getMonth() &&
              nextDate.getFullYear() === now.getFullYear()
            );
          })
          .reduce((sum, r) => sum + r.templateTransaction.amount, 0);
        
        // Get goal contributions needed this month
        const goalContributions = goals.reduce((sum, g) => {
          if (!g.targetDate) return sum;
          const targetDate = new Date(g.targetDate);
          const monthsRemaining = Math.max(
            1,
            (targetDate.getFullYear() - now.getFullYear()) * 12 +
              (targetDate.getMonth() - now.getMonth())
          );
          const remaining = g.targetAmount - g.currentAmount;
          return sum + remaining / monthsRemaining;
        }, 0);
        
        // Already spent this month on variable expenses
        const variableCategories = categories.filter((c) => c.group === 'variable');
        const variableCategoryIds = variableCategories.map((c) => c.id);
        
        const spentThisMonth = transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            return (
              t.type === 'expense' &&
              t.categoryId &&
              variableCategoryIds.includes(t.categoryId) &&
              tDate.getMonth() === now.getMonth() &&
              tDate.getFullYear() === now.getFullYear()
            );
          })
          .reduce((sum, t) => sum + t.amount, 0);
        
        const safeToSpend =
          settings.monthlyIncome - fixedBillsThisMonth - goalContributions - spentThisMonth;
        
        return Math.max(0, safeToSpend);
      },

      getSafeToSpendToday: () => {
        const safeToSpendMonth = get().getSafeToSpendMonth();
        const now = new Date();
        const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
        const daysRemaining = daysInMonth - now.getDate() + 1;
        
        return Math.max(0, safeToSpendMonth / daysRemaining);
      },

      getMonthlyExpenses: (month) => {
        const { transactions } = get();
        return transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            const tMonth = `${tDate.getFullYear()}-${String(tDate.getMonth() + 1).padStart(2, '0')}`;
            return t.type === 'expense' && tMonth === month;
          })
          .reduce((sum, t) => sum + t.amount, 0);
      },

      getMonthlyIncome: (month) => {
        const { transactions } = get();
        return transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            const tMonth = `${tDate.getFullYear()}-${String(tDate.getMonth() + 1).padStart(2, '0')}`;
            return t.type === 'income' && tMonth === month;
          })
          .reduce((sum, t) => sum + t.amount, 0);
      },

      getCategorySpending: (categoryId, month) => {
        const { transactions } = get();
        return transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            const tMonth = `${tDate.getFullYear()}-${String(tDate.getMonth() + 1).padStart(2, '0')}`;
            return t.type === 'expense' && t.categoryId === categoryId && tMonth === month;
          })
          .reduce((sum, t) => sum + t.amount, 0);
      },

      getTransactionsByCategory: (group) => {
        const { transactions, categories } = get();
        const categoryIds = categories.filter((c) => c.group === group).map((c) => c.id);
        return transactions.filter(
          (t) => t.categoryId && categoryIds.includes(t.categoryId)
        );
      },

      // Wage processing - auto-add monthly wages on pay day
      processMonthlyWages: () => {
        const today = new Date();
        const currentDay = today.getDate();
        const currentMonth = today.toISOString().slice(0, 7); // YYYY-MM
        
        set((state) => {
          const accountsWithWage = state.accounts.filter(
            (a) => a.monthlyWage && a.monthlyWage > 0 && a.wageDay
          );
          
          if (accountsWithWage.length === 0) return state;
          
          // Check if we already processed wages this month by looking for wage transactions
          const alreadyProcessed = state.transactions.some(
            (t) => t.type === 'income' && t.note === `Monthly wage (auto)` && t.date.startsWith(currentMonth)
          );
          
          if (alreadyProcessed) return state;
          
          let newAccounts = [...state.accounts];
          const newTransactions = [...state.transactions];
          
          for (const account of accountsWithWage) {
            if (currentDay >= (account.wageDay || 1)) {
              // Add wage to account balance
              const accountIndex = newAccounts.findIndex((a) => a.id === account.id);
              if (accountIndex !== -1) {
                newAccounts[accountIndex] = {
                  ...newAccounts[accountIndex],
                  balance: newAccounts[accountIndex].balance + (account.monthlyWage || 0),
                };
                
                // Create an income transaction for the wage
                newTransactions.push({
                  id: uuidv4(),
                  date: today.toISOString(),
                  amount: account.monthlyWage || 0,
                  type: 'income',
                  accountId: account.id,
                  note: `Monthly wage (auto)`,
                  merchant: 'Salary',
                });
              }
            }
          }
          
          return {
            accounts: newAccounts,
            transactions: newTransactions,
          };
        });
        // Sync wage processing results
        const { _userId, accounts: allAcc, transactions: allTx } = get();
        if (_userId) {
          sync.saveAllAccounts(_userId, allAcc);
          sync.saveMultipleTransactions(_userId, allTx);
        }
      },

      // Portfolio Actions
      addHolding: (holding) => {
        const newHolding = { ...holding, id: uuidv4() };
        set((state) => ({
          portfolio: [...state.portfolio, newHolding],
        }));
        const { _userId } = get();
        if (_userId) sync.saveHolding(_userId, newHolding as StockHolding);
      },

      updateHolding: (id, holding) => {
        set((state) => ({
          portfolio: state.portfolio.map((h) =>
            h.id === id ? { ...h, ...holding } : h
          ),
        }));
        const { _userId, portfolio } = get();
        const updated = portfolio.find((h) => h.id === id);
        if (_userId && updated) sync.saveHolding(_userId, updated);
      },

      deleteHolding: (id) => {
        const { _userId } = get();
        set((state) => ({
          portfolio: state.portfolio.filter((h) => h.id !== id),
        }));
        if (_userId) sync.deleteHoldingDb(_userId, id);
      },

      updateHoldingPrice: (id, price) => {
        set((state) => ({
          portfolio: state.portfolio.map((h) =>
            h.id === id ? { ...h, currentPrice: price, lastUpdated: new Date().toISOString() } : h
          ),
        }));
        const { _userId, portfolio } = get();
        const updated = portfolio.find((h) => h.id === id);
        if (_userId && updated) sync.saveHolding(_userId, updated);
      },

      // New Computed Functions
      getNetWorthByScope: (scope, selectedAccountId) => {
        const { accounts, portfolio } = get();
        
        if (scope === 'selected' && selectedAccountId) {
          const account = accounts.find((a) => a.id === selectedAccountId);
          return account ? account.balance : 0;
        }
        
        // All bank accounts
        const bankAccounts = accounts.filter((a) => BANK_ACCOUNT_TYPES.includes(a.type));
        const assets = bankAccounts
          .filter((a) => a.type !== 'debt')
          .reduce((sum, a) => sum + a.balance, 0);
        const debts = bankAccounts
          .filter((a) => a.type === 'debt')
          .reduce((sum, a) => sum + Math.abs(a.balance), 0);
        const bankNetWorth = assets - debts;
        
        if (scope === 'all_with_portfolio') {
          const portfolioValue = portfolio.reduce((sum, h) => sum + (h.quantity * h.currentPrice), 0);
          return bankNetWorth + portfolioValue;
        }
        
        return bankNetWorth;
      },

      getPortfolioValue: () => {
        const { portfolio } = get();
        return portfolio.reduce((sum, h) => sum + (h.quantity * h.currentPrice), 0);
      },

      getPortfolioPL: () => {
        const { portfolio } = get();
        return portfolio.reduce((sum, h) => {
          const value = h.quantity * h.currentPrice;
          const cost = h.quantity * h.buyPrice;
          return sum + (value - cost);
        }, 0);
      },

      getBankAccountCount: () => {
        const { accounts } = get();
        return accounts.filter((a) => BANK_ACCOUNT_TYPES.includes(a.type)).length;
      },

      canAddBankAccount: () => {
        const { settings } = get();
        const bankCount = get().getBankAccountCount();
        if (settings.subscriptionTier === 'VIP') return true;
        return bankCount < FREE_BANK_ACCOUNT_LIMIT;
      },

      isVip: () => {
        const { settings } = get();
        return settings.subscriptionTier === 'VIP';
      },

      getNextBillDue: () => {
        const { recurringRules } = get();
        const now = new Date();
        
        const upcomingBills = recurringRules
          .filter((r) => r.isActive && new Date(r.nextDate) >= now)
          .sort((a, b) => new Date(a.nextDate).getTime() - new Date(b.nextDate).getTime());
        
        if (upcomingBills.length === 0) return null;
        
        const nextBill = upcomingBills[0];
        return {
          name: nextBill.templateTransaction.note || 'Bill',
          amount: nextBill.templateTransaction.amount,
          date: nextBill.nextDate,
        };
      },

      getWeeklySpending: () => {
        const { transactions } = get();
        const now = new Date();
        
        // Get start of this week (Sunday)
        const thisWeekStart = new Date(now);
        thisWeekStart.setDate(now.getDate() - now.getDay());
        thisWeekStart.setHours(0, 0, 0, 0);
        
        // Get start of last week
        const lastWeekStart = new Date(thisWeekStart);
        lastWeekStart.setDate(lastWeekStart.getDate() - 7);
        
        const thisWeek = transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            return t.type === 'expense' && tDate >= thisWeekStart;
          })
          .reduce((sum, t) => sum + t.amount, 0);
        
        const lastWeek = transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            return t.type === 'expense' && tDate >= lastWeekStart && tDate < thisWeekStart;
          })
          .reduce((sum, t) => sum + t.amount, 0);
        
        return { thisWeek, lastWeek };
      },

      // Fee tracking computed functions
      getFeesForMonth: (month) => {
        const { transactions } = get();
        return transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            const tMonth = `${tDate.getFullYear()}-${String(tDate.getMonth() + 1).padStart(2, '0')}`;
            return t.isFee && tMonth === month;
          })
          .reduce((sum, t) => sum + t.amount, 0);
      },

      getFeesForYear: (year) => {
        const { transactions } = get();
        return transactions
          .filter((t) => {
            const tDate = new Date(t.date);
            return t.isFee && tDate.getFullYear().toString() === year;
          })
          .reduce((sum, t) => sum + t.amount, 0);
      },

      getTotalFees: () => {
        const { transactions } = get();
        return transactions
          .filter((t) => t.isFee)
          .reduce((sum, t) => sum + t.amount, 0);
      },

      // Portfolio Snapshot Actions
      addPortfolioSnapshot: () => {
        const portfolioValue = get().getPortfolioValue();
        const today = new Date().toISOString().split('T')[0];
        
        set((state) => {
          // Check if we already have a snapshot for today
          const existingIndex = state.portfolioSnapshots.findIndex(
            (s) => s.date === today
          );
          
          if (existingIndex !== -1) {
            // Update existing snapshot
            const newSnapshots = [...state.portfolioSnapshots];
            newSnapshots[existingIndex] = {
              ...newSnapshots[existingIndex],
              totalValue: portfolioValue,
            };
            return { portfolioSnapshots: newSnapshots };
          }
          
          // Add new snapshot
          return {
            portfolioSnapshots: [
              ...state.portfolioSnapshots,
              { id: uuidv4(), date: today, totalValue: portfolioValue },
            ],
          };
        });
        // Sync snapshot
        const { _userId, portfolioSnapshots } = get();
        const snapshot = portfolioSnapshots.find((s) => s.date === today);
        if (_userId && snapshot) sync.savePortfolioSnapshot(_userId, snapshot);
      },

      getPortfolioSnapshots: (range: string) => {
        const { portfolioSnapshots } = get();
        const now = new Date();
        let startDate: Date;
        
        switch (range) {
          case '1W':
            startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
          case '1M':
            startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
            break;
          case '3M':
            startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
            break;
          case '1Y':
            startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
            break;
          case 'ALL':
          default:
            return portfolioSnapshots.sort((a, b) => 
              new Date(a.date).getTime() - new Date(b.date).getTime()
            );
        }
        
        return portfolioSnapshots
          .filter((s) => new Date(s.date) >= startDate)
          .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
      },
    }),
    {
      name: 'budget-app-storage',
    }
  )
);
