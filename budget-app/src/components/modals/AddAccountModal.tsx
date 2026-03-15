import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Check, Building2, PiggyBank, TrendingDown } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { AccountType } from '../../types';

interface AddAccountModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const accountTypes: { id: AccountType; label: string; icon: React.ElementType; color: string }[] = [
  { id: 'bank', label: 'Bank Account', icon: Building2, color: '#3b82f6' },
  { id: 'savings', label: 'Savings', icon: PiggyBank, color: '#f59e0b' },
  { id: 'debt', label: 'Debt / Loan', icon: TrendingDown, color: '#ef4444' },
];

export const AddAccountModal: React.FC<AddAccountModalProps> = ({ isOpen, onClose }) => {
  const { addAccount } = useStore();
  const [name, setName] = useState('');
  const [selectedType, setSelectedType] = useState<AccountType>('bank');
  const [balance, setBalance] = useState('');
  const [monthlyWage, setMonthlyWage] = useState('');
  const [wageDay, setWageDay] = useState('1');
  const [bankName, setBankName] = useState('');
  const [sameBankFee, setSameBankFee] = useState('');
  const [diffBankFee, setDiffBankFee] = useState('');

  const handleSubmit = () => {
    if (!name.trim()) return;

    const selectedTypeInfo = accountTypes.find((t) => t.id === selectedType);
    
    addAccount({
      type: selectedType,
      name: name.trim(),
      balance: parseFloat(balance) || 0,
      color: selectedTypeInfo?.color || '#B8860B',
      ...(parseFloat(monthlyWage) > 0 ? {
        monthlyWage: parseFloat(monthlyWage),
        wageDay: parseInt(wageDay) || 1,
      } : {}),
      ...(bankName.trim() && (selectedType === 'bank' || selectedType === 'savings') ? {
        bankName: bankName.trim(),
        sameBankTransferFee: parseFloat(sameBankFee) || 0,
        diffBankTransferFee: parseFloat(diffBankFee) || 0,
      } : {}),
    });

    setName('');
    setBalance('');
    setMonthlyWage('');
    setWageDay('1');
    setBankName('');
    setSameBankFee('');
    setDiffBankFee('');
    setSelectedType('bank');
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
                <h2 className="text-lg font-semibold text-theme-primary">Add Account</h2>
                <button
                  onClick={handleSubmit}
                  disabled={!name.trim()}
                  className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <Check className={`w-5 h-5 ${name.trim() ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                </button>
              </div>

              {/* Account Type Selection */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-3">Account Type</p>
                <div className="space-y-2">
                  {accountTypes.map((type) => {
                    const Icon = type.icon;
                    return (
                      <button
                        key={type.id}
                        onClick={() => setSelectedType(type.id)}
                        className={`w-full p-4 rounded-2xl flex items-center gap-4 transition-all ${
                          selectedType === type.id
                            ? 'bg-gold-500/15 border-2 border-gold-500'
                            : 'bg-theme-badge border-2 border-transparent'
                        }`}
                      >
                        <div
                          className="w-12 h-12 rounded-xl flex items-center justify-center"
                          style={{ backgroundColor: `${type.color}20` }}
                        >
                          <Icon className="w-6 h-6" style={{ color: type.color }} />
                        </div>
                        <span className="flex-1 text-left font-medium text-theme-primary">
                          {type.label}
                        </span>
                        {selectedType === type.id && (
                          <Check className="w-5 h-5 text-gold-500" />
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Account Name */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Account Name</p>
                <input
                  type="text"
                  placeholder="e.g., Main Checking, Savings"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
              </div>

              {/* Current Balance */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">
                  Current Balance
                </p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">€</span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0.00"
                    value={balance}
                    onChange={(e) => setBalance(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                </div>
                {selectedType === 'debt' && (
                  <p className="text-sm text-theme-tertiary mt-2">Enter the amount you owe as a positive number</p>
                )}
              </div>

              {/* Bank Name & Transfer Fees (for bank/savings accounts) */}
              {(selectedType === 'bank' || selectedType === 'savings') && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-2">Bank Name</p>
                  <input
                    type="text"
                    placeholder="e.g., BNP Paribas, Société Générale"
                    value={bankName}
                    onChange={(e) => setBankName(e.target.value)}
                    className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                  <p className="text-sm text-theme-tertiary mt-2">Used to determine transfer fees between accounts</p>

                  {bankName.trim() && (
                    <div className="mt-4 space-y-3">
                      <div>
                        <p className="text-theme-tertiary text-sm mb-2">Same Bank Transfer Fee</p>
                        <div className="relative">
                          <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">€</span>
                          <input
                            type="number"
                            inputMode="decimal"
                            placeholder="0.00"
                            value={sameBankFee}
                            onChange={(e) => setSameBankFee(e.target.value)}
                            className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                          />
                        </div>
                      </div>
                      <div>
                        <p className="text-theme-tertiary text-sm mb-2">Different Bank Transfer Fee</p>
                        <div className="relative">
                          <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">€</span>
                          <input
                            type="number"
                            inputMode="decimal"
                            placeholder="0.00"
                            value={diffBankFee}
                            onChange={(e) => setDiffBankFee(e.target.value)}
                            className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                          />
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Monthly Wage (for bank/savings accounts) */}
              {selectedType !== 'debt' && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-2">Monthly Wage / Salary (optional)</p>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">€</span>
                    <input
                      type="number"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={monthlyWage}
                      onChange={(e) => setMonthlyWage(e.target.value)}
                      className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                    />
                  </div>
                  <p className="text-sm text-theme-tertiary mt-2">This amount will be automatically added every month</p>

                  {parseFloat(monthlyWage) > 0 && (
                    <div className="mt-3">
                      <p className="text-theme-tertiary text-sm mb-2">Pay Day (day of month)</p>
                      <select
                        value={wageDay}
                        onChange={(e) => setWageDay(e.target.value)}
                        className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary outline-none"
                      >
                        {Array.from({ length: 31 }, (_, i) => i + 1).map((day) => (
                          <option key={day} value={day}>{day}</option>
                        ))}
                      </select>
                    </div>
                  )}
                </div>
              )}

              {/* Submit Button */}
              <button
                onClick={handleSubmit}
                disabled={!name.trim()}
                className="w-full py-4 bg-gold-500 hover:bg-gold-600 disabled:bg-theme-badge disabled:text-theme-tertiary text-white font-semibold rounded-xl transition-colors"
              >
                Add Account
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
