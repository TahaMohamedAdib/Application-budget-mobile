import React from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Wallet, Receipt, PiggyBank, Sparkles } from 'lucide-react';
import { Button } from '../../ui';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

export const AhaScreen: React.FC<ScreenProps> = ({ onNext }) => {
  const steps = [
    { icon: Wallet, label: 'Income', color: '#B8860B' },
    { icon: Receipt, label: 'Expenses', color: '#ef4444' },
    { icon: PiggyBank, label: 'Savings', color: '#f59e0b' },
    { icon: Sparkles, label: 'Safe to Spend', color: '#8b5cf6' },
  ];

  return (
    <div className="flex-1 flex flex-col px-6 pb-8">
      <div className="flex-1 flex flex-col items-center justify-center">
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-2xl font-bold text-theme-primary text-center mb-2"
        >
          Here's how it works
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="text-theme-secondary text-center mb-12"
        >
          Simple math, powerful results
        </motion.p>

        <div className="flex flex-col items-center gap-4 w-full max-w-xs">
          {steps.map((step, index) => {
            const Icon = step.icon;
            return (
              <React.Fragment key={step.label}>
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.2 + index * 0.15 }}
                  className="flex items-center gap-4 w-full"
                >
                  <div
                    className="w-14 h-14 rounded-2xl flex items-center justify-center"
                    style={{ backgroundColor: `${step.color}20` }}
                  >
                    <Icon className="w-7 h-7" style={{ color: step.color }} />
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-theme-primary">{step.label}</p>
                    {index === 0 && <p className="text-sm text-theme-tertiary">What you earn</p>}
                    {index === 1 && <p className="text-sm text-theme-tertiary">Fixed expenses</p>}
                    {index === 2 && <p className="text-sm text-theme-tertiary">Goals & future</p>}
                    {index === 3 && <p className="text-sm text-theme-tertiary">What's left for you</p>}
                  </div>
                  {index === 0 && (
                    <span className="text-lg font-bold text-gold-400">+</span>
                  )}
                  {(index === 1 || index === 2) && (
                    <span className="text-lg font-bold text-red-500">−</span>
                  )}
                  {index === 3 && (
                    <span className="text-lg font-bold text-gold-400">=</span>
                  )}
                </motion.div>
                {index < steps.length - 1 && (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 0.3 + index * 0.15 }}
                  >
                    <ArrowRight className="w-5 h-5 text-theme-tertiary rotate-90" />
                  </motion.div>
                )}
              </React.Fragment>
            );
          })}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="mt-10 p-4 bg-gold-500/10 rounded-2xl border border-gold-500/20 max-w-xs"
        >
          <p className="text-sm text-gold-400 text-center">
            <span className="font-semibold">The result:</span> You'll always know exactly what you can spend without guilt.
          </p>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.9 }}
      >
        <Button onClick={onNext} fullWidth size="lg">
          Let's set it up
        </Button>
      </motion.div>
    </div>
  );
};
