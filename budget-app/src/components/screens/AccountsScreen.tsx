import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Plus, Wallet, PiggyBank, Building2, TrendingDown, Trash2, Edit2 } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { AccountType, FREE_BANK_ACCOUNT_LIMIT } from '../../types';
import { VipUpgradeModal } from '../modals/VipUpgradeModal';
import { AddAccountModal } from '../modals/AddAccountModal';

interface AccountsScreenProps {
  onBack: () => void;
}

const accountTypeIcons: Record<AccountType, React.ElementType> = {
  bank: Building2,
  savings: PiggyBank,
  investment: TrendingDown,
  debt: TrendingDown,
};

const accountTypeLabels: Record<AccountType, string> = {
  bank: 'Bank Account',
  savings: 'Savings',
  investment: 'Investment',
  debt: 'Debt',
};

export const AccountsScreen: React.FC<AccountsScreenProps> = ({ onBack }) => {
  const { accounts, settings, deleteAccount, getBankAccountCount, canAddBankAccount, isVip } = useStore();
  const [showVipModal, setShowVipModal] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [_editingAccount, setEditingAccount] = useState<string | null>(null);

  const bankAccountCount = getBankAccountCount();
  const canAdd = canAddBankAccount();
  const vip = isVip();

  const handleAddAccount = () => {
    if (canAdd) {
      setShowAddModal(true);
    } else {
      setShowVipModal(true);
    }
  };

  const handleDeleteAccount = (id: string) => {
    if (confirm('Are you sure you want to delete this account? This action cannot be undone.')) {
      deleteAccount(id);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to">
      {/* Header */}
      <div className="bg-theme-from/80 backdrop-blur-lg border-b border-theme-divider px-4 pt-12 pb-4 safe-area-top">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-theme-primary" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-theme-primary">Accounts</h1>
            <p className="text-sm text-theme-secondary">
              {vip ? (
                <span className="text-amber-500">VIP • Unlimited accounts</span>
              ) : (
                `${bankAccountCount}/${FREE_BANK_ACCOUNT_LIMIT} Free`
              )}
            </p>
          </div>
          <button
            onClick={handleAddAccount}
            className="w-10 h-10 rounded-full bg-gold-500 flex items-center justify-center"
          >
            <Plus className="w-5 h-5 text-theme-primary" />
          </button>
        </div>
      </div>

      {/* Account List */}
      <div className="p-4 space-y-3">
        <AnimatePresence>
          {accounts.map((account, index) => {
            const Icon = accountTypeIcons[account.type] || Wallet;
            const isDebt = account.type === 'debt';
            
            return (
              <motion.div
                key={account.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: -100 }}
                transition={{ delay: index * 0.05 }}
                className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4"
              >
                <div className="flex items-center gap-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center"
                    style={{ backgroundColor: `${account.color || '#B8860B'}20` }}
                  >
                    <Icon className="w-6 h-6" style={{ color: account.color || '#B8860B' }} />
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-theme-primary">{account.name}</p>
                    <p className="text-sm text-theme-tertiary">{accountTypeLabels[account.type]}</p>
                  </div>
                  <div className="text-right">
                    <p className={`font-bold text-lg ${isDebt ? 'text-red-400' : 'text-theme-primary'}`}>
                      {isDebt && '-'}{formatCurrency(Math.abs(account.balance), settings.currency)}
                    </p>
                  </div>
                </div>
                
                {/* Actions */}
                <div className="flex justify-end gap-2 mt-3 pt-3 border-t border-theme-divider">
                  <button
                    onClick={() => setEditingAccount(account.id)}
                    className="px-3 py-1.5 rounded-lg bg-theme-badge text-theme-secondary text-sm font-medium flex items-center gap-1"
                  >
                    <Edit2 className="w-4 h-4" />
                    Edit
                  </button>
                  <button
                    onClick={() => handleDeleteAccount(account.id)}
                    className="px-3 py-1.5 rounded-lg bg-red-500/10 text-red-400 text-sm font-medium flex items-center gap-1"
                  >
                    <Trash2 className="w-4 h-4" />
                    Delete
                  </button>
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>

        {accounts.length === 0 && (
          <div className="text-center py-12">
            <div className="w-16 h-16 bg-theme-badge rounded-full flex items-center justify-center mx-auto mb-4">
              <Wallet className="w-8 h-8 text-theme-tertiary" />
            </div>
            <p className="text-theme-tertiary mb-2">No accounts yet</p>
            <button
              onClick={handleAddAccount}
              className="text-gold-500 font-medium"
            >
              Add your first account
            </button>
          </div>
        )}

        {/* Free tier info */}
        {!vip && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="bg-amber-500/10 border border-amber-500/20 rounded-2xl p-4 mt-4"
          >
            <p className="text-amber-300 font-medium mb-1">
              Free Plan: {bankAccountCount}/{FREE_BANK_ACCOUNT_LIMIT} accounts used
            </p>
            <p className="text-amber-400/70 text-sm">
              Upgrade to VIP for unlimited accounts, AI Coach, and portfolio tracking.
            </p>
            <button
              onClick={() => setShowVipModal(true)}
              className="mt-3 px-4 py-2 bg-amber-500 text-white rounded-lg font-medium text-sm"
            >
              Upgrade to VIP
            </button>
          </motion.div>
        )}
      </div>

      {/* Modals */}
      <VipUpgradeModal
        isOpen={showVipModal}
        onClose={() => setShowVipModal(false)}
        feature="accounts"
      />

      <AddAccountModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
      />
    </div>
  );
};
