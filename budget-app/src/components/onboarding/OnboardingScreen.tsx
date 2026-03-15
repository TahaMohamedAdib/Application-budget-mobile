import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useStore } from '../../store/useStore';
import { HookScreen } from './screens/HookScreen';
import { GoalsScreen } from './screens/GoalsScreen';
import { FrequencyScreen } from './screens/FrequencyScreen';
import { AhaScreen } from './screens/AhaScreen';
import { SetupScreen } from './screens/SetupScreen';
import { PreviewScreen } from './screens/PreviewScreen';
import { PaywallScreen } from './screens/PaywallScreen';

const screens = [
  HookScreen,
  GoalsScreen,
  FrequencyScreen,
  AhaScreen,
  SetupScreen,
  PreviewScreen,
  PaywallScreen,
];

export const OnboardingScreen: React.FC = () => {
  const { onboardingStep, setOnboardingStep } = useStore();

  const CurrentScreen = screens[onboardingStep];

  const handleNext = () => {
    if (onboardingStep < screens.length - 1) {
      setOnboardingStep(onboardingStep + 1);
    }
  };

  const handleBack = () => {
    if (onboardingStep > 0) {
      setOnboardingStep(onboardingStep - 1);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to flex flex-col">
      {/* Progress indicator */}
      <div className="px-6 pt-6 safe-area-top">
        <div className="flex gap-1.5">
          {screens.map((_, index) => (
            <div
              key={index}
              className={`h-1 flex-1 rounded-full transition-all duration-300 ${
                index <= onboardingStep ? 'bg-gold-500' : 'bg-theme-surface-hover'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Screen content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={onboardingStep}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
          transition={{ duration: 0.3 }}
          className="flex-1 flex flex-col"
        >
          <CurrentScreen onNext={handleNext} onBack={handleBack} />
        </motion.div>
      </AnimatePresence>
    </div>
  );
};
