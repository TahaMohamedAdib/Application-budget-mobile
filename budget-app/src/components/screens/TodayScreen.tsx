import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle, TrendingDown, ArrowRight, Trash2, Receipt, Wallet, ArrowLeftRight, Building2, PiggyBank, ChevronDown, Check, TrendingUp, Banknote, Settings, Bell, Eye, EyeOff, MoreVertical, X, Clock, CircleDollarSign, ShieldAlert, CreditCard, Coins } from 'lucide-react';

import { useStore } from '../../store/useStore';
import { formatCurrency, getDaysRemainingInMonth } from '../../utils/formatters';

type FilterTab = 'all' | 'accounts' | 'bills' | 'transactions';

interface TodayScreenProps {
  onNavigateToPlan: () => void;
  onAddGoal: () => void;
  onOpenSettings: () => void;
  onNavigateToWealth?: () => void;
  onNavigateToTransactions?: () => void;
}

export const TodayScreen: React.FC<TodayScreenProps> = ({ onNavigateToPlan, onOpenSettings, onNavigateToWealth, onNavigateToTransactions }) => {
  const { settings, accounts, transactions, totalCash, getSafeToSpendToday, getSafeToSpendMonth, getNetWorthByScope, recurringRules, deleteTransaction } = useStore();
  const [selectedAccountId, setSelectedAccountId] = useState<string | 'all'>('all');
  const [showAccountPicker, setShowAccountPicker] = useState(false);
  const [activeFilter, setActiveFilter] = useState<FilterTab>('all');
  const [balanceVisible, setBalanceVisible] = useState(true);
  const [showNotifications, setShowNotifications] = useState(false);
  const [showQuickMenu, setShowQuickMenu] = useState<string | null>(null);
  
  const safeToSpendToday = getSafeToSpendToday();
  const safeToSpendMonth = getSafeToSpendMonth();
  const daysRemaining = getDaysRemainingInMonth();
  const netWorth = getNetWorthByScope(settings.netWorthScope, settings.selectedAccountId);
  
  const isLow = safeToSpendToday < 20;
  const isNegative = safeToSpendToday <= 0;

  // Selected account info
  const selectedAccount = selectedAccountId === 'all' ? null : accounts.find(a => a.id === selectedAccountId);
  const displayBalance = selectedAccount ? selectedAccount.balance : accounts.reduce((s, a) => s + a.balance, 0);

  // Get next 3 bills due (sorted by date)
  const now = new Date();
  const allUpcomingBills = recurringRules
    .filter(rule => rule.isActive && new Date(rule.nextDate) >= now)
    .sort((a, b) => new Date(a.nextDate).getTime() - new Date(b.nextDate).getTime());
  const nextBills = allUpcomingBills.slice(0, 3);

  // Total bills amount
  const totalBillsAmount = recurringRules
    .filter(rule => rule.isActive)
    .reduce((sum, rule) => sum + rule.templateTransaction.amount, 0);

  // Daily average
  const dailyAverage = daysRemaining > 0 ? safeToSpendMonth / daysRemaining : 0;

  // Account icon map
  const iconMap: Record<string, React.ElementType> = {
    bank: Building2, savings: PiggyBank,
    investment: TrendingUp, debt: TrendingDown,
  };

  const filterTabs: { id: FilterTab; label: string }[] = [
    { id: 'all', label: 'All' },
    { id: 'accounts', label: 'Accounts' },
    { id: 'bills', label: 'Bills' },
    { id: 'transactions', label: 'History' },
  ];

  const [showWithdrawalHistory, setShowWithdrawalHistory] = useState(false);
  const withdrawalTransactions = transactions.filter(t => t.type === 'withdrawal').sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  // Build notifications dynamically from app data
  type Notification = { id: string; icon: React.ReactNode; title: string; description: string; type: 'warning' | 'info' | 'danger' };
  const notifications: Notification[] = [];

  // Bills due within 3 days
  allUpcomingBills.forEach((bill) => {
    const daysUntil = Math.ceil((new Date(bill.nextDate).getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    if (daysUntil <= 3) {
      notifications.push({
        id: `bill-${bill.id}`,
        icon: <Clock className="w-5 h-5 text-amber-400" />,
        title: daysUntil === 0 ? 'Bill due today' : daysUntil === 1 ? 'Bill due tomorrow' : `Bill due in ${daysUntil} days`,
        description: `${bill.templateTransaction.note || 'Bill'} — ${formatCurrency(bill.templateTransaction.amount, settings.currency)}`,
        type: 'warning',
      });
    }
  });

  // Budget warnings
  if (isNegative) {
    notifications.push({
      id: 'over-budget',
      icon: <ShieldAlert className="w-5 h-5 text-red-400" />,
      title: 'Over budget!',
      description: 'You\'ve exceeded your safe spending limit. Consider reducing expenses.',
      type: 'danger',
    });
  } else if (isLow) {
    notifications.push({
      id: 'low-budget',
      icon: <AlertTriangle className="w-5 h-5 text-amber-400" />,
      title: 'Budget running low',
      description: `Only ${formatCurrency(safeToSpendToday, settings.currency)} left to spend today.`,
      type: 'warning',
    });
  }

  // Low account balance (under 100)
  accounts.forEach((account) => {
    if (account.balance < 100 && account.balance >= 0) {
      notifications.push({
        id: `low-bal-${account.id}`,
        icon: <CircleDollarSign className="w-5 h-5 text-amber-400" />,
        title: 'Low balance',
        description: `${account.name} has only ${formatCurrency(account.balance, settings.currency)} remaining.`,
        type: 'warning',
      });
    }
    if (account.balance < 0) {
      notifications.push({
        id: `neg-bal-${account.id}`,
        icon: <TrendingDown className="w-5 h-5 text-red-400" />,
        title: 'Negative balance',
        description: `${account.name} is at ${formatCurrency(account.balance, settings.currency)}.`,
        type: 'danger',
      });
    }
  });

  // Upcoming bills summary (if any exist but none are urgent)
  if (notifications.length === 0 && allUpcomingBills.length > 0) {
    const nextOne = allUpcomingBills[0];
    const daysUntil = Math.ceil((new Date(nextOne.nextDate).getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    notifications.push({
      id: 'next-bill-info',
      icon: <Receipt className="w-5 h-5 text-gold-400" />,
      title: 'Next bill coming up',
      description: `${nextOne.templateTransaction.note || 'Bill'} in ${daysUntil} days — ${formatCurrency(nextOne.templateTransaction.amount, settings.currency)}`,
      type: 'info',
    });
  }

  // Days remaining reminder
  if (daysRemaining <= 5 && daysRemaining > 0) {
    notifications.push({
      id: 'month-ending',
      icon: <Clock className="w-5 h-5 text-blue-400" />,
      title: `${daysRemaining} day${daysRemaining > 1 ? 's' : ''} left this month`,
      description: `You have ${formatCurrency(safeToSpendMonth, settings.currency)} remaining for the month.`,
      type: 'info',
    });
  }

  const notificationCount = notifications.length;

  const hideAmount = (amount: string) => balanceVisible ? amount : '••••••';

  const showSection = (section: FilterTab) => activeFilter === 'all' || activeFilter === section;

  return (
    <div className="flex-1 overflow-y-auto pb-24 bg-gradient-to-b from-theme-from via-theme-via to-theme-to min-h-screen transition-colors">
      {/* Top Header Bar */}
      <div className="px-4 pt-6 pb-2 safe-area-top bg-theme-from/95 backdrop-blur-lg sticky top-0 z-10">
        <div className="flex items-center gap-3">
          {/* Settings */}
          <button
            onClick={onOpenSettings}
            className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center flex-shrink-0 hover:bg-theme-surface-hover transition-colors"
          >
            <Settings className="w-5 h-5 text-theme-secondary" />
          </button>

          {/* Account Selector */}
          <button
            onClick={() => setShowAccountPicker(!showAccountPicker)}
            className="flex-1 flex items-center justify-between gap-2 bg-theme-surface backdrop-blur-sm border border-theme-surface-border rounded-full px-4 py-2.5 hover:bg-theme-surface-hover transition-colors"
          >
            <div className="flex items-center gap-2">
              <Wallet className="w-4 h-4 text-theme-secondary" />
              <span className="text-sm font-medium text-theme-primary">
                {selectedAccount ? selectedAccount.name : 'All Accounts'}
              </span>
            </div>
            <ChevronDown className={`w-4 h-4 text-theme-secondary transition-transform ${showAccountPicker ? 'rotate-180' : ''}`} />
          </button>

          {/* Eye Toggle */}
          <button
            onClick={() => setBalanceVisible(!balanceVisible)}
            className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center hover:bg-theme-surface-hover transition-colors"
          >
            {balanceVisible ? (
              <Eye className="w-5 h-5 text-theme-secondary" />
            ) : (
              <EyeOff className="w-5 h-5 text-theme-secondary" />
            )}
          </button>

          {/* Notification Bell */}
          <button
            onClick={() => setShowNotifications(!showNotifications)}
            className={`w-10 h-10 rounded-full backdrop-blur-sm border flex items-center justify-center relative transition-all ${
              showNotifications ? 'bg-gold-500/20 border-gold-500/30' : 'bg-theme-surface border-theme-surface-border hover:bg-theme-surface-hover'
            }`}
          >
            <Bell className={`w-5 h-5 ${showNotifications ? 'text-gold-400' : 'text-theme-secondary'}`} />
            {notificationCount > 0 && (
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 bg-red-500 rounded-full text-[10px] text-white flex items-center justify-center font-bold">
                {notificationCount}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* Account Picker Dropdown */}
      <AnimatePresence>
        {showAccountPicker && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden px-4 pb-1"
          >
            <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-2 space-y-1">
              <button
                onClick={() => { setSelectedAccountId('all'); setShowAccountPicker(false); }}
                className={`w-full p-2.5 rounded-xl flex items-center gap-3 transition-all ${
                  selectedAccountId === 'all' ? 'bg-gold-500/20' : 'hover:bg-theme-surface-hover'
                }`}
              >
                <Wallet className="w-4 h-4 text-theme-secondary" />
                <span className="flex-1 text-left text-sm font-medium text-theme-primary">All Accounts</span>
                {selectedAccountId === 'all' && <Check className="w-4 h-4 text-gold-400" />}
              </button>
              {accounts.map((account) => {
                const Icon = iconMap[account.type] || Wallet;
                return (
                  <button
                    key={account.id}
                    onClick={() => { setSelectedAccountId(account.id); setShowAccountPicker(false); }}
                    className={`w-full p-2.5 rounded-xl flex items-center gap-3 transition-all ${
                      selectedAccountId === account.id ? 'bg-gold-500/20' : 'hover:bg-theme-surface-hover'
                    }`}
                  >
                    <Icon className="w-4 h-4" style={{ color: account.color || '#B8860B' }} />
                    <div className="flex-1 text-left">
                      {account.bankName && <span className="text-xs text-theme-tertiary block">{account.bankName}</span>}
                      <span className="text-sm font-medium text-theme-primary">{account.name}</span>
                    </div>
                    <span className="text-xs text-theme-secondary">{hideAmount(formatCurrency(account.balance, settings.currency))}</span>
                    {selectedAccountId === account.id && <Check className="w-4 h-4 text-gold-400" />}
                  </button>
                );
              })}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Notification Panel */}
      <AnimatePresence>
        {showNotifications && (
          <motion.div
            initial={{ opacity: 0, y: -10, height: 0 }}
            animate={{ opacity: 1, y: 0, height: 'auto' }}
            exit={{ opacity: 0, y: -10, height: 0 }}
            className="overflow-hidden px-4 mb-2"
          >
            <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden">
              {/* Panel Header */}
              <div className="flex items-center justify-between p-4 border-b border-theme-divider">
                <h3 className="text-sm font-semibold text-theme-primary">Notifications</h3>
                <button
                  onClick={() => setShowNotifications(false)}
                  className="w-6 h-6 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <X className="w-3.5 h-3.5 text-theme-secondary" />
                </button>
              </div>

              {/* Notification Items */}
              {notifications.length > 0 ? (
                notifications.map((notif, index) => (
                  <div
                    key={notif.id}
                    className={`flex items-start gap-3 p-4 ${index !== notifications.length - 1 ? 'border-b border-theme-divider' : ''}`}
                  >
                    <div className={`w-9 h-9 rounded-xl flex-shrink-0 flex items-center justify-center ${
                      notif.type === 'danger' ? 'bg-red-500/15' : notif.type === 'warning' ? 'bg-amber-500/15' : 'bg-gold-500/15'
                    }`}>
                      {notif.icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm font-medium ${
                        notif.type === 'danger' ? 'text-red-300' : notif.type === 'warning' ? 'text-amber-300' : 'text-theme-primary'
                      }`}>
                        {notif.title}
                      </p>
                      <p className="text-xs text-theme-tertiary mt-0.5">{notif.description}</p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="p-6 text-center">
                  <Bell className="w-8 h-8 text-theme-tertiary mx-auto mb-2" />
                  <p className="text-theme-secondary text-sm">All clear!</p>
                  <p className="text-theme-tertiary text-xs mt-1">No notifications right now</p>
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Filter Pills */}
      <div className="px-4 py-3">
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar">
          {filterTabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveFilter(tab.id)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                activeFilter === tab.id
                  ? 'bg-gold-500 text-white shadow-lg shadow-gold-500/30'
                  : 'bg-theme-badge text-theme-secondary border border-theme-divider hover:bg-theme-surface-hover'
              }`}
            >
              {tab.label}
            </button>
          ))}

        </div>
      </div>

      <div className="px-4 space-y-4">
        {/* Safe to Spend Card */}
        {showSection('all') && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-gradient-to-br from-gold-600 to-gold-700 backdrop-blur-xl border border-gold-500/30 rounded-3xl p-5 relative overflow-hidden"
          >
            <div className="absolute -top-10 -right-10 w-40 h-40 bg-gold-400/20 rounded-full blur-2xl" />
            <div className="absolute -bottom-10 -left-10 w-32 h-32 bg-gold-300/20 rounded-full blur-2xl" />
            
            <div className="relative z-10">
              <div className="flex items-center justify-between mb-3">
                <p className="text-white/90 text-sm font-medium">Safe to Spend Today</p>
                <div className="relative">
                  <button
                    onClick={() => setShowQuickMenu(showQuickMenu === 'spend' ? null : 'spend')}
                    className={`w-7 h-7 rounded-full flex items-center justify-center transition-all ${
                      showQuickMenu === 'spend' ? 'bg-white/30' : 'bg-white/10'
                    }`}
                  >
                    <MoreVertical className="w-4 h-4 text-white/80" />
                  </button>
                  <AnimatePresence>
                    {showQuickMenu === 'spend' && (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: -5 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: -5 }}
                        className="absolute right-0 top-9 w-48 bg-theme-modal/95 backdrop-blur-xl border border-theme-surface-border rounded-xl overflow-hidden shadow-xl z-50"
                      >
                        <button
                          onClick={() => { onNavigateToPlan(); setShowQuickMenu(null); }}
                          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-theme-surface-hover transition-colors"
                        >
                          <CreditCard className="w-4 h-4 text-gold-400" />
                          <span className="text-sm text-theme-primary">Manage Bills</span>
                        </button>
                        <button
                          onClick={() => { onOpenSettings(); setShowQuickMenu(null); }}
                          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-theme-surface-hover transition-colors border-t border-theme-divider"
                        >
                          <Coins className="w-4 h-4 text-amber-400" />
                          <span className="text-sm text-theme-primary">Edit Income</span>
                        </button>
                        <button
                          onClick={() => { setBalanceVisible(!balanceVisible); setShowQuickMenu(null); }}
                          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-theme-surface-hover transition-colors border-t border-theme-divider"
                        >
                          {balanceVisible ? <EyeOff className="w-4 h-4 text-blue-400" /> : <Eye className="w-4 h-4 text-blue-400" />}
                          <span className="text-sm text-theme-primary">{balanceVisible ? 'Hide Amounts' : 'Show Amounts'}</span>
                        </button>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </div>

              {/* Selected Account Info */}
              {selectedAccount && (
                <div className="mb-2">
                  <p className="text-white/70 text-xs font-medium">{selectedAccount.bankName ? `${selectedAccount.bankName} — ` : ''}{selectedAccount.name}</p>
                  <p className="text-white/90 text-sm font-semibold">{hideAmount(formatCurrency(selectedAccount.balance, settings.currency))}</p>
                </div>
              )}

              <motion.p 
                className="text-4xl font-bold text-white mb-1"
                initial={{ scale: 0.5 }}
                animate={{ scale: 1 }}
                transition={{ type: 'spring', stiffness: 200 }}
              >
                {hideAmount(formatCurrency(safeToSpendToday, settings.currency))}
              </motion.p>
              <p className="text-white/60 text-xs mb-4">
                After expenses ({hideAmount(formatCurrency(totalBillsAmount, settings.currency))}/mo)
              </p>

              <div className="pt-3 border-t border-white/20 flex justify-between">
                <div>
                  <p className="text-white/60 text-xs">Days left</p>
                  <p className="text-white text-lg font-bold">{daysRemaining}</p>
                </div>
                <div>
                  <p className="text-white/60 text-xs">Daily avg</p>
                  <p className="text-white text-lg font-bold">{hideAmount(formatCurrency(dailyAverage, settings.currency))}</p>
                </div>
                <div>
                  <p className="text-white/60 text-xs">This month</p>
                  <p className="text-white text-lg font-bold">{hideAmount(formatCurrency(safeToSpendMonth, settings.currency))}</p>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Net Worth Card */}
        {showSection('accounts') && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15 }}
            onClick={onNavigateToWealth}
            className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-3xl p-5 relative overflow-hidden cursor-pointer active:scale-[0.98] transition-transform hover:border-gold-500/30"
          >
            <div className="absolute -top-8 -right-8 w-32 h-32 bg-gold-500/10 rounded-full blur-xl" />
            <div className="relative z-10">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <TrendingUp className="w-4 h-4 text-gold-500" />
                  <span className="text-theme-secondary text-sm">Net Worth</span>
                </div>
                <ArrowRight className="w-4 h-4 text-theme-tertiary" />
              </div>
              <p className="text-3xl font-bold text-theme-primary">{hideAmount(formatCurrency(netWorth, settings.currency))}</p>
              {selectedAccount && (
                <div className="mt-2 pt-2 border-t border-theme-divider">
                  {selectedAccount.bankName && <p className="text-theme-tertiary text-xs">{selectedAccount.bankName}</p>}
                  <p className="text-gold-500 font-semibold">{hideAmount(formatCurrency(displayBalance, settings.currency))}</p>
                </div>
              )}
            </div>
          </motion.div>
        )}

        {/* Cash on Hand Card */}
        {showSection('accounts') && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            onClick={() => setShowWithdrawalHistory(true)}
            className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-3xl p-5 relative overflow-hidden cursor-pointer active:scale-[0.98] transition-transform"
          >
            <div className="absolute -top-6 -right-6 w-24 h-24 bg-gold-400/10 rounded-full blur-xl" />
            <div className="relative z-10 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-2xl bg-gold-500/20 flex items-center justify-center">
                  <Banknote className="w-5 h-5 text-gold-400" />
                </div>
                <div>
                  <p className="font-medium text-theme-primary">Cash on Hand</p>
                  <p className="text-xs text-theme-tertiary">From bank withdrawals</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <p className="text-xl font-bold text-gold-500">{hideAmount(formatCurrency(totalCash, settings.currency))}</p>
                <ArrowRight className="w-4 h-4 text-theme-tertiary" />
              </div>
            </div>
          </motion.div>
        )}

        {/* Withdrawal History Modal */}
        <AnimatePresence>
          {showWithdrawalHistory && (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 bg-black/60 z-50"
                onClick={() => setShowWithdrawalHistory(false)}
              />
              <motion.div
                initial={{ opacity: 0, y: '100%' }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: '100%' }}
                transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 max-h-[75vh] flex flex-col"
              >
                <div className="flex items-center justify-between p-5 border-b border-theme-divider">
                  <div>
                    <h2 className="text-lg font-bold text-theme-primary">Withdrawal History</h2>
                    <p className="text-xs text-theme-tertiary mt-0.5">Cash on hand: {hideAmount(formatCurrency(totalCash, settings.currency))}</p>
                  </div>
                  <button
                    onClick={() => setShowWithdrawalHistory(false)}
                    className="w-9 h-9 rounded-full bg-theme-badge flex items-center justify-center"
                  >
                    <X className="w-5 h-5 text-theme-secondary" />
                  </button>
                </div>
                <div className="overflow-y-auto flex-1">
                  {withdrawalTransactions.length > 0 ? (
                    withdrawalTransactions.map((t, i) => (
                      <div key={t.id} className={`flex items-center justify-between p-4 ${i !== withdrawalTransactions.length - 1 ? 'border-b border-theme-divider' : ''}`}>
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-2xl bg-amber-500/20 flex items-center justify-center">
                            <Banknote className="w-5 h-5 text-amber-400" />
                          </div>
                          <div>
                            <p className="font-medium text-theme-primary">{t.note || 'Withdrawal'}</p>
                            <p className="text-xs text-theme-tertiary">{new Date(t.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</p>
                          </div>
                        </div>
                        <p className="font-semibold text-amber-400">{hideAmount(formatCurrency(t.amount, settings.currency))}</p>
                      </div>
                    ))
                  ) : (
                    <div className="p-8 text-center">
                      <Banknote className="w-10 h-10 text-theme-tertiary mx-auto mb-3" />
                      <p className="text-theme-secondary">No withdrawals yet</p>
                      <p className="text-theme-tertiary text-sm mt-1">Withdrawals will appear here</p>
                    </div>
                  )}
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>

        {/* Upcoming Bills */}
        {showSection('bills') && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
          >
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-theme-primary">Upcoming Bills</h3>
              <button onClick={onNavigateToPlan} className="text-gold-400 text-sm font-medium flex items-center gap-1">
                See all <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-3xl overflow-hidden">
              {nextBills.length > 0 ? (
                <div>
                  {nextBills.map((bill, index) => {
                    const daysUntil = Math.ceil((new Date(bill.nextDate).getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
                    return (
                      <div 
                        key={bill.id} 
                        className={`flex items-center justify-between p-4 ${index !== nextBills.length - 1 ? 'border-b border-theme-divider' : ''}`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-2xl flex items-center justify-center ${daysUntil <= 3 ? 'bg-red-500/20' : 'bg-amber-500/20'}`}>
                            <Receipt className={`w-5 h-5 ${daysUntil <= 3 ? 'text-red-400' : 'text-amber-400'}`} />
                          </div>
                          <div>
                            <p className="font-medium text-theme-primary">{bill.templateTransaction.note || 'Bill'}</p>
                            <p className="text-xs text-theme-tertiary">
                              {new Date(bill.nextDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                              {daysUntil <= 7 && (
                                <span className={`ml-1 ${daysUntil <= 3 ? 'text-red-400' : 'text-amber-400'}`}>
                                  ({daysUntil === 0 ? 'Today' : daysUntil === 1 ? 'Tomorrow' : `in ${daysUntil}d`})
                                </span>
                              )}
                            </p>
                          </div>
                        </div>
                        <p className="font-semibold text-theme-primary">
                          {hideAmount(formatCurrency(bill.templateTransaction.amount, settings.currency))}
                        </p>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="p-4 text-center">
                  <p className="text-theme-tertiary text-sm">No upcoming expenses</p>
                </div>
              )}
            </div>
          </motion.div>
        )}

        {/* Recent Transactions */}
        {showSection('transactions') && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-theme-primary">Recent Transactions</h3>
              <button 
                onClick={onNavigateToTransactions}
                className="text-gold-400 text-sm font-medium flex items-center gap-1"
              >
                See all <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-3xl overflow-hidden">
              {transactions.length > 0 ? (
                <AnimatePresence>
                  {transactions.slice(-5).reverse()
                    .filter(t => selectedAccountId === 'all' || t.accountId === selectedAccountId || t.toAccountId === selectedAccountId)
                    .map((transaction) => {
                    const getIcon = () => {
                      switch (transaction.type) {
                        case 'expense': return <Receipt className="w-5 h-5 text-red-400" />;
                        case 'income': return <Wallet className="w-5 h-5 text-gold-500" />;
                        case 'transfer': return <ArrowLeftRight className="w-5 h-5 text-blue-400" />;
                        case 'withdrawal': return <Banknote className="w-5 h-5 text-amber-400" />;
                        default: return <Receipt className="w-5 h-5 text-theme-tertiary" />;
                      }
                    };
                    const getColor = () => {
                      switch (transaction.type) {
                        case 'expense': return 'text-red-400';
                        case 'income': return 'text-gold-500';
                        case 'transfer': return 'text-blue-400';
                        case 'withdrawal': return 'text-amber-400';
                        default: return 'text-theme-tertiary';
                      }
                    };
                    return (
                      <motion.div
                        key={transaction.id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 20 }}
                        className="flex items-center justify-between p-4 border-b border-theme-divider last:border-b-0"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-2xl bg-theme-badge flex items-center justify-center">
                            {getIcon()}
                          </div>
                          <div>
                            <p className="font-medium text-theme-primary">
                              {transaction.note || transaction.type.charAt(0).toUpperCase() + transaction.type.slice(1)}
                            </p>
                            <p className="text-sm text-theme-tertiary">
                              {new Date(transaction.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <p className={`font-semibold ${getColor()}`}>
                            {transaction.type === 'expense' ? '-' : transaction.type === 'income' ? '+' : ''}
                            {hideAmount(formatCurrency(transaction.amount, settings.currency))}
                          </p>
                          <button
                            onClick={() => {
                              if (confirm('Delete this transaction?')) {
                                deleteTransaction(transaction.id);
                              }
                            }}
                            className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-theme-surface-hover"
                          >
                            <Trash2 className="w-4 h-4 text-theme-tertiary" />
                          </button>
                        </div>
                      </motion.div>
                    );
                  })}
                </AnimatePresence>
              ) : (
                <div className="p-6 text-center">
                  <p className="text-theme-secondary">No transactions yet</p>
                  <p className="text-theme-tertiary text-sm mt-1">Tap the + button to add your first transaction</p>
                </div>
              )}
            </div>
          </motion.div>
        )}

        {/* Warning Card */}
        {(isLow || isNegative) && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
          >
            <div className={`rounded-3xl p-4 border ${isNegative ? 'bg-red-500/10 border-red-500/20' : 'bg-amber-500/10 border-amber-500/20'}`}>
              <div className="flex items-start gap-3">
                {isNegative ? (
                  <TrendingDown className="w-5 h-5 text-red-400 mt-0.5" />
                ) : (
                  <AlertTriangle className="w-5 h-5 text-amber-400 mt-0.5" />
                )}
                <div>
                  <p className={`font-medium ${isNegative ? 'text-red-300' : 'text-amber-300'}`}>
                    {isNegative ? 'Over budget!' : 'Running low'}
                  </p>
                  <p className={`text-sm ${isNegative ? 'text-red-400/70' : 'text-amber-400/70'}`}>
                    {isNegative
                      ? 'Consider reducing spending or adjusting your plan.'
                      : 'You might want to slow down spending.'}
                  </p>
                </div>
              </div>
            </div>
          </motion.div>
        )}

      </div>
    </div>
  );
};
