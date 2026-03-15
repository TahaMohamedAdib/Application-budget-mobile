import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/settings.dart';
import '../models/recurring_rule.dart';
import '../models/holding.dart';
import '../models/goal.dart';

class AppProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<RecurringRule> _recurringRules = [];
  List<Holding> _holdings = [];
  List<Goal> _goals = [];
  Settings _settings = Settings();
  bool _isLoading = true;

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<RecurringRule> get recurringRules => _recurringRules;
  List<Holding> get holdings => _holdings;
  List<Goal> get goals => _goals;
  Settings get settings => _settings;
  bool get isLoading => _isLoading;

  AppProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load accounts
    final accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      _accounts = decoded.map((json) => Account.fromJson(json)).toList();
    }
    
    // Load transactions
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> decoded = jsonDecode(transactionsJson);
      _transactions = decoded.map((json) => Transaction.fromJson(json)).toList();
    }
    
    // Load settings
    final settingsJson = prefs.getString('settings');
    if (settingsJson != null) {
      _settings = Settings.fromJson(jsonDecode(settingsJson));
    }
    
    // Load recurring rules
    final recurringRulesJson = prefs.getString('recurringRules');
    if (recurringRulesJson != null) {
      final List<dynamic> decoded = jsonDecode(recurringRulesJson);
      _recurringRules = decoded.map((json) => RecurringRule.fromJson(json)).toList();
    }
    
    // Load holdings
    final holdingsJson = prefs.getString('holdings');
    if (holdingsJson != null) {
      final List<dynamic> decoded = jsonDecode(holdingsJson);
      _holdings = decoded.map((json) => Holding.fromJson(json)).toList();
    }
    
    // Load goals
    final goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      final List<dynamic> decoded = jsonDecode(goalsJson);
      _goals = decoded.map((json) => Goal.fromJson(json)).toList();
    }

    // Load categories (merge with defaults to keep new ones)
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      _categories = decoded.map((json) => Category.fromJson(json)).toList();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
    await prefs.setString('settings', jsonEncode(_settings.toJson()));
    await prefs.setString('recurringRules', jsonEncode(_recurringRules.map((r) => r.toJson()).toList()));
    await prefs.setString('holdings', jsonEncode(_holdings.map((h) => h.toJson()).toList()));
    await prefs.setString('goals', jsonEncode(_goals.map((g) => g.toJson()).toList()));
    await prefs.setString('categories', jsonEncode(_categories.map((c) => c.toJson()).toList()));
  }

  // Account methods
  void addAccount(Account account) {
    _accounts.add(account);
    saveData();
    notifyListeners();
  }

  void updateAccount(Account account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
      saveData();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    saveData();
    notifyListeners();
  }

  static const String cashOnHandId = 'cash_on_hand';

  // Transaction methods
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);

    final isCashSource = transaction.accountId == cashOnHandId;
    final isCashDest = transaction.toAccountId == cashOnHandId;

    // Update source account balance (skip if paying from cash on hand)
    if (!isCashSource) {
      final idx = _accounts.indexWhere((a) => a.id == transaction.accountId);
      if (idx != -1) {
        final account = _accounts[idx];
        double newBalance = account.balance;
        if (transaction.type == 'expense' || transaction.type == 'withdrawal' || transaction.type == 'transfer') {
          newBalance -= transaction.amount;
        } else if (transaction.type == 'income') {
          newBalance += transaction.amount;
        }
        _accounts[idx] = account.copyWith(balance: newBalance);
      }
    }

    // Update destination account for transfers (skip if sending to a person / cash)
    if (transaction.type == 'transfer' && transaction.toAccountId != null && !isCashDest) {
      final idx = _accounts.indexWhere((a) => a.id == transaction.toAccountId);
      if (idx != -1) {
        final toAccount = _accounts[idx];
        _accounts[idx] = toAccount.copyWith(balance: toAccount.balance + transaction.amount);
      }
    }

    saveData();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    saveData();
    notifyListeners();
  }

  // Recurring Rules methods
  void addRecurringRule(RecurringRule rule) {
    _recurringRules.add(rule);
    saveData();
    notifyListeners();
  }

  void updateRecurringRule(RecurringRule rule) {
    final index = _recurringRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _recurringRules[index] = rule;
      saveData();
      notifyListeners();
    }
  }

  void deleteRecurringRule(String id) {
    _recurringRules.removeWhere((r) => r.id == id);
    saveData();
    notifyListeners();
  }

  // Holdings methods
  void addHolding(Holding holding) {
    _holdings.add(holding);
    saveData();
    notifyListeners();
  }

  void updateHolding(Holding holding) {
    final index = _holdings.indexWhere((h) => h.id == holding.id);
    if (index != -1) {
      _holdings[index] = holding;
      saveData();
      notifyListeners();
    }
  }

  void deleteHolding(String id) {
    _holdings.removeWhere((h) => h.id == id);
    saveData();
    notifyListeners();
  }

  double getTotalPortfolioValue() {
    return _holdings.fold(0.0, (sum, h) => sum + h.currentValue);
  }

  double getTotalPortfolioCost() {
    return _holdings.fold(0.0, (sum, h) => sum + h.totalCost);
  }

  double getTotalPortfolioGainLoss() {
    return getTotalPortfolioValue() - getTotalPortfolioCost();
  }

  // Goal methods
  void addGoal(Goal goal) {
    _goals.add(goal);
    saveData();
    notifyListeners();
  }

  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      saveData();
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    saveData();
    notifyListeners();
  }

  void contributeToGoal(String id, double amount) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(
        currentAmount: _goals[index].currentAmount + amount,
      );
      saveData();
      notifyListeners();
    }
  }

  /// Contribute to a goal AND deduct from the source (account or cash on hand).
  /// Always creates a transaction so it appears in Recent Transactions.
  void contributeToGoalFromSource(String goalId, double amount, String sourceAccountId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    // Record a transaction (shows in Recent Transactions)
    _transactions.add(Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'goal_contribution',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Savings: ${goal.name}',
      accountId: sourceAccountId,
    ));

    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
      }
    }
    contributeToGoal(goalId, amount);
  }

  /// Pay toward a debt goal and deduct from the source.
  /// Always creates a transaction so it appears in Recent Transactions.
  void payDebt(String goalId, double amount, String sourceAccountId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    // Record a transaction (shows in Recent Transactions)
    _transactions.add(Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'debt_payment',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Debt payment: ${goal.name}',
      accountId: sourceAccountId,
    ));

    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
      }
    }
    contributeToGoal(goalId, amount);
    saveData();
    notifyListeners();
  }

  // Category methods
  void addCategory(Category category) {
    _categories.add(category);
    saveData();
    notifyListeners();
  }

  void deleteCategory(String categoryId) {
    _categories.removeWhere((c) => c.id == categoryId);
    saveData();
    notifyListeners();
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      saveData();
      notifyListeners();
    }
  }

  double getCategorySpending(String categoryId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) => t.type == 'expense' && t.categoryId == categoryId && DateTime.parse(t.date).isAfter(startOfMonth.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Settings methods
  void updateSettings(Settings settings) {
    _settings = settings;
    saveData();
    notifyListeners();
  }

  void toggleTheme() {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    saveData();
    notifyListeners();
  }

  // Calculations
  double get totalCash {
    double cash = 0;
    for (final t in _transactions) {
      if (t.type == 'withdrawal') {
        // Withdrawing from bank → adds to cash
        cash += t.amount;
      } else if (t.accountId == cashOnHandId) {
        // Spending / transferring / contributing from cash → subtracts
        if (t.type == 'expense' || t.type == 'transfer' || t.type == 'goal_contribution' || t.type == 'debt_payment') {
          cash -= t.amount;
        } else if (t.type == 'income') {
          // Receiving cash income → adds
          cash += t.amount;
        }
      }
      // Transfer TO cash on hand (e.g., someone sends you cash)
      if (t.type == 'transfer' && t.toAccountId == cashOnHandId) {
        cash += t.amount;
      }
    }
    return cash;
  }

  double getSafeToSpendToday() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    
    final totalBalance = _accounts.fold(0.0, (sum, a) => sum + a.balance);
    final monthlyExpenses = 0.0; // Calculate from recurring bills
    
    final safeToSpendMonth = _settings.monthlyIncome - monthlyExpenses;
    return daysRemaining > 0 ? safeToSpendMonth / daysRemaining : 0;
  }

  double getSafeToSpendMonth() {
    final totalBalance = _accounts.fold(0.0, (sum, a) => sum + a.balance);
    final monthlyExpenses = 0.0; // Calculate from recurring bills
    return _settings.monthlyIncome - monthlyExpenses;
  }

  double getNetWorth() {
    final bankAssets = _accounts
        .where((a) => a.includeInNetWorth)
        .fold(0.0, (sum, a) => sum + a.balance);
    final cash = totalCash;
    // Debt goals: remaining balance = targetAmount - currentAmount (what's been paid off)
    final debtRemaining = _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    return bankAssets + cash - debtRemaining;
  }

  // Time-range financial calculations
  Map<String, double> getBalanceForRange(String range) {
    final now = DateTime.now();
    DateTime startDate;
    if (range == '1W') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (range == '1M') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (range == '1Y') {
      startDate = DateTime(now.year, 1, 1);
    } else {
      startDate = DateTime(2000);
    }

    final filtered = _transactions.where((t) {
      final tDate = DateTime.parse(t.date);
      return tDate.isAfter(startDate) || tDate.isAtSameMomentAs(startDate);
    }).toList();

    final income = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'income': income,
      'expenses': expenses,
      'total': income - expenses,
    };
  }

  // Account type totals
  double getTotalByAccountType(String type) {
    return _accounts
        .where((a) => a.type == type)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
  }

  /// Total saved across all savings-type goals
  double get totalSavingsGoals {
    return _goals
        .where((g) => g.type == 'savings' || g.type == 'custom' || g.type == null)
        .fold(0.0, (sum, g) => sum + g.currentAmount);
  }

  /// Total remaining debt across all debt-type goals
  double get totalDebtRemaining {
    return _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
  }

  /// Total investment portfolio value
  double get totalInvestmentValue {
    return getTotalPortfolioValue();
  }
}
