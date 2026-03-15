import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bot, Send, Lock, Sparkles, TrendingDown, PiggyBank, Target, AlertTriangle } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { VipUpgradeModal } from '../modals/VipUpgradeModal';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  suggestions?: string[];
}

const quickPrompts = [
  { icon: TrendingDown, text: 'How can I reduce my monthly bills?' },
  { icon: AlertTriangle, text: 'What subscriptions should I cancel?' },
  { icon: Target, text: 'Where can I cut spending fastest?' },
  { icon: PiggyBank, text: 'I want to start investing—what\'s a simple plan?' },
  { icon: Sparkles, text: 'Help me build an emergency fund' },
];

export const AICoach: React.FC = () => {
  const { isVip, transactions, recurringRules, settings, goals } = useStore();
  const [showVipModal, setShowVipModal] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  const vip = isVip();

  const analyzeSpending = () => {
    const now = new Date();
    const thisMonth = transactions.filter((t) => {
      const tDate = new Date(t.date);
      return t.type === 'expense' && 
             tDate.getMonth() === now.getMonth() && 
             tDate.getFullYear() === now.getFullYear();
    });
    
    const totalSpent = thisMonth.reduce((sum, t) => sum + t.amount, 0);
    const monthlyBills = recurringRules.reduce((sum, r) => sum + r.templateTransaction.amount, 0);
    
    return { totalSpent, monthlyBills, transactionCount: thisMonth.length };
  };

  const generateResponse = (userMessage: string): string => {
    const { totalSpent, monthlyBills } = analyzeSpending();
    const income = settings.monthlyIncome;
    const savingsRate = income > 0 ? ((income - totalSpent) / income * 100) : 0;

    if (userMessage.toLowerCase().includes('reduce') || userMessage.toLowerCase().includes('bills')) {
      return `## 💡 Ways to Reduce Your Monthly Bills

**Summary:** You're spending ${formatCurrency(monthlyBills, settings.currency)}/month on recurring bills.

### Biggest Opportunities:
1. **Review subscriptions** - Cancel unused streaming services
2. **Negotiate rates** - Call providers for better deals on internet/phone
3. **Switch providers** - Compare insurance and utility rates
4. **Bundle services** - Combine internet, phone, and TV for discounts

### Actions This Week:
- [ ] List all subscriptions and cancel 1-2 unused ones
- [ ] Call your internet provider and ask for a loyalty discount
- [ ] Compare car insurance quotes online

### Monthly Savings Potential: ${formatCurrency(monthlyBills * 0.15, settings.currency)}-${formatCurrency(monthlyBills * 0.25, settings.currency)}

*Disclaimer: This is general guidance, not financial advice.*`;
    }

    if (userMessage.toLowerCase().includes('subscriptions') || userMessage.toLowerCase().includes('cancel')) {
      return `## 🔍 Subscription Audit

**Your recurring expenses:** ${formatCurrency(monthlyBills, settings.currency)}/month

### Questions to Ask for Each Subscription:
1. Have I used this in the last 30 days?
2. Does this bring me joy or save me time?
3. Can I get this for free elsewhere?

### Common Subscriptions to Review:
- Streaming services (keep 1-2 max)
- Gym memberships (consider home workouts)
- Premium app subscriptions
- News/magazine subscriptions

### Action: Apply in App
Tap "Apply" to set a reminder to review subscriptions weekly.

*Disclaimer: This is general guidance, not financial advice.*`;
    }

    if (userMessage.toLowerCase().includes('investing') || userMessage.toLowerCase().includes('invest')) {
      return `## 📈 Simple Investing Plan

**Before You Invest:**
1. ✅ Build emergency fund (3-6 months expenses)
2. ✅ Pay off high-interest debt
3. ✅ Have stable income

### Beginner Investment Strategy:
1. **Start with retirement accounts** (401k, IRA)
2. **Use low-cost index funds** (S&P 500, Total Market)
3. **Automate contributions** (even $50/month helps)
4. **Don't try to time the market**

### Your Next Steps:
- [ ] Open a brokerage account (Fidelity, Vanguard, Schwab)
- [ ] Set up automatic monthly transfers
- [ ] Start with a target-date fund if unsure

### Risk Assessment:
Your current savings rate: ${savingsRate.toFixed(0)}%
Recommended: 15-20% of income

*Disclaimer: This is educational content, not financial advice. Consult a financial advisor for personalized guidance.*`;
    }

    if (userMessage.toLowerCase().includes('emergency') || userMessage.toLowerCase().includes('fund')) {
      const emergencyTarget = (income * 3);
      const currentSavings = goals.filter(g => g.type === 'savings').reduce((sum, g) => sum + g.currentAmount, 0);
      
      return `## 🛡️ Emergency Fund Plan

**Target:** ${formatCurrency(emergencyTarget, settings.currency)} (3 months of expenses)
**Current savings:** ${formatCurrency(currentSavings, settings.currency)}
**Gap:** ${formatCurrency(Math.max(0, emergencyTarget - currentSavings), settings.currency)}

### Building Your Emergency Fund:
1. **Start small** - Even $25/week adds up
2. **Automate it** - Set up automatic transfers
3. **Keep it accessible** - High-yield savings account
4. **Don't touch it** - Only for true emergencies

### Monthly Savings Plan:
- Save ${formatCurrency(emergencyTarget / 12, settings.currency)}/month to reach goal in 1 year
- Or ${formatCurrency(emergencyTarget / 6, settings.currency)}/month for 6 months

### Action: Create Goal
Tap "Apply" to create an Emergency Fund goal in the app.

*Disclaimer: This is general guidance, not financial advice.*`;
    }

    if (userMessage.toLowerCase().includes('cut') || userMessage.toLowerCase().includes('spending')) {
      return `## ✂️ Quick Spending Cuts

**This month's spending:** ${formatCurrency(totalSpent, settings.currency)}

### Fastest Ways to Cut Spending:
1. **Dining out** - Cook at home 2 more times/week
2. **Coffee** - Make it at home (save $100+/month)
3. **Impulse buys** - Wait 24 hours before purchasing
4. **Subscriptions** - Cancel unused services

### The 50/30/20 Rule:
- 50% Needs: ${formatCurrency(income * 0.5, settings.currency)}
- 30% Wants: ${formatCurrency(income * 0.3, settings.currency)}
- 20% Savings: ${formatCurrency(income * 0.2, settings.currency)}

### This Week's Challenge:
- [ ] No-spend day on Wednesday
- [ ] Pack lunch 3 times
- [ ] Unsubscribe from 2 marketing emails

*Disclaimer: This is general guidance, not financial advice.*`;
    }

    return `## 👋 Hi! I'm your AI Coach

I can help you with:
- **Reducing monthly bills** and subscriptions
- **Cutting spending** in specific categories
- **Building an emergency fund**
- **Getting started with investing**

What would you like to work on today?

*Disclaimer: I provide general guidance, not personalized financial advice.*`;
  };

  const handleSend = (message?: string) => {
    const userMessage = message || input.trim();
    if (!userMessage) return;

    const newUserMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: userMessage,
    };

    setMessages((prev) => [...prev, newUserMessage]);
    setInput('');
    setIsTyping(true);

    // Simulate AI response delay
    setTimeout(() => {
      const response = generateResponse(userMessage);
      const newAssistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response,
      };
      setMessages((prev) => [...prev, newAssistantMessage]);
      setIsTyping(false);
    }, 1000);
  };

  // Locked state for non-VIP users
  if (!vip) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-theme-primary flex items-center gap-2">
            <Bot className="w-5 h-5 text-primary-900" />
            AI Coach
          </h3>
          <Lock className="w-5 h-5 text-amber-500" />
        </div>
        
        <div className="text-center py-6">
          <div className="w-16 h-16 bg-primary-900/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <Bot className="w-8 h-8 text-primary-900" />
          </div>
          <p className="text-theme-secondary mb-2">Get personalized financial advice</p>
          <p className="text-sm text-theme-tertiary mb-4">VIP feature • Spend less & invest smarter</p>
          <button
            onClick={() => setShowVipModal(true)}
            className="px-6 py-2 bg-amber-500 text-white rounded-lg font-medium"
          >
            Unlock with VIP
          </button>
        </div>

        <VipUpgradeModal
          isOpen={showVipModal}
          onClose={() => setShowVipModal(false)}
          feature="coach"
        />
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden"
    >
      {/* Header */}
      <div className="p-4 border-b border-theme-divider">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primary-900/10 rounded-full flex items-center justify-center">
            <Bot className="w-5 h-5 text-primary-900" />
          </div>
          <div>
            <h3 className="font-semibold text-theme-primary">AI Coach</h3>
            <p className="text-xs text-theme-tertiary">Spend less • Invest smarter</p>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="h-80 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 ? (
          <div className="space-y-3">
            <p className="text-theme-tertiary text-sm text-center mb-4">
              Ask me anything about your finances!
            </p>
            {quickPrompts.map((prompt, index) => {
              const Icon = prompt.icon;
              return (
                <motion.button
                  key={index}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.05 }}
                  onClick={() => handleSend(prompt.text)}
                  className="w-full p-3 bg-theme-surface/50 border border-theme-divider rounded-xl text-left flex items-center gap-3 hover:bg-theme-surface-hover"
                >
                  <Icon className="w-5 h-5 text-primary-900" />
                  <span className="text-sm text-theme-secondary">{prompt.text}</span>
                </motion.button>
              );
            })}
          </div>
        ) : (
          <AnimatePresence>
            {messages.map((message) => (
              <motion.div
                key={message.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] p-3 rounded-2xl ${
                    message.role === 'user'
                      ? 'bg-primary-900 text-white'
                      : 'bg-theme-surface backdrop-blur-sm border border-theme-surface-border text-theme-primary'
                  }`}
                >
                  <div className="text-sm whitespace-pre-wrap prose prose-sm dark:prose-invert max-w-none">
                    {message.content.split('\n').map((line, i) => {
                      if (line.startsWith('## ')) {
                        return <h3 key={i} className="text-base font-bold mt-2 mb-1">{line.replace('## ', '')}</h3>;
                      }
                      if (line.startsWith('### ')) {
                        return <h4 key={i} className="text-sm font-semibold mt-2 mb-1">{line.replace('### ', '')}</h4>;
                      }
                      if (line.startsWith('**') && line.endsWith('**')) {
                        return <p key={i} className="font-semibold">{line.replace(/\*\*/g, '')}</p>;
                      }
                      if (line.startsWith('- [ ]')) {
                        return (
                          <div key={i} className="flex items-center gap-2 my-1">
                            <div className="w-4 h-4 border-2 border-gray-400 rounded" />
                            <span>{line.replace('- [ ] ', '')}</span>
                          </div>
                        );
                      }
                      if (line.startsWith('- ')) {
                        return <li key={i} className="ml-4">{line.replace('- ', '')}</li>;
                      }
                      if (line.match(/^\d+\./)) {
                        return <li key={i} className="ml-4">{line}</li>;
                      }
                      if (line.startsWith('*') && line.endsWith('*')) {
                        return <p key={i} className="text-xs text-gray-500 italic mt-2">{line.replace(/\*/g, '')}</p>;
                      }
                      return line ? <p key={i}>{line}</p> : <br key={i} />;
                    })}
                  </div>
                </div>
              </motion.div>
            ))}
            {isTyping && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex justify-start"
              >
                <div className="bg-theme-badge p-3 rounded-2xl">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-white/40 rounded-full animate-bounce" />
                    <div className="w-2 h-2 bg-white/40 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }} />
                    <div className="w-2 h-2 bg-white/40 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        )}
      </div>

      {/* Input */}
      <div className="p-4 border-t border-theme-divider">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Ask about spending, saving, investing..."
            className="flex-1 px-4 py-2 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none text-sm"
          />
          <button
            onClick={() => handleSend()}
            disabled={!input.trim()}
            className="w-10 h-10 bg-primary-900 hover:bg-gold-600 disabled:bg-theme-badge rounded-xl flex items-center justify-center transition-colors"
          >
            <Send className="w-5 h-5 text-theme-primary" />
          </button>
        </div>
      </div>
    </motion.div>
  );
};
