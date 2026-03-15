import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Filter, ArrowUpRight, ArrowDownLeft, ArrowLeftRight, Calendar, ArrowLeft } from 'lucide-react';
import { Card } from '../ui';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { Transaction } from '../../types';

type FilterType = 'all' | 'expense' | 'income' | 'transfer';
type SortType = 'newest' | 'oldest' | 'highest' | 'lowest';

interface TransactionsScreenProps {
  onBack?: () => void;
}

export const TransactionsScreen: React.FC<TransactionsScreenProps> = ({ onBack }) => {
  const { transactions, settings, categories, accounts } = useStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<FilterType>('all');
  const [sortBy, setSortBy] = useState<SortType>('newest');
  const [showFilters, setShowFilters] = useState(false);

  const getCategoryName = (categoryId?: string) => {
    if (!categoryId) return 'Uncategorized';
    const category = categories.find(c => c.id === categoryId);
    return category?.name || 'Unknown';
  };

  const getAccountName = (accountId: string) => {
    const account = accounts.find(a => a.id === accountId);
    return account?.name || 'Unknown';
  };

  const filteredTransactions = transactions
    .filter(t => {
      if (filterType !== 'all' && t.type !== filterType) return false;
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const note = t.note?.toLowerCase() || '';
        const category = getCategoryName(t.categoryId).toLowerCase();
        return note.includes(query) || category.includes(query);
      }
      return true;
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'newest':
          return new Date(b.date).getTime() - new Date(a.date).getTime();
        case 'oldest':
          return new Date(a.date).getTime() - new Date(b.date).getTime();
        case 'highest':
          return b.amount - a.amount;
        case 'lowest':
          return a.amount - b.amount;
        default:
          return 0;
      }
    });

  const groupedTransactions = filteredTransactions.reduce((groups, transaction) => {
    const date = new Date(transaction.date).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
    });
    if (!groups[date]) {
      groups[date] = [];
    }
    groups[date].push(transaction);
    return groups;
  }, {} as Record<string, Transaction[]>);

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case 'expense':
        return <ArrowUpRight className="w-4 h-4 text-red-500" />;
      case 'income':
        return <ArrowDownLeft className="w-4 h-4 text-emerald-500" />;
      case 'transfer':
        return <ArrowLeftRight className="w-4 h-4 text-blue-500" />;
      default:
        return null;
    }
  };

  const getTransactionColor = (type: string) => {
    switch (type) {
      case 'expense':
        return 'text-red-500';
      case 'income':
        return 'text-emerald-500';
      case 'transfer':
        return 'text-blue-500';
      default:
        return 'text-gray-500';
    }
  };

  const totalExpenses = filteredTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalIncome = filteredTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  return (
    <div className="flex-1 overflow-y-auto pb-24 bg-gradient-to-b from-theme-from via-theme-via to-theme-to min-h-screen transition-colors">
      <div className="px-4 pt-6 pb-4 safe-area-top">
        <div className="flex items-center gap-3 mb-4">
          {onBack && (
            <button
              onClick={onBack}
              className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center flex-shrink-0"
            >
              <ArrowLeft className="w-5 h-5 text-theme-primary" />
            </button>
          )}
          <motion.h1
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-2xl font-bold text-theme-primary"
          >
            Transactions
          </motion.h1>
        </div>

        {/* Search Bar */}
        <div className="relative mb-4">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-theme-tertiary" />
          <input
            type="text"
            placeholder="Search transactions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-3 rounded-2xl border border-theme-surface-border bg-theme-badge text-theme-primary placeholder:text-theme focus:outline-none focus:ring-2 focus:ring-gold-500"
          />
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded-xl bg-theme-badge"
          >
            <Filter className="w-4 h-4 text-theme-secondary" />
          </button>
        </div>

        {/* Filters */}
        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mb-4 space-y-3"
            >
              <div>
                <p className="text-xs font-medium text-theme-tertiary mb-2">Type</p>
                <div className="flex gap-2">
                  {(['all', 'expense', 'income', 'transfer'] as FilterType[]).map((type) => (
                    <button
                      key={type}
                      onClick={() => setFilterType(type)}
                      className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                        filterType === type
                          ? 'bg-gold-500 text-white'
                          : 'bg-theme-badge text-theme-secondary'
                      }`}
                    >
                      {type.charAt(0).toUpperCase() + type.slice(1)}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <p className="text-xs font-medium text-theme-tertiary mb-2">Sort by</p>
                <div className="flex gap-2">
                  {(['newest', 'oldest', 'highest', 'lowest'] as SortType[]).map((sort) => (
                    <button
                      key={sort}
                      onClick={() => setSortBy(sort)}
                      className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                        sortBy === sort
                          ? 'bg-gold-500 text-white'
                          : 'bg-theme-badge text-theme-secondary'
                      }`}
                    >
                      {sort.charAt(0).toUpperCase() + sort.slice(1)}
                    </button>
                  ))}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Summary Cards */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-2xl">
            <p className="text-xs text-red-400 font-medium mb-1">Total Spent</p>
            <p className="text-xl font-bold text-red-400">
              {formatCurrency(totalExpenses, settings.currency)}
            </p>
          </div>
          <div className="p-4 bg-gold-500/10 border border-gold-500/20 rounded-2xl">
            <p className="text-xs text-gold-400 font-medium mb-1">Total Earned</p>
            <p className="text-xl font-bold text-emerald-400">
              {formatCurrency(totalIncome, settings.currency)}
            </p>
          </div>
        </div>
      </div>

      {/* Transaction List */}
      <div className="px-4 space-y-4">
        {Object.keys(groupedTransactions).length === 0 ? (
          <Card className="text-center py-8">
            <Calendar className="w-12 h-12 text-theme-tertiary mx-auto mb-3" />
            <p className="text-theme-secondary font-medium">No transactions yet</p>
            <p className="text-sm text-theme-tertiary">Tap + to add your first transaction</p>
          </Card>
        ) : (
          Object.entries(groupedTransactions).map(([date, txs]) => (
            <div key={date}>
              <p className="text-sm font-medium text-theme-tertiary mb-2">{date}</p>
              <Card className="p-0 overflow-hidden">
                {txs.map((tx, index) => (
                  <motion.div
                    key={tx.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.05 }}
                    className={`flex items-center gap-4 p-4 ${
                      index !== txs.length - 1 ? 'border-b border-theme-divider' : ''
                    }`}
                  >
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                      tx.type === 'expense' ? 'bg-red-500/15' :
                      tx.type === 'income' ? 'bg-emerald-500/15' :
                      'bg-blue-500/15'
                    }`}>
                      {getTransactionIcon(tx.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-theme-primary truncate">
                        {tx.note || getCategoryName(tx.categoryId)}
                      </p>
                      <p className="text-sm text-theme-tertiary">
                        {getAccountName(tx.accountId)}
                      </p>
                    </div>
                    <p className={`font-semibold ${getTransactionColor(tx.type)}`}>
                      {tx.type === 'expense' ? '-' : tx.type === 'income' ? '+' : ''}
                      {formatCurrency(tx.amount, settings.currency)}
                    </p>
                  </motion.div>
                ))}
              </Card>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
