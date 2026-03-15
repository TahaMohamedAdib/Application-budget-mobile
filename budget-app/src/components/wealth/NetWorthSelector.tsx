import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronDown, Check, Wallet, Building2, TrendingUp } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { NetWorthScope } from '../../types';

const scopeOptions: { id: NetWorthScope; label: string; description: string; icon: React.ElementType }[] = [
  { id: 'selected', label: 'Selected Account', description: 'View one account', icon: Wallet },
  { id: 'all', label: 'All Accounts', description: 'All bank accounts', icon: Building2 },
  { id: 'all_with_portfolio', label: 'All + Portfolio', description: 'Include stocks', icon: TrendingUp },
];

export const NetWorthSelector: React.FC = () => {
  const { settings, accounts, updateSettings } = useStore();
  const [isOpen, setIsOpen] = useState(false);
  const [showAccountPicker, setShowAccountPicker] = useState(false);

  const currentScope = scopeOptions.find((s) => s.id === settings.netWorthScope) || scopeOptions[1];
  const selectedAccount = accounts.find((a) => a.id === settings.selectedAccountId);

  const handleScopeChange = (scope: NetWorthScope) => {
    updateSettings({ netWorthScope: scope });
    setIsOpen(false);
    
    if (scope === 'selected') {
      setShowAccountPicker(true);
    }
  };

  const handleAccountSelect = (accountId: string) => {
    updateSettings({ selectedAccountId: accountId });
    setShowAccountPicker(false);
  };

  return (
    <div className="relative">
      {/* Scope Selector Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 bg-theme-badge border border-theme-divider rounded-xl text-sm"
      >
        <currentScope.icon className="w-4 h-4 text-theme-secondary" />
        <span className="text-theme-secondary font-medium">
          {settings.netWorthScope === 'selected' && selectedAccount 
            ? selectedAccount.name 
            : currentScope.label}
        </span>
        <ChevronDown className={`w-4 h-4 text-theme-tertiary transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {/* Scope Dropdown */}
      <AnimatePresence>
        {isOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-40"
              onClick={() => setIsOpen(false)}
            />
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="absolute top-full left-0 mt-2 w-56 bg-theme-modal backdrop-blur-xl rounded-xl shadow-lg border border-theme-divider z-50 overflow-hidden"
            >
              {scopeOptions.map((option) => {
                const Icon = option.icon;
                const isSelected = settings.netWorthScope === option.id;
                
                return (
                  <button
                    key={option.id}
                    onClick={() => handleScopeChange(option.id)}
                    className={`w-full p-3 flex items-center gap-3 hover:bg-theme-surface-hover transition-colors ${
                      isSelected ? 'bg-gold-500/15' : ''
                    }`}
                  >
                    <Icon className={`w-5 h-5 ${isSelected ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                    <div className="flex-1 text-left">
                      <p className={`font-medium ${isSelected ? 'text-gold-400' : 'text-theme-primary'}`}>
                        {option.label}
                      </p>
                      <p className="text-xs text-theme-tertiary">{option.description}</p>
                    </div>
                    {isSelected && <Check className="w-5 h-5 text-gold-500" />}
                  </button>
                );
              })}
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Account Picker Modal */}
      <AnimatePresence>
        {showAccountPicker && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 z-50"
              onClick={() => setShowAccountPicker(false)}
            />
            <motion.div
              initial={{ opacity: 0, y: '100%' }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: '100%' }}
              className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 p-6"
            >
              <h3 className="text-lg font-semibold text-theme-primary mb-4">Select Account</h3>
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {accounts.map((account) => (
                  <button
                    key={account.id}
                    onClick={() => handleAccountSelect(account.id)}
                    className={`w-full p-4 rounded-xl flex items-center gap-3 transition-colors ${
                      settings.selectedAccountId === account.id
                        ? 'bg-gold-500/15 border-2 border-gold-500'
                        : 'bg-theme-badge border-2 border-transparent'
                    }`}
                  >
                    <div
                      className="w-10 h-10 rounded-lg flex items-center justify-center"
                      style={{ backgroundColor: `${account.color || '#B8860B'}20` }}
                    >
                      <Wallet className="w-5 h-5" style={{ color: account.color || '#B8860B' }} />
                    </div>
                    <span className="flex-1 text-left font-medium text-theme-primary">
                      {account.name}
                    </span>
                    {settings.selectedAccountId === account.id && (
                      <Check className="w-5 h-5 text-gold-500" />
                    )}
                  </button>
                ))}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
};
