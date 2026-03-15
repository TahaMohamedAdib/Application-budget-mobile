import React from 'react';
import { motion } from 'framer-motion';
import { Calendar, CalendarDays, CalendarRange, HelpCircle, Check } from 'lucide-react';
import { Button } from '../../ui';
import { useStore } from '../../../store/useStore';
import { PayFrequency } from '../../../types';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

const frequencies: { id: PayFrequency; label: string; description: string; icon: React.ElementType }[] = [
  { id: 'monthly', label: 'Monthly', description: 'Once a month', icon: Calendar },
  { id: 'biweekly', label: 'Biweekly', description: 'Every 2 weeks', icon: CalendarDays },
  { id: 'weekly', label: 'Weekly', description: 'Every week', icon: CalendarRange },
  { id: 'irregular', label: 'Irregular', description: 'It varies', icon: HelpCircle },
];

export const FrequencyScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const { onboardingData, updateOnboardingData } = useStore();

  const selectFrequency = (frequency: PayFrequency) => {
    updateOnboardingData({ payFrequency: frequency });
  };

  return (
    <div className="flex-1 flex flex-col px-6 pb-8">
      <div className="flex-1">
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-2xl font-bold text-theme-primary mt-8 mb-2"
        >
          How often do you get paid?
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="text-theme-secondary mb-8"
        >
          This helps us calculate your safe-to-spend
        </motion.p>

        <div className="space-y-3">
          {frequencies.map((freq, index) => {
            const Icon = freq.icon;
            const isSelected = onboardingData.payFrequency === freq.id;

            return (
              <motion.button
                key={freq.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.1 + index * 0.1 }}
                onClick={() => selectFrequency(freq.id)}
                className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all duration-200 ${
                  isSelected
                    ? 'border-gold-500 bg-gold-500/20'
                    : 'border-theme-divider bg-theme-surface/50 hover:border-theme-surface-border'
                }`}
              >
                <div className="w-12 h-12 rounded-xl bg-theme-badge flex items-center justify-center">
                  <Icon className="w-6 h-6 text-theme-secondary" />
                </div>
                <div className="flex-1 text-left">
                  <p className="font-medium text-theme-primary">{freq.label}</p>
                  <p className="text-sm text-theme-tertiary">{freq.description}</p>
                </div>
                {isSelected && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="w-6 h-6 rounded-full bg-gold-500 flex items-center justify-center"
                  >
                    <Check className="w-4 h-4 text-theme-primary" />
                  </motion.div>
                )}
              </motion.button>
            );
          })}
        </div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        <Button onClick={onNext} fullWidth size="lg">
          Continue
        </Button>
      </motion.div>
    </div>
  );
};
