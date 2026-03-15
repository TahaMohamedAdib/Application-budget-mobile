import React, { useState, useRef, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Plus, Receipt, Settings } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';

type TabType = 'fixed' | 'variable' | 'sinking';

interface PlanScreenProps {
  onAddBill: () => void;
  onAddGoal: () => void;
  onOpenSettings: () => void;
}

export const PlanScreen: React.FC<PlanScreenProps> = ({ onAddBill, onAddGoal, onOpenSettings }) => {
  const { settings, goals, recurringRules } = useStore();
  const [activeTab, setActiveTab] = useState<TabType>('fixed');

  const totalPlanned = settings.monthlyIncome || 200;
  const fixedBillsCount = recurringRules.length;
  const fixedBillsTotal = recurringRules.reduce((sum, r) => sum + r.templateTransaction.amount, 0);
  const monthlyContribution = goals.reduce((sum, g) => sum + (g.targetAmount / 12), 0);

  const tabs = [
    { id: 'fixed' as TabType, label: 'Expenses' },
    { id: 'variable' as TabType, label: 'Variable Expenses' },
    { id: 'sinking' as TabType, label: 'Sinking' },
  ];

  const touchStartX = useRef(0);
  const isDragging = useRef(false);

  const handleTabSwipeStart = useCallback((e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
    isDragging.current = true;
  }, []);

  const handleTabSwipeMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging.current) return;
    const deltaX = e.touches[0].clientX - touchStartX.current;
    const threshold = 40;
    if (Math.abs(deltaX) > threshold) {
      const currentIndex = tabs.findIndex(t => t.id === activeTab);
      if (deltaX > 0 && currentIndex > 0) {
        setActiveTab(tabs[currentIndex - 1].id);
      } else if (deltaX < 0 && currentIndex < tabs.length - 1) {
        setActiveTab(tabs[currentIndex + 1].id);
      }
      isDragging.current = false;
    }
  }, [activeTab, tabs]);

  const handleTabSwipeEnd = useCallback(() => {
    isDragging.current = false;
  }, []);

  const variableCategories = [
    { id: 'groceries', name: 'Groceries', budget: 0, spent: 0 },
    { id: 'fuel', name: 'Fuel/Transport', budget: 0, spent: 0 },
    { id: 'eating-out', name: 'Eating Out', budget: 0, spent: 0 },
    { id: 'fun', name: 'Fun', budget: 0, spent: 0 },
    { id: 'other', name: 'Other', budget: 0, spent: 0 },
  ];

  return (
    <div className="flex-1 overflow-y-auto pb-24 bg-gradient-to-b from-theme-from via-theme-via to-theme-to min-h-screen transition-colors">
      {/* Header */}
      <div className="px-4 pt-6 pb-4 safe-area-top">
        <div className="flex items-center justify-between">
          <motion.h1
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-2xl font-bold text-theme-primary"
          >
            Monthly Plan
          </motion.h1>
          <button
            onClick={onOpenSettings}
            className="w-9 h-9 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center"
          >
            <Settings className="w-4 h-4 text-theme-secondary" />
          </button>
        </div>
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="text-theme-secondary"
        >
          Total planned: {formatCurrency(totalPlanned, settings.currency)}/mo
        </motion.p>
      </div>

      {/* Tabs */}
      <div className="px-4 mb-4">
        <div
          onTouchStart={handleTabSwipeStart}
          onTouchMove={handleTabSwipeMove}
          onTouchEnd={handleTabSwipeEnd}
          style={{
            display: 'flex',
            borderRadius: '22px',
            background: 'rgba(40, 50, 70, 0.55)',
            backdropFilter: 'blur(50px) saturate(180%)',
            WebkitBackdropFilter: 'blur(50px) saturate(180%)',
            border: '0.5px solid rgba(255, 255, 255, 0.15)',
            boxShadow: '0 2px 20px rgba(0, 0, 0, 0.2)',
            padding: '4px',
          }}
        >
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                style={{
                  position: 'relative',
                  flex: 1,
                  padding: '7px 8px',
                  border: 'none',
                  background: 'none',
                  cursor: 'pointer',
                  WebkitTapHighlightColor: 'transparent',
                  fontSize: '13px',
                  fontWeight: 600,
                  color: isActive ? '#ffffff' : 'rgba(255, 255, 255, 0.45)',
                  transition: 'color 0.2s ease',
                  zIndex: 1,
                }}
              >
                {isActive && (
                  <motion.div
                    layoutId="planTabCapsule"
                    style={{
                      position: 'absolute',
                      inset: '0',
                      borderRadius: '18px',
                      background: 'rgba(184, 134, 11, 0.9)',
                      boxShadow: '0 4px 12px rgba(184, 134, 11, 0.3)',
                    }}
                    transition={{
                      type: 'spring',
                      stiffness: 350,
                      damping: 30,
                    }}
                  />
                )}
                <span style={{ position: 'relative', zIndex: 1 }}>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      <div className="px-4 space-y-3">
        {/* Fixed Bills Tab */}
        {activeTab === 'fixed' && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-3"
          >
            <div className="flex items-center justify-between">
              <p className="text-theme-tertiary text-sm">
                {fixedBillsCount} expenses · {formatCurrency(fixedBillsTotal, settings.currency)}/mo
              </p>
              <button onClick={onAddBill} className="text-gold-400 text-sm font-medium flex items-center gap-1">
                <Plus className="w-4 h-4" /> Add
              </button>
            </div>

            {recurringRules.length > 0 ? (
              recurringRules.map((rule) => (
                <div key={rule.id} className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-gray-700 flex items-center justify-center">
                      <Receipt className="w-6 h-6 text-gray-400" />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-theme-primary">{rule.templateTransaction.note || 'Bill'}</p>
                      <p className="text-sm text-theme-tertiary">
                        Due {new Date(rule.nextDate).getDate()}th · {rule.cadence}
                      </p>
                    </div>
                    <p className="font-semibold text-theme-primary">
                      {formatCurrency(rule.templateTransaction.amount, settings.currency)}
                    </p>
                  </div>
                </div>
              ))
            ) : (
              <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-8 text-center">
                <div className="w-16 h-16 rounded-2xl bg-theme-badge flex items-center justify-center mx-auto mb-4">
                  <Receipt className="w-8 h-8 text-theme-tertiary" />
                </div>
                <p className="text-theme-tertiary mb-4">No fixed expenses added yet</p>
                <button onClick={onAddBill} className="px-6 py-3 bg-gold-500 text-white rounded-xl font-medium">
                  Add your first expense
                </button>
              </div>
            )}
          </motion.div>
        )}

        {/* Variable Spending Tab */}
        {activeTab === 'variable' && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-3"
          >
            <div className="flex items-center justify-between">
              <p className="text-theme-tertiary text-sm">Monthly limit: {formatCurrency(0, settings.currency)}</p>
            </div>

            {variableCategories.map((category) => (
              <div key={category.id} className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <p className="font-medium text-theme-primary">{category.name}</p>
                  <p className="text-theme-tertiary text-sm">
                    {formatCurrency(category.spent, settings.currency)} / {formatCurrency(category.budget, settings.currency)}
                  </p>
                </div>
                <div className="h-2 bg-theme-badge rounded-full overflow-hidden mb-1">
                  <div 
                    className="h-full bg-gold-500 rounded-full"
                    style={{ width: category.budget > 0 ? `${(category.spent / category.budget) * 100}%` : '0%' }}
                  />
                </div>
                <p className="text-theme-tertiary text-xs">{formatCurrency(0, settings.currency)} over budget</p>
              </div>
            ))}
          </motion.div>
        )}

        {/* Sinking Funds Tab */}
        {activeTab === 'sinking' && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-3"
          >
            <div className="flex items-center justify-between">
              <p className="text-theme-tertiary text-sm">
                Monthly contribution: {formatCurrency(monthlyContribution, settings.currency)}
              </p>
              <button onClick={onAddGoal} className="text-gold-400 text-sm font-medium flex items-center gap-1">
                <Plus className="w-4 h-4" /> Add
              </button>
            </div>

            {goals.length > 0 ? (
              goals.map((goal) => {
                const progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0;
                const goalMonthly = goal.targetAmount / 12;
                
                return (
                  <div key={goal.id} className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
                    <div className="flex items-center gap-3 mb-3">
                      <div 
                        className="w-10 h-10 rounded-full flex items-center justify-center text-xl"
                        style={{ backgroundColor: `${goal.color}20` }}
                      >
                        {goal.icon || '🎯'}
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-theme-primary">{goal.name}</p>
                        <p className="text-sm text-theme-tertiary">
                          {formatCurrency(goalMonthly, settings.currency)}/mo
                        </p>
                      </div>
                      <span className="text-gold-400 font-semibold">{Math.round(progress)}%</span>
                    </div>
                    <div className="h-2 bg-theme-badge rounded-full overflow-hidden mb-2">
                      <div 
                        className="h-full rounded-full transition-all"
                        style={{ 
                          width: `${Math.min(progress, 100)}%`,
                          backgroundColor: goal.color || '#B8860B'
                        }}
                      />
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-theme-tertiary">{formatCurrency(goal.currentAmount, settings.currency)} saved</span>
                      <span className="text-theme-tertiary">{formatCurrency(goal.targetAmount, settings.currency)} goal</span>
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="space-y-3">
                {['Car/Repairs', 'Gifts', 'Emergency Fund', 'Vacation'].map((name) => (
                  <div key={name} className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 rounded-full bg-amber-500/20 flex items-center justify-center text-xl">
                        🎯
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-theme-primary">{name}</p>
                        <p className="text-sm text-theme-tertiary">$0/mo</p>
                      </div>
                      <span className="text-theme-tertiary font-semibold">0%</span>
                    </div>
                    <div className="h-2 bg-theme-badge rounded-full overflow-hidden mb-2">
                      <div className="h-full bg-gold-500 rounded-full" style={{ width: '0%' }} />
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-theme-tertiary">$0 saved</span>
                      <span className="text-theme-tertiary">$1 goal</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </motion.div>
        )}
      </div>
    </div>
  );
};
