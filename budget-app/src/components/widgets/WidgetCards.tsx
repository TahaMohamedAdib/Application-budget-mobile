import React from 'react';
import { motion } from 'framer-motion';
import { Wallet, TrendingUp, Calendar, BarChart3, ArrowUp, ArrowDown } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';

export const WidgetCards: React.FC = () => {
  const { 
    settings, 
    getSafeToSpendToday, 
    getNetWorthByScope, 
    getNextBillDue, 
    getWeeklySpending 
  } = useStore();

  const safeToSpend = getSafeToSpendToday();
  const netWorth = getNetWorthByScope(settings.netWorthScope, settings.selectedAccountId);
  const nextBill = getNextBillDue();
  const weeklySpending = getWeeklySpending();
  const weeklyChange = weeklySpending.lastWeek > 0 
    ? ((weeklySpending.thisWeek - weeklySpending.lastWeek) / weeklySpending.lastWeek) * 100 
    : 0;

  return (
    <div className="space-y-3">
      {/* Widget Header */}
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium text-theme-secondary">Widgets</h3>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Safe to Spend Widget */}
        {settings.widgets.safeToSpend && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-gradient-to-br from-gold-500 to-gold-600 rounded-2xl p-4 text-white"
          >
            <div className="flex items-center gap-2 mb-2">
              <Wallet className="w-4 h-4 opacity-80" />
              <span className="text-xs font-medium opacity-80">Safe to Spend</span>
            </div>
            <p className="text-2xl font-bold">
              {formatCurrency(safeToSpend, settings.currency)}
            </p>
            <p className="text-xs opacity-70 mt-1">Today</p>
          </motion.div>
        )}

        {/* Net Worth Widget */}
        {settings.widgets.netWorth && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.05 }}
            className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl p-4 text-white"
          >
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="w-4 h-4 opacity-80" />
              <span className="text-xs font-medium opacity-80">Net Worth</span>
            </div>
            <p className="text-2xl font-bold">
              {formatCurrency(netWorth, settings.currency)}
            </p>
            <p className="text-xs opacity-70 mt-1 capitalize">
              {settings.netWorthScope === 'all_with_portfolio' ? 'All + Portfolio' : 
               settings.netWorthScope === 'selected' ? 'Selected' : 'All Accounts'}
            </p>
          </motion.div>
        )}

        {/* Next Bill Widget */}
        {settings.widgets.nextBill && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.1 }}
            className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl p-4 text-white"
          >
            <div className="flex items-center gap-2 mb-2">
              <Calendar className="w-4 h-4 opacity-80" />
              <span className="text-xs font-medium opacity-80">Next Expense</span>
            </div>
            {nextBill ? (
              <>
                <p className="text-2xl font-bold">
                  {formatCurrency(nextBill.amount, settings.currency)}
                </p>
                <p className="text-xs opacity-70 mt-1 truncate">{nextBill.name}</p>
                <p className="text-xs opacity-70">
                  {new Date(nextBill.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                </p>
              </>
            ) : (
              <>
                <p className="text-lg font-medium">No expenses</p>
                <p className="text-xs opacity-70 mt-1">All caught up!</p>
              </>
            )}
          </motion.div>
        )}

        {/* Weekly Spending Widget */}
        {settings.widgets.weeklySpending && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.15 }}
            className="bg-gradient-to-br from-primary-900 to-primary-800 rounded-2xl p-4 text-white"
          >
            <div className="flex items-center gap-2 mb-2">
              <BarChart3 className="w-4 h-4 opacity-80" />
              <span className="text-xs font-medium opacity-80">This Week</span>
            </div>
            <p className="text-2xl font-bold">
              {formatCurrency(weeklySpending.thisWeek, settings.currency)}
            </p>
            <div className="flex items-center gap-1 mt-1">
              {weeklyChange > 0 ? (
                <ArrowUp className="w-3 h-3 text-red-300" />
              ) : weeklyChange < 0 ? (
                <ArrowDown className="w-3 h-3 text-emerald-300" />
              ) : null}
              <p className={`text-xs ${weeklyChange > 0 ? 'text-red-200' : weeklyChange < 0 ? 'text-emerald-200' : 'opacity-70'}`}>
                {weeklyChange !== 0 ? `${Math.abs(weeklyChange).toFixed(0)}% vs last week` : 'Same as last week'}
              </p>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
};
