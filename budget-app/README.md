# SafeSpend - Budget Planner App

A modern budget planning application built with React, TypeScript, and TailwindCSS. Know exactly what you can spend today while still saving for big yearly expenses and investing.

## Features

### Core Functionality
- **Safe-to-Spend Daily**: Know exactly how much you can spend each day guilt-free
- **Sinking Funds**: Save for big yearly expenses (car insurance, vacation, gifts)
- **Net Worth Tracking**: Track your investments and overall wealth
- **Quick Transaction Entry**: Add expenses in 2 taps

### App Structure
- **Today Screen**: Daily safe-to-spend amount, recent transactions, goal progress
- **Plan Screen**: Fixed bills, variable spending limits, sinking funds
- **Wealth Screen**: Net worth, emergency fund progress, account balances

### Onboarding
- 7-screen conversion-optimized onboarding flow
- Pain point identification
- Personalized setup
- Hard paywall with free trial

### Viral Features
- Shareable "I can spend X/day" cards
- Monthly savings achievement cards
- Goal progress cards

## Tech Stack
- **React 18** with TypeScript
- **Vite** for fast development
- **TailwindCSS** for styling
- **Zustand** for state management
- **Framer Motion** for animations
- **Lucide React** for icons

## Getting Started

### Prerequisites
- Node.js 18+ installed
- npm or yarn

### Installation

```bash
# Navigate to the project directory
cd budget-app

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will be available at `http://localhost:5173`

### Build for Production

```bash
npm run build
```

## Project Structure

```
src/
├── components/
│   ├── layout/          # BottomNav, FloatingActionButton
│   ├── modals/          # AddTransactionModal
│   ├── onboarding/      # Onboarding screens
│   ├── screens/         # Today, Plan, Wealth screens
│   ├── share/           # Shareable cards
│   └── ui/              # Reusable UI components
├── data/
│   └── categories.ts    # Default categories
├── store/
│   └── useStore.ts      # Zustand store
├── types/
│   └── index.ts         # TypeScript types
├── utils/
│   └── formatters.ts    # Currency/date formatters
├── App.tsx
├── main.tsx
└── index.css
```

## Data Model

- **Account**: Cash, bank, card, savings, investment, debt accounts
- **Transaction**: Expenses, income, transfers
- **Category**: Fixed, variable, future (sinking funds), wealth
- **Goal**: Sinking funds with target amounts and dates
- **BudgetMonth**: Monthly budget allocations per category
- **RecurringRule**: Recurring transactions

## The Math

```
SafeToSpendMonth = Income - FixedBills - GoalContributions - SpentThisMonth
SafeToSpendToday = SafeToSpendMonthRemaining / DaysRemaining
```

## Pricing Strategy
- Hard paywall after onboarding
- Monthly ($7.99) and Yearly ($39.99) plans
- 7-day free trial
- 30-day money-back guarantee

## Trading.com Integration

### Overview
The Portfolio (Compte-Titres) feature is designed to fetch real-time prices from trading.com. However, **trading.com does not expose a public API** for market data.

### Investigation Findings
- Trading.com is a **forex/CFD broker**, not a stock data API provider
- Price data is only available through their proprietary platforms (MT5, WebTrader)
- No public REST API endpoints discovered
- Authentication required for all data access
- Scraping would violate their Terms of Service

### Current Implementation
Since trading.com doesn't provide API access, the app implements:

1. **Manual Price Entry**: Users can edit prices directly using the ✏️ button
2. **20-Minute Caching**: Prices are cached locally to avoid redundant updates
3. **Clear Status Indicators**: Shows "manual" or "trading.com" as data source
4. **Delay Badge**: Displays "Prices delayed ~20 min" disclaimer

### Market Data Service Architecture
```
src/services/marketData/
├── index.ts                    # Public API exports
├── types.ts                    # TypeScript interfaces
├── cache.ts                    # 20-minute quote caching
├── tradingComConnector.ts      # Trading.com connector (placeholder)
├── marketDataService.ts        # Main service with fallback logic
└── TRADING_COM_DEV_NOTES.md    # Detailed investigation notes
```

### Configuration (Future)
If trading.com ever provides API access, configure these environment variables:
```env
TRADING_COM_ENABLED=true
TRADING_COM_SESSION_TOKEN=your_token_here
TRADING_COM_ACCOUNT_ID=your_account_id
```

### API Response Format
```json
{
  "ticker": "AAPL",
  "name": "Apple Inc.",
  "currency": "USD",
  "price": 185.50,
  "change": 2.30,
  "changePct": 1.25,
  "timestamp": "2026-02-05T18:30:00Z",
  "source": "trading.com",
  "delayedMins": 20,
  "cached": true
}
```

### Test Plan
Test with these 3 tickers:
1. **AAPL** - Apple Inc.
2. **MSFT** - Microsoft Corp.
3. **GOOGL** - Alphabet Inc.

Expected behavior:
- First fetch: Returns error (trading.com not configured)
- Manual entry: User enters price, cached for 20 min
- Refresh within 20 min: Returns cached price
- Refresh after 20 min: Allows new manual entry

## License
MIT
