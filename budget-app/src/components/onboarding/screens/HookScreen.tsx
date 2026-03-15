import React from 'react';
import { motion } from 'framer-motion';
import { TrendingDown, CreditCard, Calendar, DollarSign } from 'lucide-react';
import { Button } from '../../ui';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

export const HookScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const painPoints = [
    { icon: CreditCard, text: 'Unexpected bills drain your account', delay: 0.5 },
    { icon: Calendar, text: 'Yearly expenses catch you off guard', delay: 0.6 },
    { icon: DollarSign, text: 'No idea how much you can actually spend', delay: 0.7 },
  ];

  return (
    <div className="flex-1 flex flex-col px-6 pb-8">
      <div className="flex-1 flex flex-col items-center justify-center text-center">
        <motion.div
          initial={{ scale: 0, rotate: -180 }}
          animate={{ scale: 1, rotate: 0 }}
          transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
          className="w-28 h-28 rounded-full bg-gradient-to-br from-red-500 to-red-600 flex items-center justify-center mb-8 shadow-xl shadow-red-500/30"
        >
          <TrendingDown className="w-14 h-14 text-theme-primary" />
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="text-4xl font-bold text-theme-primary mb-3 leading-tight"
        >
          78% of people
          <br />
          <span className="text-red-500">overspend monthly</span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="text-lg text-theme-secondary max-w-xs mb-8"
        >
          They don't know what's truly{' '}
          <span className="font-bold text-gold-400">safe to spend</span> each day.
        </motion.p>

        <div className="w-full max-w-sm space-y-3">
          {painPoints.map((point, index) => {
            const Icon = point.icon;
            return (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: point.delay }}
                className="flex items-center gap-4 p-4 bg-theme-surface backdrop-blur-sm border border-theme-surface-border rounded-2xl"
              >
                <div className="w-10 h-10 rounded-xl bg-red-100 dark:bg-red-900/30 flex items-center justify-center flex-shrink-0">
                  <Icon className="w-5 h-5 text-red-500" />
                </div>
                <p className="text-sm font-medium text-theme-primary text-left">
                  {point.text}
                </p>
              </motion.div>
            );
          })}
        </div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.9 }}
        className="space-y-3"
      >
        <Button onClick={onNext} fullWidth size="lg">
          I want to fix this →
        </Button>
        <p className="text-center text-xs text-theme-tertiary">
          Join 50,000+ people who took control of their money
        </p>
      </motion.div>
    </div>
  );
};
