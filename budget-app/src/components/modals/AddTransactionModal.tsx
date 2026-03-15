import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Check, Wallet, Building2, PiggyBank, TrendingDown } from 'lucide-react';
import { Button } from '../ui';
import { useStore } from '../../store/useStore';
import { TransactionType } from '../../types';

interface AddTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  type: TransactionType;
}

export const AddTransactionModal: React.FC<AddTransactionModalProps> = ({
  isOpen,
  onClose,
  type: initialType,
}) => {
  const { accounts, addTransaction, settings } = useStore();
  const [activeTab, setActiveTab] = useState<TransactionType>(initialType);

  // Sync activeTab when the modal opens with a different type
  useEffect(() => {
    if (isOpen) {
      setActiveTab(initialType);
    }
  }, [isOpen, initialType]);
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [selectedAccount, setSelectedAccount] = useState(accounts[0]?.id || '');
  const [toAccount, setToAccount] = useState('');
  const [isExternalTransfer, setIsExternalTransfer] = useState(false);
  const [externalRecipient, setExternalRecipient] = useState('');
  const [manualFee, setManualFee] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'bank' | 'cash'>('bank');

  const quickAmounts = [5, 10, 20, 50, 100];

  const expenseCategories = [
    { id: 'rent', name: 'Rent/House' },
    { id: 'utilities', name: 'Utilities' },
    { id: 'phone', name: 'Phone/Internet' },
    { id: 'subscriptions', name: 'Subscriptions' },
    { id: 'insurance', name: 'Insurance' },
    { id: 'loans', name: 'Loans' },
    { id: 'groceries', name: 'Groceries' },
    { id: 'fuel', name: 'Fuel/Transport' },
    { id: 'eating-out', name: 'Eating Out' },
    { id: 'shopping', name: 'Shopping' },
    { id: 'health', name: 'Health' },
    { id: 'fun', name: 'Fun' },
    { id: 'other', name: 'Other' },
  ];

  const transferCategories = [
    { id: 'to-friend', name: 'To Friend/Family' },
    { id: 'to-own-account', name: 'Own Account' },
    { id: 'emergency-fund', name: 'Emergency Fund' },
    { id: 'investing', name: 'Investing' },
  ];

  const categories = activeTab === 'expense' 
    ? expenseCategories 
    : activeTab === 'transfer' 
    ? transferCategories 
    : [];

  const feeValue = parseFloat(manualFee) || 0;

  const handleSubmit = () => {
    if (!amount || parseFloat(amount) <= 0) return;

    if (activeTab === 'withdrawal') {
      // Withdrawal: deduct from bank, add to cash
      addTransaction({
        date: new Date().toISOString(),
        amount: parseFloat(amount),
        type: 'withdrawal',
        accountId: selectedAccount,
        note: note || 'Bank withdrawal',
        feeAmount: feeValue > 0 ? feeValue : undefined,
      });
    } else if (activeTab === 'transfer') {
      addTransaction({
        date: new Date().toISOString(),
        amount: parseFloat(amount),
        type: 'transfer',
        accountId: selectedAccount,
        toAccountId: isExternalTransfer ? undefined : (toAccount || undefined),
        categoryId: selectedCategory || undefined,
        note: isExternalTransfer ? (externalRecipient ? `Transfer to ${externalRecipient}` : note || undefined) : (note || undefined),
        feeAmount: feeValue > 0 ? feeValue : undefined,
      });
    } else if (activeTab === 'expense' && paymentMethod === 'cash') {
      // Cash payment: deduct from totalCash, not from bank account
      addTransaction({
        date: new Date().toISOString(),
        amount: parseFloat(amount),
        type: activeTab,
        accountId: 'cash',
        categoryId: selectedCategory || undefined,
        note: note || undefined,
      });
    } else {
      addTransaction({
        date: new Date().toISOString(),
        amount: parseFloat(amount),
        type: activeTab,
        accountId: selectedAccount,
        categoryId: selectedCategory || undefined,
        note: note || undefined,
      });
    }

    setAmount('');
    setNote('');
    setSelectedCategory('');
    setManualFee('');
    setExternalRecipient('');
    setIsExternalTransfer(false);
    setToAccount('');
    setPaymentMethod('bank');
    onClose();
  };

  const getCurrencySymbol = () => {
    switch (settings.currency) {
      case 'USD': return '$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$';
    }
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
                <button
                  onClick={onClose}
                  className="w-10 h-10 rounded-full flex items-center justify-center"
                >
                  <X className="w-6 h-6 text-theme-secondary" />
                </button>
                <h2 className="text-lg font-semibold text-theme-primary">
                  {activeTab === 'expense' ? 'Add Expense' : activeTab === 'income' ? 'Add Income' : activeTab === 'withdrawal' ? 'Withdrawal' : 'Transfer'}
                </h2>
                <button
                  onClick={handleSubmit}
                  disabled={!amount || parseFloat(amount) <= 0}
                  className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <Check className={`w-5 h-5 ${amount && parseFloat(amount) > 0 ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                </button>
              </div>

              {/* Tabs */}
              <div className="flex bg-theme-badge border border-theme-divider rounded-full p-1 mb-6">
                {(['expense', 'income', 'transfer', 'withdrawal'] as TransactionType[]).map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`flex-1 py-2 rounded-full text-xs font-medium transition-all ${
                      activeTab === tab
                        ? 'bg-gold-500 text-white shadow-lg shadow-gold-500/30'
                        : 'text-theme-secondary'
                    }`}
                  >
                    {tab === 'withdrawal' ? 'Withdraw' : tab.charAt(0).toUpperCase() + tab.slice(1)}
                  </button>
                ))}
              </div>

              {/* Amount Display */}
              <div className="text-center mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Amount</p>
                <div className="flex items-center justify-center gap-1">
                  <span className="text-3xl text-theme-tertiary">{getCurrencySymbol()}</span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    className="text-5xl font-bold text-theme-primary bg-transparent border-none outline-none text-center w-40"
                  />
                </div>
              </div>

              {/* Quick Amount Buttons */}
              <div className="flex justify-center gap-2 mb-6">
                {quickAmounts.map((quickAmount) => (
                  <button
                    key={quickAmount}
                    onClick={() => setAmount(quickAmount.toString())}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                      amount === quickAmount.toString()
                        ? 'bg-gold-500 text-white'
                        : 'bg-theme-badge text-theme-secondary'
                    }`}
                  >
                    {getCurrencySymbol()}{quickAmount}
                  </button>
                ))}
              </div>

              {/* Payment Method for Expense */}
              {activeTab === 'expense' && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-3">Payment Method</p>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setPaymentMethod('bank')}
                      className={`flex-1 p-3 rounded-xl flex items-center justify-center gap-2 text-sm font-medium transition-all ${
                        paymentMethod === 'bank'
                          ? 'bg-blue-500/15 border-2 border-blue-500 text-blue-400'
                          : 'bg-theme-badge border-2 border-transparent text-theme-secondary'
                      }`}
                    >
                      <Building2 className="w-4 h-4" />
                      Bank Transfer
                    </button>
                    <button
                      onClick={() => setPaymentMethod('cash')}
                      className={`flex-1 p-3 rounded-xl flex items-center justify-center gap-2 text-sm font-medium transition-all ${
                        paymentMethod === 'cash'
                          ? 'bg-gold-500/15 border-2 border-gold-500 text-gold-400'
                          : 'bg-theme-badge border-2 border-transparent text-theme-secondary'
                      }`}
                    >
                      <Wallet className="w-4 h-4" />
                      Cash
                    </button>
                  </div>
                </div>
              )}

              {/* Payment Source */}
              {!(activeTab === 'expense' && paymentMethod === 'cash') && (
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-3">
                  {activeTab === 'transfer' ? 'From Account' : activeTab === 'income' ? 'Deposit To' : activeTab === 'withdrawal' ? 'Withdraw From' : 'Pay From'}
                </p>
                <div className="space-y-2">
                  {accounts
                    .filter((account) => {
                      // For withdrawal, only show bank/savings accounts
                      if (activeTab === 'withdrawal') return account.type === 'bank' || account.type === 'savings';
                      // For transfer, only show bank/savings (not debt/investment)
                      if (activeTab === 'transfer') return account.type === 'bank' || account.type === 'savings';
                      return true;
                    })
                    .map((account) => {
                    const iconMap: Record<string, React.ElementType> = {
                      bank: Building2, savings: PiggyBank, 
                      investment: TrendingDown, debt: TrendingDown,
                    };
                    const Icon = iconMap[account.type] || Wallet;
                    return (
                      <button
                        key={account.id}
                        onClick={() => setSelectedAccount(account.id)}
                        className={`w-full p-3 rounded-xl flex items-center gap-3 transition-all ${
                          selectedAccount === account.id
                            ? 'bg-gold-500/15 border-2 border-gold-500'
                            : 'bg-theme-badge border-2 border-transparent'
                        }`}
                      >
                        <div
                          className="w-9 h-9 rounded-lg flex items-center justify-center"
                          style={{ backgroundColor: `${account.color || '#B8860B'}20` }}
                        >
                          <Icon className="w-4 h-4" style={{ color: account.color || '#B8860B' }} />
                        </div>
                        <div className="flex-1 text-left">
                          {account.bankName && (
                            <span className="text-xs text-theme-tertiary block">{account.bankName}</span>
                          )}
                          <span className="text-sm font-medium text-theme-primary">{account.name}</span>
                        </div>
                        <span className="text-sm text-theme-tertiary">
                          {getCurrencySymbol()}{account.balance.toFixed(2)}
                        </span>
                        {selectedAccount === account.id && (
                          <Check className="w-4 h-4 text-gold-500" />
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
              )}

              {/* Transfer: Choose own account or external */}
              {activeTab === 'transfer' && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-3">Transfer To</p>
                  <div className="flex gap-2 mb-4">
                    <button
                      onClick={() => { setIsExternalTransfer(false); setExternalRecipient(''); }}
                      className={`flex-1 p-3 rounded-xl text-sm font-medium transition-all ${
                        !isExternalTransfer
                          ? 'bg-blue-500/15 border-2 border-blue-500 text-blue-400'
                          : 'bg-theme-badge border-2 border-transparent text-theme-secondary'
                      }`}
                    >
                      My Account
                    </button>
                    <button
                      onClick={() => { setIsExternalTransfer(true); setToAccount(''); }}
                      className={`flex-1 p-3 rounded-xl text-sm font-medium transition-all ${
                        isExternalTransfer
                          ? 'bg-primary-900/15 border-2 border-primary-800 text-primary-400 dark:text-primary-300'
                          : 'bg-theme-badge border-2 border-transparent text-theme-secondary'
                      }`}
                    >
                      Someone Else
                    </button>
                  </div>

                  {/* Own account destination */}
                  {!isExternalTransfer && (
                    <div className="space-y-2">
                      {accounts.filter(a => a.id !== selectedAccount).map((account) => {
                        const iconMap: Record<string, React.ElementType> = {
                          bank: Building2, savings: PiggyBank,
                          investment: TrendingDown, debt: TrendingDown,
                        };
                        const Icon = iconMap[account.type] || Wallet;
                        return (
                          <button
                            key={account.id}
                            onClick={() => setToAccount(account.id)}
                            className={`w-full p-3 rounded-xl flex items-center gap-3 transition-all ${
                              toAccount === account.id
                                ? 'bg-blue-500/15 border-2 border-blue-500'
                                : 'bg-theme-badge border-2 border-transparent'
                            }`}
                          >
                            <div
                              className="w-9 h-9 rounded-lg flex items-center justify-center"
                              style={{ backgroundColor: `${account.color || '#B8860B'}20` }}
                            >
                              <Icon className="w-4 h-4" style={{ color: account.color || '#B8860B' }} />
                            </div>
                            <div className="flex-1 text-left">
                              {account.bankName && (
                                <span className="text-xs text-theme-tertiary block">{account.bankName}</span>
                              )}
                              <span className="text-sm font-medium text-theme-primary">{account.name}</span>
                            </div>
                            <span className="text-sm text-theme-tertiary">
                              {getCurrencySymbol()}{account.balance.toFixed(2)}
                            </span>
                            {toAccount === account.id && (
                              <Check className="w-4 h-4 text-blue-500" />
                            )}
                          </button>
                        );
                      })}
                    </div>
                  )}

                  {/* External recipient */}
                  {isExternalTransfer && (
                    <div>
                      <input
                        type="text"
                        placeholder="Recipient name (e.g., John, Mom...)"
                        value={externalRecipient}
                        onChange={(e) => setExternalRecipient(e.target.value)}
                        className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                      />
                    </div>
                  )}
                </div>
              )}

              {/* Transfer / Withdrawal Fee Input */}
              {(activeTab === 'transfer' || activeTab === 'withdrawal') && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-2">
                    {activeTab === 'withdrawal' ? 'Withdrawal Fee (optional)' : 'Transfer Fee (optional)'}
                  </p>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">{getCurrencySymbol()}</span>
                    <input
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={manualFee}
                      onChange={(e) => {
                        const val = e.target.value;
                        if (val === '' || /^\d*\.?\d*$/.test(val)) setManualFee(val);
                      }}
                      className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                    />
                  </div>
                  {feeValue > 0 && amount && (
                    <div className="mt-3 p-3 rounded-xl bg-amber-500/10 border border-amber-500/20">
                      <p className="text-xs text-amber-300">
                        Total deducted from your account: <span className="font-bold">{getCurrencySymbol()}{(parseFloat(amount) + feeValue).toFixed(2)}</span>
                      </p>
                      <p className="text-xs text-amber-400/70 mt-1">
                        {getCurrencySymbol()}{parseFloat(amount).toFixed(2)} {activeTab === 'withdrawal' ? 'withdrawn' : 'transferred'} + {getCurrencySymbol()}{feeValue.toFixed(2)} fee
                      </p>
                    </div>
                  )}
                </div>
              )}

              {/* Note Input */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Note (optional)</p>
                <input
                  type="text"
                  placeholder="What was this for?"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
              </div>

              {/* Category Selection */}
              {categories.length > 0 && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-3">Category</p>
                  <div className="flex flex-wrap gap-2">
                    {categories.map((category) => (
                      <button
                        key={category.id}
                        onClick={() => setSelectedCategory(category.id)}
                        className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                          selectedCategory === category.id
                            ? 'bg-gold-500 text-white'
                            : 'bg-theme-badge text-theme-secondary'
                        }`}
                      >
                        {category.name}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Save Button */}
              <Button
                onClick={handleSubmit}
                fullWidth
                size="lg"
                disabled={!amount || parseFloat(amount) <= 0}
                className="bg-gold-500 hover:bg-gold-600 disabled:bg-theme-badge disabled:text-theme-tertiary"
              >
                Save
              </Button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
