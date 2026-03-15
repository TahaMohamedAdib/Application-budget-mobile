import React from 'react';
import { motion } from 'framer-motion';
import { Sparkles, Calendar, TrendingUp } from 'lucide-react';
import { Button } from '../../ui';
import { useStore } from '../../../store/useStore';
import { formatCurrency } from '../../../utils/formatters';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

export const PreviewScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const { onboardingData } = useStore();
  
  const estimatedFixedBills = onboardingData.monthlyIncome * 0.35;
  const estimatedSavings = onboardingData.monthlyIncome * 0.15;
  const safeToSpendMonth = onboardingData.monthlyIncome - estimatedFixedBills - estimatedSavings;
  const safeToSpendDaily = safeToSpendMonth / 30;

  return (
    <div className="flex-1 flex flex-col px-6 pb-8">
      <div className="flex-1 flex flex-col items-center justify-center">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', stiffness: 200 }}
          className="w-20 h-20 rounded-full gradient-primary flex items-center justify-center mb-6"
        >
          <Sparkles className="w-10 h-10 text-theme-primary" />
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="text-2xl font-bold text-theme-primary text-center mb-2"
        >
          Your Safe-to-Spend
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="text-theme-secondary text-center mb-8"
        >
          Based on your income
        </motion.p>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
          className="w-full max-w-xs bg-gradient-to-br from-primary-900/90 to-primary-800/80 backdrop-blur-xl border border-primary-700/30 rounded-3xl p-6 text-theme-primary"
        >
          <div className="flex items-center gap-2 mb-4">
            <Calendar className="w-5 h-5 opacity-80" />
            <span className="text-sm opacity-80">Daily budget</span>
          </div>
          <p className="text-4xl font-bold mb-1">
            {formatCurrency(safeToSpendDaily, onboardingData.currency)}
          </p>
          <p className="text-sm opacity-80">per day, guilt-free</p>

          <div className="mt-6 pt-4 border-t border-theme-surface-border">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="w-4 h-4 opacity-80" />
              <span className="text-sm opacity-80">Monthly</span>
            </div>
            <p className="text-2xl font-semibold">
              {formatCurrency(safeToSpendMonth, onboardingData.currency)}
            </p>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="mt-6 p-4 bg-theme-surface backdrop-blur-sm border border-theme-divider rounded-2xl max-w-xs"
        >
          <p className="text-sm text-theme-secondary text-center">
            This is an estimate. We'll refine it as you add your actual bills and goals.
          </p>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7 }}
      >
        <Button onClick={onNext} fullWidth size="lg">
          Unlock Full Access
        </Button>
      </motion.div>
    </div>
  );
};
