import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/settings.dart';
import '../models/recurring_rule.dart';
import '../models/holding.dart';
import '../models/goal.dart';
import '../services/supabase_sync_service.dart';

class AppProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<RecurringRule> _recurringRules = [];
  List<Holding> _holdings = [];
  List<Goal> _goals = [];
  Settings _settings = Settings();
  bool _isLoading = true;
  bool _localDataLoaded = false;
  bool _supabaseDataLoaded = false;
  bool _supabaseLoadInProgress = false;

  bool _setupComplete = false;
  String? _selectedAccountId; // null = all accounts (shared across screens)

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<RecurringRule> get recurringRules => _recurringRules;
  List<Holding> get holdings => _holdings;
  List<Goal> get goals => _goals;
  Settings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get localDataLoaded => _localDataLoaded;
  bool get setupComplete => _setupComplete;
  bool get supabaseDataLoaded => _supabaseDataLoaded;
  String? get selectedAccountId => _selectedAccountId;

  void setSelectedAccount(String? accountId) {
    if (_selectedAccountId == accountId) return;
    _selectedAccountId = accountId;
    notifyListeners();
  }

  AppProvider() {
    loadData();
  }

  // ============================================
  // SUPABASE INTEGRATION
  // ============================================

  String? get _userId => SupabaseSyncService.currentUserId;

  /// Load ALL data from Supabase for the authenticated user.
  /// Falls back to SharedPreferences if not authenticated or on error.
  Future<void> loadFromSupabase(String userId) async {
    if (_supabaseLoadInProgress) return;
    _supabaseLoadInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      final data = await SupabaseSyncService.loadAllUserData(userId);

      if (data['settings'] != null) _settings = data['settings'] as Settings;
      _accounts = data['accounts'] as List<Account>;
      _transactions = data['transactions'] as List<Transaction>;
      _goals = data['goals'] as List<Goal>;
      _recurringRules = data['recurringRules'] as List<RecurringRule>;
      _holdings = data['holdings'] as List<Holding>;
      _categories = data['categories'] as List<Category>;

      _isLoading = false;
      _supabaseDataLoaded = true;
      _supabaseLoadInProgress = false;

      // Auto-skip onboarding if user already has data in Supabase
      if (_accounts.isNotEmpty && !_setupComplete) {
        _setupComplete = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('setup_complete', true);
      }

      notifyListeners();

      // Cache to SharedPreferences for offline use
      _saveToLocal();
      processSalaries();
      processSubscriptions();
    } catch (e) {
      print('[AppProvider] Error loading from Supabase, falling back to local: $e');
      _supabaseDataLoaded = true; // mark as done even on error to avoid retry loops
      _supabaseLoadInProgress = false;
      await loadData();
    }
  }

  /// Clear all data (used on sign out). Resets flags so the next user
  /// can load their own data from Supabase cleanly.
  void clearData() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _recurringRules = [];
    _holdings = [];
    _goals = [];
    _settings = Settings();
    _isLoading = false;
    _supabaseDataLoaded = false;
    _localDataLoaded = false;
    _setupComplete = false;
    _supabaseLoadInProgress = false;
    notifyListeners();
    _clearLocalCache();
  }

  Future<void> _clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accounts');
    await prefs.remove('transactions');
    await prefs.remove('settings');
    await prefs.remove('recurringRules');
    await prefs.remove('holdings');
    await prefs.remove('goals');
    await prefs.remove('categories');
    await prefs.remove('setup_complete');
  }

  // ============================================
  // LOCAL PERSISTENCE (SharedPreferences cache)
  // ============================================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      _accounts = (jsonDecode(accountsJson) as List).map((j) => Account.fromJson(j)).toList();
    }

    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      _transactions = (jsonDecode(transactionsJson) as List).map((j) => Transaction.fromJson(j)).toList();
    }

    final settingsJson = prefs.getString('settings');
    if (settingsJson != null) {
      _settings = Settings.fromJson(jsonDecode(settingsJson));
    }

    final recurringRulesJson = prefs.getString('recurringRules');
    if (recurringRulesJson != null) {
      _recurringRules = (jsonDecode(recurringRulesJson) as List).map((j) => RecurringRule.fromJson(j)).toList();
    }

    final holdingsJson = prefs.getString('holdings');
    if (holdingsJson != null) {
      _holdings = (jsonDecode(holdingsJson) as List).map((j) => Holding.fromJson(j)).toList();
    }

    final goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      _goals = (jsonDecode(goalsJson) as List).map((j) => Goal.fromJson(j)).toList();
    }

    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      _categories = (jsonDecode(categoriesJson) as List).map((j) => Category.fromJson(j)).toList();
    }

    _setupComplete = prefs.getBool('setup_complete') ?? false;

    _isLoading = false;
    _localDataLoaded = true;
    notifyListeners();
    processSalaries();
    processSubscriptions();
  }

  Future<void> markSetupComplete() async {
    _setupComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
    await prefs.setString('settings', jsonEncode(_settings.toJson()));
    await prefs.setString('recurringRules', jsonEncode(_recurringRules.map((r) => r.toJson()).toList()));
    await prefs.setString('holdings', jsonEncode(_holdings.map((h) => h.toJson()).toList()));
    await prefs.setString('goals', jsonEncode(_goals.map((g) => g.toJson()).toList()));
    await prefs.setString('categories', jsonEncode(_categories.map((c) => c.toJson()).toList()));
  }

  // ============================================
  // ACCOUNT METHODS
  // ============================================

  void addAccount(Account account) {
    _accounts.add(account);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveAccount(uid, account);
  }

  void updateAccount(Account account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveAccount(uid, account);
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteAccount(uid, id);
  }

  /// Auto-credits salary for each account where today >= salaryDay and
  /// the salary has not yet been credited this calendar month.
  void processSalaries() {
    final today = DateTime.now();
    final thisMonth =
        '${today.year}-${today.month.toString().padLeft(2, '0')}';
    bool changed = false;

    for (int i = 0; i < _accounts.length; i++) {
      final acc = _accounts[i];
      final amount = acc.salaryAmount;
      final day = acc.salaryDay;
      if (amount == null || amount <= 0 || day == null) continue;
      if (today.day < day) continue; // pay day not reached yet
      if (acc.lastSalaryDate == thisMonth) continue; // already credited

      // Build the salary transaction dated on the pay day
      final payDate = DateTime(today.year, today.month, day);
      final tx = Transaction(
        id: const Uuid().v4(),
        type: 'income',
        amount: amount,
        date: payDate.toIso8601String().substring(0, 10),
        note: 'Salary',
        accountId: acc.id,
      );
      _transactions.add(tx);

      _accounts[i] = acc.copyWith(
        balance: acc.balance + amount,
        lastSalaryDate: thisMonth,
      );
      changed = true;

      final uid = _userId;
      if (uid != null) {
        SupabaseSyncService.saveTransaction(uid, tx);
        SupabaseSyncService.saveAccount(uid, _accounts[i]);
      }
    }

    if (changed) {
      _saveToLocal();
      notifyListeners();
    }
  }

  static const String cashOnHandId = 'cash_on_hand';

  /// Process all overdue recurring rules: create transactions and advance nextDate.
  /// Compares full datetime so same-day future rules are NOT processed prematurely.
  void processSubscriptions() {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _recurringRules.length; i++) {
      final rule = _recurringRules[i];
      if (!rule.isActive) continue;

      // Support both date-only "2026-03-22" and full datetime "2026-03-22T15:30:00"
      DateTime nextDate = DateTime.parse(rule.nextDate);
      int safetyCounter = 0;

      // Process each overdue period (max 24 to avoid infinite loop on very old rules)
      while (!nextDate.isAfter(now) && safetyCounter < 24) {
        safetyCounter++;

        final isIncome = rule.templateTransaction.type == 'income';

        // Create transaction for this due date/time
        final tx = Transaction(
          id: const Uuid().v4(),
          type: isIncome ? 'income' : 'expense',
          amount: rule.templateTransaction.amount,
          date: nextDate.toIso8601String(),
          note: rule.templateTransaction.note,
          categoryId: rule.templateTransaction.categoryId,
          accountId: rule.templateTransaction.accountId,
          isRecurring: true,
          expenseSubType: isIncome ? null : 'subscription',
        );
        _transactions.add(tx);

        // Add/deduct from account balance
        if (rule.templateTransaction.accountId != cashOnHandId) {
          final idx = _accounts.indexWhere((a) => a.id == rule.templateTransaction.accountId);
          if (idx != -1) {
            _accounts[idx] = _accounts[idx].copyWith(
              balance: _accounts[idx].balance + (isIncome ? rule.templateTransaction.amount : -rule.templateTransaction.amount),
            );
          }
        }

        // Advance nextDate by one period, preserving time of day
        switch (rule.frequency) {
          case 'daily':
            nextDate = nextDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDate = nextDate.add(const Duration(days: 7));
            break;
          case 'yearly':
            nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day, nextDate.hour, nextDate.minute);
            break;
          default: // monthly
            nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day, nextDate.hour, nextDate.minute);
        }

        // Sync transaction to Supabase
        final uid = _userId;
        if (uid != null) {
          SupabaseSyncService.saveTransaction(uid, tx);
          if (rule.templateTransaction.accountId != cashOnHandId) {
            final idx = _accounts.indexWhere((a) => a.id == rule.templateTransaction.accountId);
            if (idx != -1) SupabaseSyncService.saveAccount(uid, _accounts[idx]);
          }
        }
        changed = true;
      }

      if (safetyCounter > 0) {
        // Update the rule with the new nextDate (full ISO string with time)
        _recurringRules[i] = rule.copyWith(nextDate: nextDate.toIso8601String());
        final uid = _userId;
        if (uid != null) SupabaseSyncService.saveRecurringRule(uid, _recurringRules[i]);
      }
    }

    if (changed) {
      _saveToLocal();
      notifyListeners();
    }
  }

  // ============================================
  // TRANSACTION METHODS
  // ============================================

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);

    final isCashSource = transaction.accountId == cashOnHandId;
    final isCashDest = transaction.toAccountId == cashOnHandId;

    // Track which accounts changed for Supabase sync
    final List<Account> changedAccounts = [];

    // Update source account balance (skip if paying from cash on hand)
    if (!isCashSource) {
      final idx = _accounts.indexWhere((a) => a.id == transaction.accountId);
      if (idx != -1) {
        final account = _accounts[idx];
        double newBalance = account.balance;
        if (transaction.type == 'expense' || transaction.type == 'withdrawal' || transaction.type == 'transfer') {
          newBalance -= transaction.amount;
        } else if (transaction.type == 'income' || transaction.type == 'lending_collection') {
          newBalance += transaction.amount;
        }
        _accounts[idx] = account.copyWith(balance: newBalance);
        changedAccounts.add(_accounts[idx]);
      }
    }

    // Update destination account for transfers (skip if sending to a person / cash)
    if (transaction.type == 'transfer' && transaction.toAccountId != null && !isCashDest) {
      final idx = _accounts.indexWhere((a) => a.id == transaction.toAccountId);
      if (idx != -1) {
        final toAccount = _accounts[idx];
        _accounts[idx] = toAccount.copyWith(balance: toAccount.balance + transaction.amount);
        changedAccounts.add(_accounts[idx]);
      }
    }

    _saveToLocal();
    notifyListeners();

    // Sync to Supabase: save the transaction + any changed account balances
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, transaction);
      if (changedAccounts.isNotEmpty) {
        SupabaseSyncService.saveMultipleAccounts(uid, changedAccounts);
      }
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteTransaction(uid, id);
  }

  void updateTransaction(Transaction updated) {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final old = _transactions[idx];
    _transactions[idx] = updated;

    // Reverse old effect on account balance
    if (old.accountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == old.accountId);
      if (ai != -1) {
        double bal = _accounts[ai].balance;
        if (old.type == 'expense' || old.type == 'withdrawal' || old.type == 'transfer') bal += old.amount;
        else if (old.type == 'income' || old.type == 'lending_collection') bal -= old.amount;
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }
    // Apply new effect on account balance
    if (updated.accountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == updated.accountId);
      if (ai != -1) {
        double bal = _accounts[ai].balance;
        if (updated.type == 'expense' || updated.type == 'withdrawal' || updated.type == 'transfer') bal -= updated.amount;
        else if (updated.type == 'income' || updated.type == 'lending_collection') bal += updated.amount;
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }

    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, updated);
    }
  }

  // ============================================
  // RECURRING RULES METHODS
  // ============================================

  void addRecurringRule(RecurringRule rule) {
    _recurringRules.add(rule);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveRecurringRule(uid, rule);
  }

  void updateRecurringRule(RecurringRule rule) {
    final index = _recurringRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _recurringRules[index] = rule;
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveRecurringRule(uid, rule);
    }
  }

  void deleteRecurringRule(String id) {
    _recurringRules.removeWhere((r) => r.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteRecurringRule(uid, id);
  }

  // ============================================
  // HOLDINGS METHODS
  // ============================================

  void addHolding(Holding holding) {
    _holdings.add(holding);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveHolding(uid, holding);
  }

  void updateHolding(Holding holding) {
    final index = _holdings.indexWhere((h) => h.id == holding.id);
    if (index != -1) {
      _holdings[index] = holding;
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveHolding(uid, holding);
    }
  }

  void deleteHolding(String id) {
    _holdings.removeWhere((h) => h.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteHolding(uid, id);
  }

  /// Sell [sharesToSell] shares of [holding] at [sellPrice] each.
  /// Proceeds go to [accountId]. Creates an income transaction and
  /// reduces (or removes) the holding. Everything syncs to Supabase.
  void sellHolding({
    required Holding holding,
    required double sharesToSell,
    required double sellPrice,
    required String accountId,
    required String transactionId,
  }) {
    final proceeds = sharesToSell * sellPrice;
    final remainingShares = holding.shares - sharesToSell;

    // 1. Update or remove the holding
    if (remainingShares <= 0) {
      _holdings.removeWhere((h) => h.id == holding.id);
      final uid = _userId;
      if (uid != null) SupabaseSyncService.deleteHolding(uid, holding.id);
    } else {
      final updated = holding.copyWith(shares: remainingShares);
      final idx = _holdings.indexWhere((h) => h.id == holding.id);
      if (idx != -1) _holdings[idx] = updated;
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveHolding(uid, updated);
    }

    // 2. Create an income transaction for the proceeds
    final tx = Transaction(
      id: transactionId,
      type: 'income',
      amount: proceeds,
      date: DateTime.now().toIso8601String(),
      accountId: accountId,
      note: 'Sold $sharesToSell × ${holding.symbol} @ \$${sellPrice.toStringAsFixed(2)}',
    );
    _transactions.add(tx);

    // 3. Credit the account balance
    final accIdx = _accounts.indexWhere((a) => a.id == accountId);
    Account? updatedAccount;
    if (accIdx != -1) {
      updatedAccount = _accounts[accIdx]
          .copyWith(balance: _accounts[accIdx].balance + proceeds);
      _accounts[accIdx] = updatedAccount;
    }

    _saveToLocal();
    notifyListeners();

    // 4. Sync to Supabase
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, tx);
      if (updatedAccount != null) {
        SupabaseSyncService.saveAccount(uid, updatedAccount);
      }
    }
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

  // ============================================
  // GOAL METHODS
  // ============================================

  void addGoal(Goal goal) {
    _goals.add(goal);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveGoal(uid, goal);
  }

  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveGoal(uid, goal);
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteGoal(uid, id);
  }

  void contributeToGoal(String id, double amount) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(
        currentAmount: _goals[index].currentAmount + amount,
      );
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveGoal(uid, _goals[index]);
    }
  }

  /// Contribute to a goal AND deduct from the source (account or cash on hand).
  /// Always creates a transaction so it appears in Recent Transactions.
  void contributeToGoalFromSource(String goalId, double amount, String sourceAccountId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'goal_contribution',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Savings: ${goal.name}',
      accountId: sourceAccountId,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      _goals[goalIdx] = _goals[goalIdx].copyWith(
        currentAmount: _goals[goalIdx].currentAmount + amount,
      );
    }

    _saveToLocal();
    notifyListeners();

    // Sync all changed items to Supabase
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (changedAccount != null) SupabaseSyncService.saveAccount(uid, changedAccount);
      if (goalIdx != -1) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
    }
  }

  /// Pay toward a debt goal and deduct from the source.
  /// Always creates a transaction so it appears in Recent Transactions.
  void payDebt(String goalId, double amount, String sourceAccountId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'debt_payment',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Debt payment: ${goal.name}',
      accountId: sourceAccountId,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      _goals[goalIdx] = _goals[goalIdx].copyWith(
        currentAmount: _goals[goalIdx].currentAmount + amount,
      );
    }

    _saveToLocal();
    notifyListeners();

    // Sync all changed items to Supabase
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (changedAccount != null) SupabaseSyncService.saveAccount(uid, changedAccount);
      if (goalIdx != -1) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
    }
  }

  // ============================================
  // CATEGORY METHODS
  // ============================================

  void addCategory(Category category) {
    _categories.add(category);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveCategory(uid, category);
  }

  void deleteCategory(String categoryId) {
    _categories.removeWhere((c) => c.id == categoryId);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteCategory(uid, categoryId);
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveCategory(uid, category);
    }
  }

  double getCategorySpending(String categoryId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions
        .where((t) => t.type == 'expense' && t.categoryId == categoryId && DateTime.parse(t.date).isAfter(startOfMonth.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ============================================
  // SETTINGS METHODS
  // ============================================

  void updateSettings(Settings settings) {
    _settings = settings;
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, settings);
  }

  void toggleTheme() {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, _settings);
  }

  // ============================================
  // CALCULATIONS (read-only, no sync needed)
  // ============================================

  double get totalCash {
    double cash = 0;
    for (final t in _transactions) {
      if (t.type == 'withdrawal') {
        cash += t.amount;
      } else if (t.accountId == cashOnHandId) {
        if (t.type == 'expense' || t.type == 'transfer' || t.type == 'goal_contribution' || t.type == 'debt_payment') {
          cash -= t.amount;
        } else if (t.type == 'income' || t.type == 'lending_collection') {
          cash += t.amount;
        }
      }
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
    final monthlyExpenses = 0.0;
    
    final safeToSpendMonth = _settings.monthlyIncome - monthlyExpenses;
    return daysRemaining > 0 ? safeToSpendMonth / daysRemaining : 0;
  }

  double getSafeToSpendMonth() {
    final totalBalance = _accounts.fold(0.0, (sum, a) => sum + a.balance);
    final monthlyExpenses = 0.0;
    return _settings.monthlyIncome - monthlyExpenses;
  }

  double getNetWorth() {
    // Non-investment accounts with includeInNetWorth
    final bankAssets = _accounts
        .where((a) => a.includeInNetWorth && a.type != 'investment')
        .fold(0.0, (sum, a) => sum + a.balance);
    final cash = totalCash;
    // Investment account balances + portfolio positions
    final investments = totalInvestmentValue;
    final debtRemaining = _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    final personalDebtRemaining = _goals
        .where((g) => g.type == 'personal_debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    return bankAssets + cash + investments - debtRemaining + personalDebtRemaining;
  }

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

  double getTotalByAccountType(String type) {
    return _accounts
        .where((a) => a.type == type)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
  }

  double get totalSavingsGoals {
    return _goals
        .where((g) => g.type == 'savings' || g.type == 'custom' || g.type == null)
        .fold(0.0, (sum, g) => sum + g.currentAmount);
  }

  double get totalDebtRemaining {
    return _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
  }

  double get totalInvestmentValue {
    // Investment account balances + portfolio (holdings) value
    final investmentAccounts = _accounts
        .where((a) => a.type == 'investment')
        .fold(0.0, (sum, a) => sum + a.balance);
    return investmentAccounts + getTotalPortfolioValue();
  }
}
