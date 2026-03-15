import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Check } from 'lucide-react';
import { Button } from '../ui';
import { useStore } from '../../store/useStore';

interface AddGoalModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type GoalType = 'sinking' | 'savings' | 'debt';

const goalTypes: { id: GoalType; name: string; description: string; icon: string; color: string }[] = [
  { id: 'sinking', name: 'Sinking Fund', description: 'Save for predictable future expenses', icon: '🎯', color: '#B8860B' },
  { id: 'savings', name: 'Savings Goal', description: 'Build up savings over time', icon: '🐷', color: '#3b82f6' },
  { id: 'debt', name: 'Pay Off Debt', description: 'Track debt payoff progress', icon: '💳', color: '#ef4444' },
];

const quickGoalNames = [
  'Emergency Fund', 'Vacation', 'Car Repairs', 'Gifts',
  'Annual Insurance', 'Taxes', 'Home Repairs', 'Medical'
];

export const AddGoalModal: React.FC<AddGoalModalProps> = ({ isOpen, onClose }) => {
  const { addGoal, settings } = useStore();
  const [selectedType, setSelectedType] = useState<GoalType>('sinking');
  const [name, setName] = useState('');
  const [targetAmount, setTargetAmount] = useState('');
  const [monthlyContribution, setMonthlyContribution] = useState('');

  const getCurrencySymbol = () => {
    switch (settings.currency) {
      case 'USD': return '$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$';
    }
  };

  const handleSubmit = () => {
    if (!name || !targetAmount || parseFloat(targetAmount) <= 0) return;

    addGoal({
      type: selectedType,
      name,
      targetAmount: parseFloat(targetAmount),
      currentAmount: 0,
      priority: 1,
      icon: goalTypes.find(t => t.id === selectedType)?.icon || '🎯',
      color: goalTypes.find(t => t.id === selectedType)?.color || '#B8860B',
    });

    setName('');
    setTargetAmount('');
    setMonthlyContribution('');
    setSelectedType('sinking');
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 z-50"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, y: '100%' }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 max-h-[90vh] overflow-y-auto"
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <button onClick={onClose} className="w-10 h-10 rounded-full flex items-center justify-center">
                  <X className="w-6 h-6 text-theme-secondary" />
                </button>
                <h2 className="text-lg font-semibold text-theme-primary">Add Goal</h2>
                <button
                  onClick={handleSubmit}
                  disabled={!name || !targetAmount}
                  className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <Check className={`w-5 h-5 ${name && targetAmount ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                </button>
              </div>

              {/* Goal Type Selection */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-3">Goal Type</p>
                <div className="space-y-2">
                  {goalTypes.map((type) => (
                    <button
                      key={type.id}
                      onClick={() => setSelectedType(type.id)}
                      className={`w-full p-4 rounded-2xl flex items-center gap-4 transition-all ${
                        selectedType === type.id
                          ? 'bg-gold-500/15 border-2 border-gold-500'
                          : 'bg-theme-badge border-2 border-transparent'
                      }`}
                    >
                      <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl" 
                           style={{ backgroundColor: `${type.color}20` }}>
                        {type.icon}
                      </div>
                      <div className="flex-1 text-left">
                        <p className="font-medium text-theme-primary">{type.name}</p>
                        <p className="text-sm text-theme-tertiary">{type.description}</p>
                      </div>
                      {selectedType === type.id && (
                        <Check className="w-5 h-5 text-gold-500" />
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Goal Name */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Goal Name</p>
                <input
                  type="text"
                  placeholder="e.g., Vacation, Emergency Fund"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
                {/* Quick name suggestions */}
                <div className="flex flex-wrap gap-2 mt-3">
                  {quickGoalNames.map((quickName) => (
                    <button
                      key={quickName}
                      onClick={() => setName(quickName)}
                      className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                        name === quickName
                          ? 'bg-gold-500 text-white'
                          : 'bg-theme-badge text-theme-secondary'
                      }`}
                    >
                      {quickName}
                    </button>
                  ))}
                </div>
              </div>

              {/* Target Amount */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Target Amount</p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">
                    {getCurrencySymbol()}
                  </span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0"
                    value={targetAmount}
                    onChange={(e) => setTargetAmount(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                </div>
              </div>

              {/* Monthly Contribution (for savings goals) */}
              {selectedType === 'savings' && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-2">Monthly Contribution</p>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">
                      {getCurrencySymbol()}
                    </span>
                    <input
                      type="number"
                      inputMode="decimal"
                      placeholder="0"
                      value={monthlyContribution}
                      onChange={(e) => setMonthlyContribution(e.target.value)}
                      className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                    />
                  </div>
                </div>
              )}

              {/* Add Goal Button */}
              <Button
                onClick={handleSubmit}
                fullWidth
                size="lg"
                disabled={!name || !targetAmount || parseFloat(targetAmount) <= 0}
                className="bg-gold-500 hover:bg-gold-600 disabled:bg-theme-badge disabled:text-theme-tertiary"
              >
                Add Goal
              </Button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
