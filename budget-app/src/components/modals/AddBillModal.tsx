import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Check, ChevronDown } from 'lucide-react';
import { Button } from '../ui';
import { useStore } from '../../store/useStore';

interface AddBillModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AddBillModal: React.FC<AddBillModalProps> = ({ isOpen, onClose }) => {
  const { addRecurringRule, settings } = useStore();
  const [billName, setBillName] = useState('');
  const [amount, setAmount] = useState('');
  const [dueDay, setDueDay] = useState(1);
  const [showDayPicker, setShowDayPicker] = useState(false);
  const [repeatsMonthly, setRepeatsMonthly] = useState(true);
  const [includeInForecast, setIncludeInForecast] = useState(true);

  const getCurrencySymbol = () => {
    switch (settings.currency) {
      case 'USD': return '$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$';
    }
  };

  const handleSubmit = () => {
    if (!billName || !amount || parseFloat(amount) <= 0) return;

    const now = new Date();
    let nextDate = new Date(now.getFullYear(), now.getMonth(), dueDay);
    if (nextDate < now) {
      nextDate = new Date(now.getFullYear(), now.getMonth() + 1, dueDay);
    }

    addRecurringRule({
      cadence: repeatsMonthly ? 'monthly' : 'yearly',
      nextDate: nextDate.toISOString(),
      isActive: true,
      templateTransaction: {
        amount: parseFloat(amount),
        type: 'expense',
        accountId: '',
        categoryId: 'bills',
        note: billName,
      },
    });

    setBillName('');
    setAmount('');
    setDueDay(1);
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
                <button
                  onClick={onClose}
                  className="w-10 h-10 rounded-full flex items-center justify-center"
                >
                  <X className="w-6 h-6 text-theme-secondary" />
                </button>
                <h2 className="text-lg font-semibold text-theme-primary">Add Expense</h2>
                <button
                  onClick={handleSubmit}
                  disabled={!billName || !amount || parseFloat(amount) <= 0}
                  className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <Check className={`w-5 h-5 ${billName && amount && parseFloat(amount) > 0 ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                </button>
              </div>

              {/* Bill Name */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Expense Name</p>
                <input
                  type="text"
                  placeholder="e.g., Rent, Netflix, Electric"
                  value={billName}
                  onChange={(e) => setBillName(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
              </div>

              {/* Amount */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Amount</p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">
                    {getCurrencySymbol()}
                  </span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                </div>
              </div>

              {/* Due Date */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Due Date</p>
                <button
                  onClick={() => setShowDayPicker(!showDayPicker)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary flex items-center justify-between"
                >
                  <span>{dueDay === 1 ? '1st' : dueDay === 2 ? '2nd' : dueDay === 3 ? '3rd' : `${dueDay}th`} of each month</span>
                  <ChevronDown className={`w-5 h-5 text-theme-tertiary transition-transform ${showDayPicker ? 'rotate-180' : ''}`} />
                </button>
                
                {showDayPicker && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    className="mt-2 p-3 bg-theme-badge border border-theme-divider rounded-xl"
                  >
                    <div className="grid grid-cols-8 gap-2">
                      {Array.from({ length: 31 }, (_, i) => i + 1).map((day) => (
                        <button
                          key={day}
                          onClick={() => {
                            setDueDay(day);
                            setShowDayPicker(false);
                          }}
                          className={`w-9 h-9 rounded-full text-sm font-medium transition-all ${
                            dueDay === day
                              ? 'bg-gold-500 text-white'
                              : 'text-theme-tertiary hover:bg-theme-surface-hover'
                          }`}
                        >
                          {day}
                        </button>
                      ))}
                    </div>
                  </motion.div>
                )}
              </div>

              {/* Repeats Monthly Toggle */}
              <div className="mb-4 p-4 bg-theme-badge border border-theme-divider rounded-xl flex items-center justify-between">
                <div>
                  <p className="text-theme-primary font-medium">Repeats Monthly</p>
                  <p className="text-theme-tertiary text-sm">Expense recurs every month</p>
                </div>
                <button
                  onClick={() => setRepeatsMonthly(!repeatsMonthly)}
                  className={`w-12 h-7 rounded-full transition-all ${
                    repeatsMonthly ? 'bg-gold-500' : 'bg-gray-600'
                  }`}
                >
                  <div
                    className={`w-5 h-5 bg-white rounded-full transition-transform ${
                      repeatsMonthly ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>

              {/* Include in Forecast Toggle */}
              <div className="mb-6 p-4 bg-theme-badge border border-theme-divider rounded-xl flex items-center justify-between">
                <div>
                  <p className="text-theme-primary font-medium">Include in Forecast</p>
                  <p className="text-theme-tertiary text-sm">Affects your safe-to-spend calculation</p>
                </div>
                <button
                  onClick={() => setIncludeInForecast(!includeInForecast)}
                  className={`w-12 h-7 rounded-full transition-all ${
                    includeInForecast ? 'bg-gold-500' : 'bg-gray-600'
                  }`}
                >
                  <div
                    className={`w-5 h-5 bg-white rounded-full transition-transform ${
                      includeInForecast ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>

              {/* Add Bill Button */}
              <Button
                onClick={handleSubmit}
                fullWidth
                size="lg"
                disabled={!billName || !amount || parseFloat(amount) <= 0}
                className="bg-gold-500 hover:bg-gold-600 disabled:bg-theme-badge disabled:text-theme-tertiary"
              >
                Add Expense
              </Button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
