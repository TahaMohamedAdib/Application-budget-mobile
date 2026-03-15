import React from 'react';
import { motion } from 'framer-motion';
import { Target, PiggyBank, TrendingUp, CreditCard, Check } from 'lucide-react';
import { Button } from '../../ui';
import { useStore } from '../../../store/useStore';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

const goals = [
  { id: 'overspending', label: 'Stop overspending', icon: Target, color: '#ef4444' },
  { id: 'yearly', label: 'Save for big yearly expenses', icon: PiggyBank, color: '#f59e0b' },
  { id: 'investing', label: 'Start investing consistently', icon: TrendingUp, color: '#B8860B' },
  { id: 'debt', label: 'Get out of debt', icon: CreditCard, color: '#8b5cf6' },
];

export const GoalsScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const { onboardingData, updateOnboardingData } = useStore();
  const selectedGoals = onboardingData.selectedGoals || [];

  const toggleGoal = (goalId: string) => {
    const newGoals = selectedGoals.includes(goalId)
      ? selectedGoals.filter((g) => g !== goalId)
      : [...selectedGoals, goalId];
    updateOnboardingData({ selectedGoals: newGoals });
  };

  return (
    <div className="flex-1 flex flex-col px-6 pb-8">
      <div className="flex-1">
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-2xl font-bold text-theme-primary mt-8 mb-2"
        >
          What do you want to fix?
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="text-theme-secondary mb-8"
        >
          Select all that apply
        </motion.p>

        <div className="space-y-3">
          {goals.map((goal, index) => {
            const Icon = goal.icon;
            const isSelected = selectedGoals.includes(goal.id);

            return (
              <motion.button
                key={goal.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.1 + index * 0.1 }}
                onClick={() => toggleGoal(goal.id)}
                className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all duration-200 ${
                  isSelected
                    ? 'border-gold-500 bg-gold-500/20'
                    : 'border-theme-divider bg-theme-surface/50 hover:border-theme-surface-border'
                }`}
              >
                <div
                  className="w-12 h-12 rounded-xl flex items-center justify-center"
                  style={{ backgroundColor: `${goal.color}20` }}
                >
                  <Icon className="w-6 h-6" style={{ color: goal.color }} />
                </div>
                <span className="flex-1 text-left font-medium text-theme-primary">
                  {goal.label}
                </span>
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
        <Button
          onClick={onNext}
          fullWidth
          size="lg"
          disabled={selectedGoals.length === 0}
        >
          Continue
        </Button>
      </motion.div>
    </div>
  );
};
