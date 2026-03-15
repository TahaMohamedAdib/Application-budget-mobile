/**
 * @file App.tsx
 * @description Main entry point for the BudgetApp application.
 * This file sets up the global structure, authentication flow, and core navigation.
 */

import React, { useState, useEffect } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { useStore } from './store/useStore';
import { ThemeProvider } from './components/ThemeProvider';
import { AuthProvider, useAuth } from './lib/AuthContext';
import { AuthScreen } from './components/auth/AuthScreen';
import { OnboardingScreen } from './components/onboarding/OnboardingScreen';
import { TodayScreen } from './components/screens/TodayScreen';
import { PlanScreen } from './components/screens/PlanScreen';
import { WealthScreen } from './components/screens/WealthScreen';
import { SettingsScreen } from './components/screens/SettingsScreen';
import { AccountsScreen } from './components/screens/AccountsScreen';
import { CoachScreen } from './components/screens/CoachScreen';
import { PortfolioScreen } from './components/screens/PortfolioScreen';
import { TransactionsScreen } from './components/screens/TransactionsScreen';
import { BottomNav } from './components/layout/BottomNav';
import { FloatingActionButton } from './components/layout/FloatingActionButton';
import { AddTransactionModal } from './components/modals/AddTransactionModal';
import { AddGoalModal } from './components/modals/AddGoalModal';
import { AddBillModal } from './components/modals/AddBillModal';
import { TransactionType } from './types';
import { Loader2, Bot } from 'lucide-react';

/**
 * ErrorBoundary component to catch runtime crashes in the component tree.
 * Displays a fallback UI and allows users to reload the application.
 */
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[ErrorBoundary]', error, info.componentStack);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to flex items-center justify-center p-6">
          <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-6 max-w-md w-full text-center">
            <h2 className="text-xl font-bold text-theme-primary mb-2">Something went wrong</h2>
            <p className="text-theme-secondary text-sm mb-4">{this.state.error?.message}</p>
            <button
              onClick={() => { this.setState({ hasError: false, error: null }); window.location.reload(); }}
              className="px-6 py-3 bg-gold-500 text-white rounded-xl font-medium"
            >
              Reload App
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

/**
 * Valid tab identifiers for the bottom navigation.
 */
type TabType = 'today' | 'plan' | 'wealth';

/**
 * Internal content component that handles the application state and UI logic.
 * Manages tab navigation, overlays (Accounts, Coach, Settings, etc.), and transaction modals.
 */
function AppContent() {
  const { user, loading } = useAuth();
  const { settings, processMonthlyWages } = useStore();

  console.log('[App] render — loading:', loading, 'user:', !!user, 'onboarding:', settings.onboardingComplete);
  const [activeTab, setActiveTab] = useState<TabType>('today');

  // Process monthly wages on app load
  useEffect(() => {
    if (settings.onboardingComplete) {
      processMonthlyWages();
    }
  }, [settings.onboardingComplete, processMonthlyWages]);

  const [modalOpen, setModalOpen] = useState(false);
  const [goalModalOpen, setGoalModalOpen] = useState(false);
  const [billModalOpen, setBillModalOpen] = useState(false);
  const [transactionType, setTransactionType] = useState<TransactionType>('expense');
  const [showAccountsScreen, setShowAccountsScreen] = useState(false);
  const [showCoachScreen, setShowCoachScreen] = useState(false);
  const [showSettingsScreen, setShowSettingsScreen] = useState(false);
  const [showPortfolioScreen, setShowPortfolioScreen] = useState(false);
  const [showTransactionsScreen, setShowTransactionsScreen] = useState(false);

  const handleAddExpense = () => {
    setTransactionType('expense');
    setModalOpen(true);
  };

  const handleAddIncome = () => {
    setTransactionType('income');
    setModalOpen(true);
  };

  const handleAddTransfer = () => {
    setTransactionType('transfer');
    setModalOpen(true);
  };

  const handleAddWithdrawal = () => {
    setTransactionType('withdrawal');
    setModalOpen(true);
  };

  const handleAddBill = () => {
    setBillModalOpen(true);
  };

  const handleAddGoal = () => {
    setGoalModalOpen(true);
  };

  const handleNavigateToPlan = () => {
    setActiveTab('plan');
  };


  // Show loading spinner while checking auth
  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-gold-500 animate-spin" />
      </div>
    );
  }

  // Show auth screen if not logged in
  if (!user) {
    return <AuthScreen />;
  }

  // Show onboarding if not complete
  if (!settings.onboardingComplete) {
    return <OnboardingScreen />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to transition-colors">
      <AnimatePresence mode="wait">
        {activeTab === 'today' && (
          <TodayScreen 
            key="today" 
            onNavigateToPlan={handleNavigateToPlan}
            onAddGoal={handleAddGoal}
            onOpenSettings={() => setShowSettingsScreen(true)}
            onNavigateToWealth={() => setActiveTab('wealth')}
            onNavigateToTransactions={() => setShowTransactionsScreen(true)}
          />
        )}
        {activeTab === 'plan' && (
          <PlanScreen 
            key="plan" 
            onAddBill={handleAddBill}
            onAddGoal={handleAddGoal}
            onOpenSettings={() => setShowSettingsScreen(true)}
          />
        )}
        {activeTab === 'wealth' && (
          <WealthScreen 
            key="wealth" 
            onManageAccounts={() => setShowAccountsScreen(true)}
            onOpenSettings={() => setShowSettingsScreen(true)}
            onOpenPortfolio={() => setShowPortfolioScreen(true)}
          />
        )}
      </AnimatePresence>

      {/* Accounts Screen Overlay */}
      {showAccountsScreen && (
        <div className="fixed inset-0 z-50">
          <AccountsScreen onBack={() => setShowAccountsScreen(false)} />
        </div>
      )}

      {/* Coach Screen Overlay */}
      {showCoachScreen && (
        <div className="fixed inset-0 z-50">
          <CoachScreen onBack={() => setShowCoachScreen(false)} />
        </div>
      )}

      {/* Settings Screen Overlay */}
      {showSettingsScreen && (
        <div className="fixed inset-0 z-50">
          <SettingsScreen onBack={() => setShowSettingsScreen(false)} />
        </div>
      )}

      {/* Portfolio Screen Overlay */}
      {showPortfolioScreen && (
        <div className="fixed inset-0 z-50">
          <PortfolioScreen onBack={() => setShowPortfolioScreen(false)} />
        </div>
      )}

      {/* Transactions Screen Overlay */}
      {showTransactionsScreen && (
        <div className="fixed inset-0 z-50">
          <TransactionsScreen onBack={() => setShowTransactionsScreen(false)} />
        </div>
      )}

      {/* Floating AI Coach Button - Left side */}
      <motion.button
        whileTap={{ scale: 0.95 }}
        onClick={() => setShowCoachScreen(true)}
        className="fixed bottom-24 left-4 z-50 w-14 h-14 rounded-full bg-gradient-to-br from-gold-600 to-gold-700 flex items-center justify-center shadow-xl border border-gold-500/30"
      >
        <Bot className="w-6 h-6 text-white" />
      </motion.button>

      <FloatingActionButton
        onAddExpense={handleAddExpense}
        onAddIncome={handleAddIncome}
        onAddTransfer={handleAddTransfer}
        onAddWithdrawal={handleAddWithdrawal}
      />

      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />

      <AddTransactionModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        type={transactionType}
      />

      <AddGoalModal
        isOpen={goalModalOpen}
        onClose={() => setGoalModalOpen(false)}
      />

      <AddBillModal
        isOpen={billModalOpen}
        onClose={() => setBillModalOpen(false)}
      />
    </div>
  );
}

/**
 * Root App component.
 * Wraps the application with necessary context providers:
 * - ErrorBoundary for safety
 * - ThemeProvider for styling
 * - AuthProvider for authentication state
 */
function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <AuthProvider>
          <AppContent />
        </AuthProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
