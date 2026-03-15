import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, X, Receipt, Wallet, ArrowLeftRight, Banknote } from 'lucide-react';

interface FloatingActionButtonProps {
  onAddExpense: () => void;
  onAddIncome: () => void;
  onAddTransfer: () => void;
  onAddWithdrawal: () => void;
}

export const FloatingActionButton: React.FC<FloatingActionButtonProps> = ({
  onAddExpense,
  onAddIncome,
  onAddTransfer,
  onAddWithdrawal,
}) => {
  const [isOpen, setIsOpen] = useState(false);

  const actions = [
    { id: 'expense', label: 'Expense', icon: Receipt, color: '#ef4444', onClick: onAddExpense },
    { id: 'income', label: 'Income', icon: Wallet, color: '#10B981', onClick: onAddIncome }, // keep green for income
    { id: 'transfer', label: 'Transfer', icon: ArrowLeftRight, color: '#3b82f6', onClick: onAddTransfer },
    { id: 'withdrawal', label: 'Withdraw', icon: Banknote, color: '#f59e0b', onClick: onAddWithdrawal },
  ];

  const handleActionClick = (action: () => void) => {
    action();
    setIsOpen(false);
  };

  return (
    <>
      {/* Backdrop */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/30 z-40"
            onClick={() => setIsOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Action buttons - positioned above the main FAB */}
      <AnimatePresence>
        {isOpen && (
          <div className="fixed bottom-44 right-4 z-50 flex flex-col items-end gap-3">
            {actions.map((action, index) => {
              const Icon = action.icon;
              return (
                <motion.button
                  key={action.id}
                  initial={{ opacity: 0, scale: 0.5, y: 20 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.5, y: 20 }}
                  transition={{ delay: index * 0.05 }}
                  onClick={() => handleActionClick(action.onClick)}
                  className="flex items-center gap-3"
                >
                  <span className="bg-theme-badge/90 backdrop-blur-sm px-3 py-1.5 rounded-lg shadow-lg text-sm font-medium text-theme-primary">
                    {action.label}
                  </span>
                  <div
                    className="w-12 h-12 rounded-full flex items-center justify-center shadow-lg"
                    style={{ backgroundColor: action.color }}
                  >
                    <Icon className="w-5 h-5 text-white" />
                  </div>
                </motion.button>
              );
            })}
          </div>
        )}
      </AnimatePresence>

      {/* Main FAB - positioned at bottom right, well above bottom nav */}
      <motion.button
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(!isOpen)}
        className={`fixed bottom-24 right-4 z-50 w-14 h-14 rounded-full flex items-center justify-center shadow-xl transition-colors duration-200 ${
          isOpen ? 'bg-theme-badge' : 'bg-gold-500'
        }`}
      >
        <motion.div
          animate={{ rotate: isOpen ? 0 : 0 }}
          transition={{ duration: 0.2 }}
        >
          {isOpen ? (
            <X className="w-6 h-6 text-theme-primary" />
          ) : (
            <Plus className="w-6 h-6 text-white" />
          )}
        </motion.div>
      </motion.button>
    </>
  );
};
