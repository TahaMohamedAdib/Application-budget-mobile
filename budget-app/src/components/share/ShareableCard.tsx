import React from 'react';
import { motion } from 'framer-motion';
import { Share2, Sparkles, PiggyBank, TrendingUp } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';

type CardType = 'daily-spend' | 'monthly-saved' | 'goal-progress';

interface ShareableCardProps {
  type: CardType;
  onShare?: () => void;
}

export const ShareableCard: React.FC<ShareableCardProps> = ({ type, onShare }) => {
  const { settings, getSafeToSpendToday, goals } = useStore();
  const safeToSpendToday = getSafeToSpendToday();
  const topGoal = goals[0];

  const handleShare = () => {
    if (onShare) {
      onShare();
    }
  };

  if (type === 'daily-spend') {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-gradient-to-br from-primary-500 to-primary-600 rounded-3xl p-6 text-theme-primary shadow-xl relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-32 h-32 bg-theme-badge rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-0 w-24 h-24 bg-theme-badge rounded-full translate-y-1/2 -translate-x-1/2" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-4">
            <Sparkles className="w-5 h-5" />
            <span className="text-sm font-medium opacity-90">SafeSpend</span>
          </div>
          
          <p className="text-sm opacity-80 mb-1">I can spend</p>
          <p className="text-4xl font-bold mb-2">
            {formatCurrency(safeToSpendToday, settings.currency)}
          </p>
          <p className="text-sm opacity-80">per day, guilt-free</p>
          
          <button
            onClick={handleShare}
            className="mt-6 flex items-center gap-2 bg-white/20 hover:bg-white/30 transition-colors px-4 py-2 rounded-xl text-sm font-medium"
          >
            <Share2 className="w-4 h-4" />
            Share
          </button>
        </div>
      </motion.div>
    );
  }

  if (type === 'monthly-saved') {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-3xl p-6 text-theme-primary shadow-xl relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-32 h-32 bg-theme-badge rounded-full -translate-y-1/2 translate-x-1/2" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-4">
            <PiggyBank className="w-5 h-5" />
            <span className="text-sm font-medium opacity-90">Monthly Savings</span>
          </div>
          
          <p className="text-sm opacity-80 mb-1">This month I saved</p>
          <p className="text-4xl font-bold mb-2">
            {formatCurrency(settings.monthlyIncome * 0.15, settings.currency)}
          </p>
          <p className="text-sm opacity-80">towards my goals</p>
          
          <button
            onClick={handleShare}
            className="mt-6 flex items-center gap-2 bg-white/20 hover:bg-white/30 transition-colors px-4 py-2 rounded-xl text-sm font-medium"
          >
            <Share2 className="w-4 h-4" />
            Share
          </button>
        </div>
      </motion.div>
    );
  }

  if (type === 'goal-progress' && topGoal) {
    const progress = (topGoal.currentAmount / topGoal.targetAmount) * 100;
    
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-gradient-to-br from-violet-500 to-purple-600 rounded-3xl p-6 text-theme-primary shadow-xl relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-32 h-32 bg-theme-badge rounded-full -translate-y-1/2 translate-x-1/2" />
        
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="w-5 h-5" />
            <span className="text-sm font-medium opacity-90">Goal Progress</span>
          </div>
          
          <p className="text-sm opacity-80 mb-1">{topGoal.name}</p>
          <p className="text-4xl font-bold mb-2">{Math.round(progress)}%</p>
          <p className="text-sm opacity-80">
            {formatCurrency(topGoal.currentAmount, settings.currency)} of {formatCurrency(topGoal.targetAmount, settings.currency)}
          </p>
          
          <div className="mt-4 h-2 bg-white/20 rounded-full overflow-hidden">
            <div
              className="h-full bg-white rounded-full transition-all duration-500"
              style={{ width: `${Math.min(100, progress)}%` }}
            />
          </div>
          
          <button
            onClick={handleShare}
            className="mt-6 flex items-center gap-2 bg-white/20 hover:bg-white/30 transition-colors px-4 py-2 rounded-xl text-sm font-medium"
          >
            <Share2 className="w-4 h-4" />
            Share
          </button>
        </div>
      </motion.div>
    );
  }

  return null;
};
