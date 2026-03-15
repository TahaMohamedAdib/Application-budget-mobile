import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, Settings, Wallet, ChevronRight } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { NetWorthSelector } from '../wealth/NetWorthSelector';

type TimeRange = '1W' | '1M' | '1Y' | 'ALL';

interface WealthScreenProps {
  onManageAccounts?: () => void;
  onOpenSettings: () => void;
  onOpenPortfolio?: () => void;
}

export const WealthScreen: React.FC<WealthScreenProps> = ({ onManageAccounts, onOpenSettings, onOpenPortfolio }) => {
  const { settings, accounts, transactions, totalCash, getNetWorthByScope, getFeesForMonth, getFeesForYear, getTotalFees } = useStore();
  const [timeRange, setTimeRange] = useState<TimeRange>('ALL');
  
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const currentYear = now.getFullYear().toString();
  const monthlyFees = getFeesForMonth(currentMonth);
  const yearlyFees = getFeesForYear(currentYear);
  const totalFees = getTotalFees();
  
  const netWorth = getNetWorthByScope(settings.netWorthScope, settings.selectedAccountId);
  
  // Calculate balance change for selected time range
  const getBalanceForRange = (): { total: number; income: number; expenses: number } => {
    let startDate: Date;
    if (timeRange === '1W') {
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    } else if (timeRange === '1M') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (timeRange === '1Y') {
      startDate = new Date(now.getFullYear(), 0, 1);
    } else {
      startDate = new Date(0); // All time
    }
    
    const filtered = transactions.filter(t => new Date(t.date) >= startDate);
    const income = filtered.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const expenses = filtered.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    return { total: income - expenses, income, expenses };
  };
  const rangeData = getBalanceForRange();
  
  const bankAccounts = accounts.filter((a) => a.type === 'bank');
  const savingsAccounts = accounts.filter((a) => a.type === 'savings');
  const investmentAccounts = accounts.filter((a) => a.type === 'investment');
  const debtAccounts = accounts.filter((a) => a.type === 'debt');

  const totalBank = bankAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalSavings = savingsAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalInvestments = investmentAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalDebt = debtAccounts.reduce((sum, a) => sum + Math.abs(a.balance), 0);

  const emergencyFundTarget = settings.monthlyIncome * 3 || 9;
  const emergencyFundProgress = emergencyFundTarget > 0 ? (totalSavings / emergencyFundTarget) * 100 : 0;

  const breakdownItems = [
    { icon: '🏦', label: 'Bank Accounts', sublabel: 'Checking & current', amount: totalBank, color: '#3b82f6', onClick: undefined as (() => void) | undefined },
    { icon: '💵', label: 'Cash on Hand', sublabel: 'From withdrawals', amount: totalCash, color: '#B8860B', onClick: undefined as (() => void) | undefined },
    { icon: '🐷', label: 'Savings', sublabel: 'Emergency fund & goals', amount: totalSavings, color: '#f59e0b', onClick: undefined as (() => void) | undefined },
    { icon: '📈', label: 'Investments', sublabel: 'Stocks, funds, etc.', amount: totalInvestments, color: '#8b5cf6', onClick: onOpenPortfolio },
    { icon: '💳', label: 'Debt', sublabel: 'Loans & debts', amount: -totalDebt, color: '#ef4444', onClick: undefined as (() => void) | undefined },
  ];

  const timeRangeLabel = timeRange === '1W' ? 'This Week' : timeRange === '1M' ? 'This Month' : timeRange === '1Y' ? 'This Year' : 'All Time';

  return (
    <div className="flex-1 overflow-y-auto pb-24 bg-gradient-to-b from-theme-from via-theme-via to-theme-to min-h-screen transition-colors">
      {/* Header */}
      <div className="px-4 pt-6 pb-4 safe-area-top">
        <div className="flex items-center justify-between mb-3">
          <motion.h1
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-2xl font-bold text-theme-primary"
          >
            Wealth
          </motion.h1>
          <div className="flex items-center gap-2">
            {/* Time Range Selector */}
            <div className="flex bg-theme-surface backdrop-blur-sm border border-theme-divider rounded-full p-1">
              {(['1W', '1M', '1Y', 'ALL'] as TimeRange[]).map((range) => (
                <button
                  key={range}
                  onClick={() => setTimeRange(range)}
                  className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                    timeRange === range
                      ? 'bg-gold-500 text-white shadow-lg shadow-gold-500/30'
                      : 'text-theme-secondary'
                  }`}
                >
                  {range}
                </button>
              ))}
            </div>
            {/* Settings */}
            <button
              onClick={onOpenSettings}
              className="w-9 h-9 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center"
            >
              <Settings className="w-4 h-4 text-theme-secondary" />
            </button>
          </div>
        </div>
        {/* Net Worth Scope Selector */}
        <NetWorthSelector />
      </div>

      <div className="px-4 space-y-4">
        {/* Net Worth Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-br from-primary-900/90 to-primary-800/80 backdrop-blur-xl border border-primary-700/30 rounded-3xl p-5 relative overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-48 h-48 bg-gold-500/10 rounded-full -translate-y-1/2 translate-x-1/4" />
          
          <div className="relative z-10">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp className="w-4 h-4 text-theme-primary" />
              <span className="text-theme-primary text-sm">Net Worth</span>
            </div>
            <motion.p 
              className="text-4xl font-bold text-theme-primary mb-2"
              initial={{ scale: 0.5 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 200 }}
            >
              {formatCurrency(netWorth, settings.currency)}
            </motion.p>
            
            {/* Period Summary */}
            <div className="mt-3 pt-3 border-t border-theme-surface-border">
              <p className="text-theme-secondary text-xs mb-2">{timeRangeLabel}</p>
              <div className="flex justify-between">
                <div>
                  <p className="text-theme-secondary text-xs">Income</p>
                  <p className="text-emerald-400 font-semibold text-sm">+{formatCurrency(rangeData.income, settings.currency)}</p>
                </div>
                <div>
                  <p className="text-theme-secondary text-xs">Expenses</p>
                  <p className="text-red-300 font-semibold text-sm">-{formatCurrency(rangeData.expenses, settings.currency)}</p>
                </div>
                <div>
                  <p className="text-theme-secondary text-xs">Balance</p>
                  <p className={`font-semibold text-sm ${rangeData.total >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                    {rangeData.total >= 0 ? '+' : ''}{formatCurrency(rangeData.total, settings.currency)}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Breakdown Section */}
        <div>
          <h3 className="text-theme-secondary text-sm mb-3">Breakdown</h3>
          <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden">
            {breakdownItems.map((item, index) => (
              <div 
                key={item.label}
                onClick={item.onClick}
                className={`flex items-center gap-4 p-4 ${index !== breakdownItems.length - 1 ? 'border-b border-theme-divider' : ''} ${item.onClick ? 'cursor-pointer active:bg-theme-surface-hover' : ''}`}
              >
                <div className="w-10 h-10 rounded-xl flex items-center justify-center text-xl" style={{ backgroundColor: `${item.color}20` }}>
                  {item.icon}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-theme-primary">{item.label}</p>
                  <p className="text-sm text-theme-tertiary">{item.sublabel}</p>
                </div>
                <div className="flex items-center gap-1">
                  <p className={`font-semibold ${item.amount < 0 ? 'text-red-400' : 'text-theme-primary'}`}>
                    {item.amount < 0 ? '-' : ''}{formatCurrency(Math.abs(item.amount), settings.currency)}
                  </p>
                  {item.onClick && <ChevronRight className="w-4 h-4 text-theme-tertiary" />}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Investing Section */}
        <div>
          <h3 className="text-theme-secondary text-sm mb-3">Investing</h3>
          <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-theme-tertiary text-xs mb-1">This Month</p>
                <p className="text-xl font-bold text-theme-primary">{formatCurrency(0, settings.currency)}</p>
              </div>
              <div>
                <p className="text-theme-tertiary text-xs mb-1">This Year</p>
                <p className="text-xl font-bold text-theme-primary">{formatCurrency(0, settings.currency)}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Emergency Fund Section */}
        <div>
          <h3 className="text-theme-secondary text-sm mb-3">Emergency Fund</h3>
          <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
            <div className="flex items-center justify-between mb-3">
              <p className="font-medium text-theme-primary">3 months of expenses</p>
              <span className="text-gold-400 font-semibold">{Math.round(emergencyFundProgress)}%</span>
            </div>
            <div className="h-2 bg-theme-badge rounded-full overflow-hidden mb-2">
              <div 
                className="h-full bg-gold-500 rounded-full transition-all"
                style={{ width: `${Math.min(emergencyFundProgress, 100)}%` }}
              />
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-theme-tertiary">{formatCurrency(totalSavings, settings.currency)} saved</span>
              <span className="text-theme-tertiary">Goal: {formatCurrency(emergencyFundTarget, settings.currency)}</span>
            </div>
          </div>
        </div>

        {/* Transfer Fees Summary */}
        {totalFees > 0 && (
          <div>
            <h3 className="text-theme-secondary text-sm mb-3">Transfer Fees</h3>
            <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-theme-tertiary text-xs mb-1">This Month</p>
                  <p className="font-bold text-red-500">{formatCurrency(monthlyFees, settings.currency)}</p>
                </div>
                <div>
                  <p className="text-theme-tertiary text-xs mb-1">This Year</p>
                  <p className="font-bold text-red-500">{formatCurrency(yearlyFees, settings.currency)}</p>
                </div>
                <div>
                  <p className="text-theme-tertiary text-xs mb-1">All Time</p>
                  <p className="font-bold text-red-500">{formatCurrency(totalFees, settings.currency)}</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Manage Accounts Button */}
        {onManageAccounts && (
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            onClick={onManageAccounts}
            className="w-full bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4 flex items-center gap-3"
          >
            <Wallet className="w-5 h-5 text-gold-500" />
            <span className="flex-1 text-left font-medium text-theme-primary">Manage Accounts</span>
            <span className="text-theme-tertiary">→</span>
          </motion.button>
        )}

        {/* Portfolio shortcut button */}
        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          onClick={onOpenPortfolio}
          className="w-full bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4 flex items-center gap-3"
        >
          <span className="text-xl">📈</span>
          <span className="flex-1 text-left font-medium text-theme-primary">View Portfolio</span>
          <ChevronRight className="w-5 h-5 text-theme-tertiary" />
        </motion.button>

        {/* Rules Section */}
        <div>
          <h3 className="text-theme-secondary text-sm mb-3">Rules</h3>
          <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
            <div className="flex items-center gap-3">
              <Settings className="w-5 h-5 text-theme-secondary" />
              <div>
                <p className="font-medium text-theme-primary">Investing rules</p>
                <p className="text-sm text-theme-tertiary">Only invest if emergency fund</p>
                <p className="text-sm text-gold-400">≥ 3 months of expenses</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
