import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Crown, CreditCard, Bot, TrendingUp, Check } from 'lucide-react';
import { useStore } from '../../store/useStore';

interface VipUpgradeModalProps {
  isOpen: boolean;
  onClose: () => void;
  feature?: 'accounts' | 'coach' | 'portfolio';
}

export const VipUpgradeModal: React.FC<VipUpgradeModalProps> = ({ isOpen, onClose, feature = 'accounts' }) => {
  const { updateSettings } = useStore();

  const features = [
    { icon: CreditCard, label: 'Unlimited bank accounts', included: true },
    { icon: Bot, label: 'AI Coach (spend less + invest smarter)', included: true },
    { icon: TrendingUp, label: 'Portfolio tracking (Compte Titres)', included: true },
  ];

  const getTitle = () => {
    switch (feature) {
      case 'accounts': return 'Add More Accounts';
      case 'coach': return 'Unlock AI Coach';
      case 'portfolio': return 'Track Your Portfolio';
      default: return 'Upgrade to VIP';
    }
  };

  const getDescription = () => {
    switch (feature) {
      case 'accounts': return 'Free users can add up to 2 bank accounts. Upgrade to VIP for unlimited accounts.';
      case 'coach': return 'Get personalized advice on spending less and investing smarter with our AI Coach.';
      case 'portfolio': return 'Track your stock portfolio (Compte Titres) with real-time delayed quotes.';
      default: return 'Unlock all premium features with VIP.';
    }
  };

  const handleUpgrade = () => {
    // In a real app, this would trigger a payment flow
    // For now, we'll just upgrade the user directly for demo purposes
    updateSettings({ subscriptionTier: 'VIP' });
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
                <div className="flex items-center gap-2">
                  <Crown className="w-6 h-6 text-amber-500" />
                  <h2 className="text-lg font-semibold text-theme-primary">VIP</h2>
                </div>
                <div className="w-10" />
              </div>

              {/* Icon */}
              <div className="flex justify-center mb-6">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', stiffness: 200, delay: 0.1 }}
                  className="w-24 h-24 bg-gradient-to-br from-amber-400 to-amber-600 rounded-3xl flex items-center justify-center shadow-lg"
                >
                  <Crown className="w-12 h-12 text-theme-primary" />
                </motion.div>
              </div>

              {/* Title & Description */}
              <div className="text-center mb-8">
                <h3 className="text-2xl font-bold text-theme-primary mb-2">
                  {getTitle()}
                </h3>
                <p className="text-theme-secondary">
                  {getDescription()}
                </p>
              </div>

              {/* Features List */}
              <div className="bg-theme-surface backdrop-blur-sm border border-theme-divider rounded-2xl p-4 mb-6">
                <p className="text-sm font-medium text-theme-tertiary mb-3">VIP includes:</p>
                <div className="space-y-3">
                  {features.map((feat, index) => {
                    const Icon = feat.icon;
                    return (
                      <motion.div
                        key={feat.label}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.2 + index * 0.1 }}
                        className="flex items-center gap-3"
                      >
                        <div className="w-10 h-10 bg-amber-500/10 rounded-xl flex items-center justify-center">
                          <Icon className="w-5 h-5 text-amber-500" />
                        </div>
                        <span className="flex-1 text-theme-primary font-medium">
                          {feat.label}
                        </span>
                        <Check className="w-5 h-5 text-gold-500" />
                      </motion.div>
                    );
                  })}
                </div>
              </div>

              {/* Pricing */}
              <div className="text-center mb-6">
                <div className="flex items-baseline justify-center gap-1">
                  <span className="text-4xl font-bold text-theme-primary">$9.99</span>
                  <span className="text-theme-tertiary">/month</span>
                </div>
                <p className="text-sm text-theme-tertiary mt-1">Cancel anytime</p>
              </div>

              {/* CTA Buttons */}
              <div className="space-y-3">
                <button
                  onClick={handleUpgrade}
                  className="w-full py-4 bg-gradient-to-r from-amber-500 to-amber-600 text-theme-primary font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all"
                >
                  Upgrade to VIP
                </button>
                <button
                  onClick={onClose}
                  className="w-full py-4 bg-theme-badge text-theme-secondary font-medium rounded-xl"
                >
                  Cancel
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
