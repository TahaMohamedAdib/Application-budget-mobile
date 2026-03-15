import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { DollarSign, Check, Building2, User, Wallet, Calendar } from 'lucide-react';
import { Button, Input } from '../../ui';
import { useStore } from '../../../store/useStore';
import { Currency, BudgetTemplate } from '../../../types';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

const currencies: { id: Currency; symbol: string; name: string }[] = [
  { id: 'USD', symbol: '$', name: 'US Dollar' },
  { id: 'EUR', symbol: '€', name: 'Euro' },
  { id: 'GBP', symbol: '£', name: 'British Pound' },
  { id: 'CAD', symbol: 'C$', name: 'Canadian Dollar' },
  { id: 'AUD', symbol: 'A$', name: 'Australian Dollar' },
];

const templates: { id: BudgetTemplate; name: string; description: string }[] = [
  { id: 'simple', name: 'Simple', description: 'Just track spending' },
  { id: 'saver', name: 'Saver', description: 'Focus on saving goals' },
  { id: 'investor', name: 'Investor', description: 'Track investments too' },
];

export const SetupScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const { onboardingData, updateOnboardingData } = useStore();
  const [balance, setBalance] = useState(onboardingData.currentBalance ? onboardingData.currentBalance.toString() : '');
  const [wage, setWage] = useState(onboardingData.wageAmount ? onboardingData.wageAmount.toString() : '');

  const handleBalanceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/[^0-9.]/g, '');
    setBalance(value);
    updateOnboardingData({ currentBalance: parseFloat(value) || 0 });
  };

  const handleWageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/[^0-9]/g, '');
    setWage(value);
    updateOnboardingData({ wageAmount: parseInt(value) || 0, monthlyIncome: parseInt(value) || 0 });
  };

  const selectCurrency = (currency: Currency) => {
    updateOnboardingData({ currency });
  };

  const selectTemplate = (template: BudgetTemplate) => {
    updateOnboardingData({ template });
  };

  const canContinue = (onboardingData.wageAmount > 0 || onboardingData.currentBalance > 0) && onboardingData.accountName.trim().length > 0;

  return (
    <div className="flex-1 flex flex-col px-6 pb-8 overflow-y-auto">
      <div className="flex-1">
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-2xl font-bold text-theme-primary mt-8 mb-2"
        >
          Set up your account
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="text-theme-secondary mb-6"
        >
          Tell us about your bank account so we can track your money
        </motion.p>

        {/* Bank Name */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Bank name
          </label>
          <Input
            type="text"
            placeholder="e.g. Chase, BNP Paribas"
            value={onboardingData.bankName}
            onChange={(e) => updateOnboardingData({ bankName: e.target.value })}
            icon={<Building2 className="w-5 h-5" />}
          />
        </motion.div>

        {/* Account Name */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Account name *
          </label>
          <Input
            type="text"
            placeholder="e.g. Checking, Main Account"
            value={onboardingData.accountName}
            onChange={(e) => updateOnboardingData({ accountName: e.target.value })}
            icon={<User className="w-5 h-5" />}
          />
        </motion.div>

        {/* Current Balance */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Current balance
          </label>
          <Input
            type="text"
            inputMode="decimal"
            placeholder="0"
            value={balance}
            onChange={handleBalanceChange}
            icon={<Wallet className="w-5 h-5" />}
          />
          <p className="text-xs text-theme-tertiary mt-1">How much is in this account right now?</p>
        </motion.div>

        {/* Wage Amount */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Monthly salary (after tax)
          </label>
          <Input
            type="text"
            inputMode="numeric"
            placeholder="0"
            value={wage}
            onChange={handleWageChange}
            icon={<DollarSign className="w-5 h-5" />}
          />
          <p className="text-xs text-theme-tertiary mt-1">We'll auto-add this to your account each month</p>
        </motion.div>

        {/* Pay Day */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            What day do you get paid?
          </label>
          <div className="flex items-center gap-3">
            <div className="flex-1 relative">
              <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                <Calendar className="w-5 h-5" />
              </div>
              <select
                value={onboardingData.wageDay}
                onChange={(e) => updateOnboardingData({ wageDay: parseInt(e.target.value) })}
                className="w-full pl-11 pr-4 py-3 rounded-xl border-2 border-theme-surface-border bg-theme-badge text-theme-primary font-medium focus:border-gold-500 focus:outline-none transition-all"
              >
                {Array.from({ length: 31 }, (_, i) => i + 1).map((day) => (
                  <option key={day} value={day}>
                    {day}{day === 1 ? 'st' : day === 2 ? 'nd' : day === 3 ? 'rd' : 'th'} of each month
                  </option>
                ))}
              </select>
            </div>
          </div>
        </motion.div>

        {/* Currency */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mb-4"
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Currency
          </label>
          <div className="flex flex-wrap gap-2">
            {currencies.map((curr) => (
              <button
                key={curr.id}
                onClick={() => selectCurrency(curr.id)}
                className={`px-4 py-2 rounded-xl font-medium transition-all duration-200 ${
                  onboardingData.currency === curr.id
                    ? 'bg-gold-500 text-white'
                    : 'bg-theme-badge text-theme-secondary hover:bg-theme-surface-hover'
                }`}
              >
                {curr.symbol} {curr.id}
              </button>
            ))}
          </div>
        </motion.div>

        {/* Template */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.45 }}
        >
          <label className="block text-sm font-medium text-theme-secondary mb-2">
            Choose your style
          </label>
          <div className="space-y-2">
            {templates.map((template) => (
              <button
                key={template.id}
                onClick={() => selectTemplate(template.id)}
                className={`w-full flex items-center gap-3 p-4 rounded-xl border-2 transition-all duration-200 ${
                  onboardingData.template === template.id
                    ? 'border-gold-500 bg-gold-500/20'
                    : 'border-theme-divider bg-theme-surface/50 hover:border-theme-surface-border'
                }`}
              >
                <div className="flex-1 text-left">
                  <p className="font-medium text-theme-primary">{template.name}</p>
                  <p className="text-sm text-theme-tertiary">{template.description}</p>
                </div>
                {onboardingData.template === template.id && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="w-6 h-6 rounded-full bg-gold-500 flex items-center justify-center"
                  >
                    <Check className="w-4 h-4 text-theme-primary" />
                  </motion.div>
                )}
              </button>
            ))}
          </div>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="mt-6"
      >
        <Button onClick={onNext} fullWidth size="lg" disabled={!canContinue}>
          See my Safe-to-Spend
        </Button>
      </motion.div>
    </div>
  );
};
