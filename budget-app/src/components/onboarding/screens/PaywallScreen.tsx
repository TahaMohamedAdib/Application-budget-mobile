import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Check, Shield, Sparkles, Star, Clock, Zap, Calendar, TrendingUp, Layers, Share2 } from 'lucide-react';
import { Button } from '../../ui';
import { useStore } from '../../../store/useStore';

interface ScreenProps {
  onNext: () => void;
  onBack: () => void;
}

export const PaywallScreen: React.FC<ScreenProps> = () => {
  const { completeOnboarding } = useStore();
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly');
  const [timeLeft, setTimeLeft] = useState({ minutes: 14, seconds: 59 });

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev.seconds > 0) {
          return { ...prev, seconds: prev.seconds - 1 };
        } else if (prev.minutes > 0) {
          return { minutes: prev.minutes - 1, seconds: 59 };
        }
        return prev;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const handleSubscribe = () => {
    completeOnboarding();
  };

  const features = [
    { text: 'Know exactly what you can spend daily', icon: Zap },
    { text: 'Never forget yearly expenses again', icon: Calendar },
    { text: 'Track net worth & investments', icon: TrendingUp },
    { text: 'Unlimited accounts & categories', icon: Layers },
    { text: 'Beautiful shareable insights', icon: Share2 },
  ];

  const testimonials = [
    { name: 'Sarah M.', text: 'Finally stopped living paycheck to paycheck!', rating: 5 },
    { name: 'James K.', text: 'Saved $3,000 in my first 3 months', rating: 5 },
    { name: 'Emily R.', text: 'The daily safe-to-spend changed everything', rating: 5 },
  ];

  const [currentTestimonial, setCurrentTestimonial] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTestimonial(prev => (prev + 1) % testimonials.length);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex-1 flex flex-col px-6 pb-8 overflow-y-auto">
      <div className="flex-1">
        {/* Urgency Banner */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-4 mb-6 p-3 bg-gradient-to-r from-amber-500 to-orange-500 rounded-2xl text-theme-primary text-center"
        >
          <div className="flex items-center justify-center gap-2">
            <Clock className="w-4 h-4" />
            <span className="text-sm font-semibold">
              Special offer ends in {timeLeft.minutes}:{timeLeft.seconds.toString().padStart(2, '0')}
            </span>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-6"
        >
          <motion.div 
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200 }}
            className="inline-flex items-center gap-2 px-4 py-2 bg-gold-500/15 rounded-full mb-4"
          >
            <Sparkles className="w-4 h-4 text-gold-400" />
            <span className="text-sm font-medium text-gold-400">7-day FREE trial</span>
          </motion.div>
          <h1 className="text-3xl font-bold text-theme-primary mb-2">
            Unlock Your
            <br />
            <span className="text-gold-400">Financial Freedom</span>
          </h1>
          <p className="text-theme-secondary">
            Join 50,000+ people who transformed their finances
          </p>
        </motion.div>

        {/* Social Proof */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="flex items-center justify-center gap-2 mb-6"
        >
          <div className="flex -space-x-2">
            {[1, 2, 3, 4, 5].map((i) => (
              <div
                key={i}
                className="w-8 h-8 rounded-full bg-gradient-to-br from-gold-400 to-gold-600 border-2 border-gold-900 flex items-center justify-center text-theme-primary text-xs font-bold"
              >
                {String.fromCharCode(64 + i)}
              </div>
            ))}
          </div>
          <div className="flex items-center gap-1">
            {[1, 2, 3, 4, 5].map((i) => (
              <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
            ))}
          </div>
          <span className="text-sm text-theme-secondary">4.9 (12k+ reviews)</span>
        </motion.div>

        {/* Testimonial Carousel */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 }}
          className="mb-6 h-20 relative overflow-hidden"
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={currentTestimonial}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="absolute inset-0 p-4 bg-theme-surface backdrop-blur-sm border border-theme-surface-border rounded-2xl"
            >
              <div className="flex items-center gap-1 mb-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <Star key={i} className="w-3 h-3 fill-amber-400 text-amber-400" />
                ))}
              </div>
              <p className="text-sm text-theme-primary italic">"{testimonials[currentTestimonial].text}"</p>
              <p className="text-xs text-theme-tertiary mt-1">— {testimonials[currentTestimonial].name}</p>
            </motion.div>
          </AnimatePresence>
        </motion.div>

        {/* Plan selection */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="space-y-3 mb-6"
        >
          <button
            onClick={() => setSelectedPlan('yearly')}
            className={`w-full p-4 rounded-2xl border-2 transition-all duration-200 relative ${
              selectedPlan === 'yearly'
                ? 'border-gold-500 bg-gold-500/20'
                : 'border-theme-divider bg-theme-surface/50'
            }`}
          >
            <div className="absolute -top-3 left-4 px-2 py-0.5 bg-gold-500 text-white text-xs font-medium rounded-full">
              BEST VALUE
            </div>
            <div className="flex items-center justify-between">
              <div className="text-left">
                <p className="font-semibold text-theme-primary">Yearly</p>
                <p className="text-sm text-theme-tertiary">$39.99/year</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-theme-primary">$3.33</p>
                <p className="text-sm text-theme-tertiary">/month</p>
              </div>
            </div>
            <div className="mt-2 text-sm text-gold-400 font-medium">
              Save 58% vs monthly
            </div>
          </button>

          <button
            onClick={() => setSelectedPlan('monthly')}
            className={`w-full p-4 rounded-2xl border-2 transition-all duration-200 ${
              selectedPlan === 'monthly'
                ? 'border-gold-500 bg-gold-500/20'
                : 'border-theme-divider bg-theme-surface/50'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="text-left">
                <p className="font-semibold text-theme-primary">Monthly</p>
                <p className="text-sm text-theme-tertiary">Billed monthly</p>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-theme-primary">$7.99</p>
                <p className="text-sm text-theme-tertiary">/month</p>
              </div>
            </div>
          </button>
        </motion.div>

        {/* Features */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-6"
        >
          <p className="text-sm font-medium text-theme-secondary mb-3">What you get:</p>
          <div className="space-y-2">
            {features.map((feature, index) => (
              <div key={index} className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full bg-gold-500/20 flex items-center justify-center">
                  <Check className="w-3 h-3 text-gold-400" />
                </div>
                <span className="text-sm text-theme-secondary">{feature.text}</span>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Guarantee */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="p-4 bg-theme-surface backdrop-blur-sm border border-theme-divider rounded-2xl flex items-start gap-3"
        >
          <Shield className="w-5 h-5 text-theme-secondary mt-0.5" />
          <div>
            <p className="text-sm font-medium text-theme-primary">100% Money-back guarantee</p>
            <p className="text-xs text-theme-secondary">
              Not happy? Get a full refund within 30 days, no questions asked.
            </p>
          </div>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="mt-6 space-y-3"
      >
        <Button onClick={handleSubscribe} fullWidth size="lg">
          Start Free Trial
        </Button>
        <p className="text-xs text-center text-theme-tertiary">
          Cancel anytime. No commitment required.
        </p>
      </motion.div>
    </div>
  );
};
