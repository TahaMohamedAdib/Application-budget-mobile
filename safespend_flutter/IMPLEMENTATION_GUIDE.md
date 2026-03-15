# SafeSpend Flutter - Complete Implementation Guide

## Current Status

### ✅ Completed (Foundation)
- Project structure and configuration
- Theme system (light/dark with gold accents)
- Data models (Account, Transaction, Category, Settings, RecurringRule)
- State management with Provider
- Local storage with SharedPreferences
- Today Screen with main features
- Basic navigation structure

### 📋 Remaining Work

This guide outlines what needs to be built to match the React app completely.

## Screens to Build

### 1. Settings Screen
**File**: `lib/screens/settings_screen.dart`

**Features**:
- Currency selector
- Monthly income input
- Theme toggle (light/dark)
- Net worth scope selector
- About section
- Back button

**Key Widgets**:
```dart
- ListTile for each setting
- Switch for theme toggle
- TextField for income
- DropdownButton for currency
```

### 2. Accounts Screen
**File**: `lib/screens/accounts_screen.dart`

**Features**:
- List of all accounts with balances
- Add account button (opens modal)
- Edit account (tap to edit)
- Delete account (swipe or long press)
- Account types: bank, savings, investment, debt
- Color picker for each account

**Modals Needed**:
- `lib/widgets/add_account_modal.dart`
- Account form with name, type, balance, bank name, color

### 3. Plan Screen (Bills Management)
**File**: `lib/screens/plan_screen.dart`

**Features**:
- List of recurring bills
- Add bill button
- Edit/delete bills
- Next due date display
- Monthly total calculation
- Bill categories

**Modals Needed**:
- `lib/widgets/add_bill_modal.dart`
- Frequency selector (daily, weekly, monthly, yearly)

### 4. Wealth Screen (Complete)
**File**: `lib/screens/wealth_screen.dart`

**Features**:
- Net worth card with trend
- Assets vs Debts breakdown
- Account list by type
- Emergency fund tracker
- Link to Portfolio screen
- Manage Accounts button

### 5. Portfolio Screen
**File**: `lib/screens/portfolio_screen.dart`

**Features**:
- Investment holdings list
- Total portfolio value
- Gain/loss display
- Add holding button
- Edit/delete holdings
- Market data integration (optional)

**Models Needed**:
- `lib/models/holding.dart` (symbol, shares, cost basis, current price)

### 6. Transactions Screen
**File**: `lib/screens/transactions_screen.dart`

**Features**:
- Full transaction list
- Search functionality
- Filter by type (expense, income, transfer, withdrawal)
- Sort options (newest, oldest, highest, lowest)
- Date range filter
- Category filter
- Back button

### 7. Coach Screen (AI Assistant)
**File**: `lib/screens/coach_screen.dart`

**Features**:
- Chat interface
- Financial advice display
- Budget insights
- Spending analysis
- Locked state (VIP feature)
- Unlock button

### 8. Onboarding Flow
**Files**: 
- `lib/screens/onboarding/welcome_screen.dart`
- `lib/screens/onboarding/hook_screen.dart`
- `lib/screens/onboarding/aha_screen.dart`
- `lib/screens/onboarding/preview_screen.dart`
- `lib/screens/onboarding/setup_screen.dart`

**Features**:
- Welcome animation
- Problem statement
- Solution showcase
- App preview
- Initial setup (income, first account)

## Modals & Dialogs

### 1. Add Transaction Modal
**File**: `lib/widgets/add_transaction_modal.dart`

**Types**:
- Expense (amount, category, account, note, date)
- Income (amount, account, note, date)
- Transfer (amount, from account, to account, note, date)
- Withdrawal (amount, account, note, date)

**Features**:
- Tab selector for type
- Number pad for amount
- Category picker
- Account picker
- Date picker
- Note field

### 2. Withdrawal History Modal
**File**: `lib/widgets/withdrawal_history_modal.dart`

**Features**:
- Bottom sheet style
- List of all withdrawals
- Total cash on hand
- Date display
- Close button

### 3. Account Picker Modal
**File**: `lib/widgets/account_picker_modal.dart`

**Features**:
- List of accounts
- "All Accounts" option
- Checkmark for selected
- Account icons and colors

### 4. VIP Upgrade Modal
**File**: `lib/widgets/vip_upgrade_modal.dart`

**Features**:
- Premium features list
- Pricing display
- Upgrade button
- Close button

## Widgets to Create

### 1. Bottom Navigation
**File**: `lib/widgets/bottom_nav.dart`
- Already in main.dart, can be extracted

### 2. Floating Action Button
**File**: `lib/widgets/floating_action_button.dart`
- Speed dial for quick actions
- Add expense, income, transfer, withdrawal

### 3. Safe to Spend Card
**File**: `lib/widgets/safe_to_spend_card.dart`
- Extract from TodayScreen
- Reusable component

### 4. Transaction List Item
**File**: `lib/widgets/transaction_list_item.dart`
- Icon based on type
- Amount with color
- Date and note
- Swipe to delete

### 5. Account Card
**File**: `lib/widgets/account_card.dart`
- Account icon and color
- Name and bank
- Balance
- Tap to select

## Enhanced Provider Methods

Add to `lib/providers/app_provider.dart`:

```dart
// Recurring Rules
void addRecurringRule(RecurringRule rule) { }
void updateRecurringRule(RecurringRule rule) { }
void deleteRecurringRule(String id) { }

// Calculations
double getTotalBills() { }
double getDailyAverage() { }
int getDaysRemainingInMonth() { }
double getNetWorthByScope(String scope, String? accountId) { }
List<Transaction> getTransactionsByAccount(String accountId) { }
List<Transaction> getTransactionsByType(String type) { }
List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) { }

// Holdings (for portfolio)
void addHolding(Holding holding) { }
void updateHolding(Holding holding) { }
void deleteHolding(String id) { }
double getTotalPortfolioValue() { }
```

## Animations

Use Flutter's built-in animation widgets:
- `AnimatedContainer` for size/color changes
- `Hero` for screen transitions
- `SlideTransition` for page transitions
- `FadeTransition` for opacity changes
- `AnimatedOpacity` for fading
- `AnimatedPositioned` for movement

## Navigation

Update `main.dart` to handle:
- Push/pop for modal screens
- Bottom sheet for modals
- Dialog for confirmations
- Named routes for deep linking

## Testing Checklist

- [ ] Add account
- [ ] Edit account
- [ ] Delete account
- [ ] Add transaction (all types)
- [ ] Delete transaction
- [ ] Add recurring bill
- [ ] Edit recurring bill
- [ ] Delete recurring bill
- [ ] Toggle theme
- [ ] Change currency
- [ ] Update income
- [ ] View portfolio
- [ ] Add holding
- [ ] Filter transactions
- [ ] Search transactions
- [ ] Cash on hand calculation
- [ ] Safe to spend calculation
- [ ] Net worth calculation
- [ ] Data persistence (close/reopen app)

## Build & Run

```bash
# Get dependencies
flutter pub get

# Run on emulator
flutter run

# Build APK
flutter build apk --release

# Build for iOS (requires Mac)
flutter build ios --release
```

## Estimated Effort

- **Settings Screen**: 2-3 hours
- **Accounts Screen**: 3-4 hours
- **Plan Screen**: 4-5 hours
- **Wealth Screen**: 4-5 hours
- **Portfolio Screen**: 3-4 hours
- **Transactions Screen**: 3-4 hours
- **Coach Screen**: 2-3 hours
- **Onboarding Flow**: 4-6 hours
- **All Modals**: 6-8 hours
- **Widgets & Components**: 4-6 hours
- **Animations & Polish**: 3-4 hours
- **Testing & Bug Fixes**: 4-6 hours

**Total**: ~45-60 hours of development

## Next Steps

1. Start with Settings Screen (simplest)
2. Build Accounts Screen with add/edit/delete
3. Implement Add Transaction Modal
4. Complete Plan Screen with bills
5. Finish Wealth Screen
6. Add Portfolio Screen
7. Build Transactions Screen
8. Create Coach Screen
9. Implement Onboarding
10. Add animations and polish
11. Test thoroughly
12. Build release APK

## Resources

- Flutter Documentation: https://docs.flutter.dev
- Material Design 3: https://m3.material.io
- Provider Package: https://pub.dev/packages/provider
- SharedPreferences: https://pub.dev/packages/shared_preferences
