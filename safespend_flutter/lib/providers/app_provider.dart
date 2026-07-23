import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/settings.dart';
import '../models/recurring_rule.dart';
import '../models/holding.dart';
import '../models/goal.dart';
import '../models/daret.dart';
import '../services/supabase_sync_service.dart';

/// Top-level function for compute() — parses all cached JSON off the main thread.
Map<String, dynamic> _parseLocalData(Map<String, String?> rawJson) {
  final result = <String, dynamic>{};
  try {
    final a = rawJson['accounts'];
    if (a != null)
      result['accounts'] =
          (jsonDecode(a) as List).map((j) => Account.fromJson(j)).toList();
  } catch (_) {}
  try {
    final t = rawJson['transactions'];
    if (t != null)
      result['transactions'] =
          (jsonDecode(t) as List).map((j) => Transaction.fromJson(j)).toList();
  } catch (_) {}
  try {
    final s = rawJson['settings'];
    if (s != null) result['settings'] = Settings.fromJson(jsonDecode(s));
  } catch (_) {}
  try {
    final r = rawJson['recurringRules'];
    if (r != null)
      result['recurringRules'] = (jsonDecode(r) as List)
          .map((j) => RecurringRule.fromJson(j))
          .toList();
  } catch (_) {}
  try {
    final h = rawJson['holdings'];
    if (h != null)
      result['holdings'] =
          (jsonDecode(h) as List).map((j) => Holding.fromJson(j)).toList();
  } catch (_) {}
  try {
    final g = rawJson['goals'];
    if (g != null)
      result['goals'] =
          (jsonDecode(g) as List).map((j) => Goal.fromJson(j)).toList();
  } catch (_) {}
  try {
    final d = rawJson['darets'];
    if (d != null)
      result['darets'] =
          (jsonDecode(d) as List).map((j) => Daret.fromJson(j)).toList();
  } catch (_) {}
  try {
    final c = rawJson['categories'];
    if (c != null)
      result['categories'] =
          (jsonDecode(c) as List).map((j) => Category.fromJson(j)).toList();
  } catch (_) {}
  return result;
}

class AppProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<RecurringRule> _recurringRules = [];
  List<Holding> _holdings = [];
  List<Goal> _goals = [];
  List<Daret> _darets = [];
  Settings _settings = Settings();
  bool _isLoading = true;
  bool _localDataLoaded = false;
  bool _supabaseDataLoaded = false;
  bool _supabaseLoadInProgress = false;

  bool _setupComplete = false;
  String? _selectedAccountId; // null = all accounts (shared across screens)

  // ── Debounced save ──────────────────────────────────────────────────────
  Timer? _saveDebounce;
  static const _saveDebounceDuration = Duration(milliseconds: 500);

  // ── Cached computed values ──────────────────────────────────────────────
  double? _cachedTotalCash;
  double? _cachedNetWorth;
  double? _cachedTotalSavingsGoals;
  double? _cachedTotalDebtRemaining;
  double? _cachedTotalInvestmentValue;

  void _invalidateCache() {
    _cachedTotalCash = null;
    _cachedNetWorth = null;
    _cachedTotalSavingsGoals = null;
    _cachedTotalDebtRemaining = null;
    _cachedTotalInvestmentValue = null;
  }

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<RecurringRule> get recurringRules => _recurringRules;
  List<Holding> get holdings => _holdings;
  List<Goal> get goals => _goals;
  List<Daret> get darets => _darets;
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
      final hasPendingOfflineChanges =
          await SupabaseSyncService.hasPendingOperationsForUser(userId);
      if (hasPendingOfflineChanges) {
        _isLoading = false;
        _supabaseDataLoaded = true;
        _supabaseLoadInProgress = false;
        notifyListeners();
        processSalaries();
        processSubscriptions();
        SupabaseSyncService.flushRetryQueue();
        return;
      }

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

      // Flush any queued sync operations that failed while offline
      SupabaseSyncService.flushRetryQueue();
    } catch (e) {
      if (kDebugMode)
        debugPrint(
            '[AppProvider] Error loading from Supabase, falling back to local: $e');
      _supabaseDataLoaded =
          true; // mark as done even on error to avoid retry loops
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
    _darets = [];
    _settings = Settings();
    _isLoading = false;
    _supabaseDataLoaded = false;
    _localDataLoaded = false;
    _setupComplete = false;
    _supabaseLoadInProgress = false;
    notifyListeners();
    unawaited(SupabaseSyncService.clearPendingRetryQueue());
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
    await prefs.remove('darets');
    await prefs.remove('categories');
    await prefs.remove('setup_complete');
  }

  // ============================================
  // LOCAL PERSISTENCE (SharedPreferences cache)
  // ============================================

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read raw JSON strings (fast, main thread)
      final rawJson = <String, String?>{
        'accounts': prefs.getString('accounts'),
        'transactions': prefs.getString('transactions'),
        'settings': prefs.getString('settings'),
        'recurringRules': prefs.getString('recurringRules'),
        'holdings': prefs.getString('holdings'),
        'goals': prefs.getString('goals'),
        'darets': prefs.getString('darets'),
        'categories': prefs.getString('categories'),
      };

      // Parse JSON off the main thread via isolate
      final parsed = await compute(_parseLocalData, rawJson);

      if (parsed.containsKey('accounts'))
        _accounts = parsed['accounts'] as List<Account>;
      if (parsed.containsKey('transactions'))
        _transactions = parsed['transactions'] as List<Transaction>;
      if (parsed.containsKey('settings'))
        _settings = parsed['settings'] as Settings;
      if (parsed.containsKey('recurringRules'))
        _recurringRules = parsed['recurringRules'] as List<RecurringRule>;
      if (parsed.containsKey('holdings'))
        _holdings = parsed['holdings'] as List<Holding>;
      if (parsed.containsKey('goals')) _goals = parsed['goals'] as List<Goal>;
      if (parsed.containsKey('darets'))
        _darets = parsed['darets'] as List<Daret>;
      if (parsed.containsKey('categories'))
        _categories = parsed['categories'] as List<Category>;

      _setupComplete = prefs.getBool('setup_complete') ?? false;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[AppProvider] Critical error in loadData: $e');
    } finally {
      _isLoading = false;
      _localDataLoaded = true;
      notifyListeners();
      processSalaries();
      processSubscriptions();
    }
  }

  Future<void> markSetupComplete() async {
    _setupComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    notifyListeners();
  }

  /// Debounced save — coalesces rapid mutations into a single write.
  void _saveToLocal() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDuration, _performSave);
  }

  /// Immediate save — used when we must persist right away (e.g. before dispose).
  Future<void> _performSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(
            'accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList())),
        prefs.setString('transactions',
            jsonEncode(_transactions.map((t) => t.toJson()).toList())),
        prefs.setString('settings', jsonEncode(_settings.toJson())),
        prefs.setString('recurringRules',
            jsonEncode(_recurringRules.map((r) => r.toJson()).toList())),
        prefs.setString(
            'holdings', jsonEncode(_holdings.map((h) => h.toJson()).toList())),
        prefs.setString(
            'goals', jsonEncode(_goals.map((g) => g.toJson()).toList())),
        prefs.setString(
            'darets', jsonEncode(_darets.map((d) => d.toJson()).toList())),
        prefs.setString('categories',
            jsonEncode(_categories.map((c) => c.toJson()).toList())),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppProvider] Error saving to local: $e');
    }
  }

  @override
  void notifyListeners() {
    _invalidateCache();
    super.notifyListeners();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _performSave(); // flush pending writes
    super.dispose();
  }

  // ============================================
  // ACCOUNT METHODS
  // ============================================

  void addAccount(Account account) {
    final normalized = account.addedAt == null
        ? account.copyWith(addedAt: DateTime.now().toIso8601String())
        : account;
    _accounts.add(normalized);
    _syncDebtPaymentRule(normalized);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveAccount(uid, normalized);
  }

  void updateAccount(Account account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      final normalized = account.copyWith(
        addedAt: account.addedAt ??
            _accounts[index].addedAt ??
            DateTime.now().toIso8601String(),
      );
      _accounts[index] = normalized;
      _syncDebtPaymentRule(normalized);
      _saveToLocal();
      notifyListeners();
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveAccount(uid, normalized);
    }
  }

  void deleteAccount(String id) {
    // Remove any debt-payment recurring rule linked to this account
    final ruleId = 'debt_$id';
    final ruleIdx = _recurringRules.indexWhere((r) => r.id == ruleId);
    if (ruleIdx != -1) {
      _recurringRules.removeAt(ruleIdx);
      final uid = _userId;
      if (uid != null) SupabaseSyncService.deleteRecurringRule(uid, ruleId);
    }
    _accounts.removeWhere((a) => a.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteAccount(uid, id);
  }

  /// Creates, updates, or removes the recurring rule that auto-pays a debt.
  void _syncDebtPaymentRule(Account account) {
    final ruleId = 'debt_${account.id}';
    final existingIdx = _recurringRules.indexWhere((r) => r.id == ruleId);
    final hasPayment = account.type == 'debt' &&
        account.debtPaymentAmount != null &&
        account.debtPaymentAmount! > 0;

    if (!hasPayment) {
      // Remove rule if it existed
      if (existingIdx != -1) {
        _recurringRules.removeAt(existingIdx);
        final uid = _userId;
        if (uid != null) SupabaseSyncService.deleteRecurringRule(uid, ruleId);
      }
      return;
    }

    // Compute next payment date (the upcoming day this month or next)
    final now = DateTime.now();
    final day = account.debtPaymentDay ?? 1;
    DateTime nextDate = DateTime(now.year, now.month, day);
    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(now.year, now.month + 1, day);
    }

    final sourceId = account.debtPaymentSourceId ?? cashOnHandId;

    final rule = RecurringRule(
      id: ruleId,
      frequency: 'monthly',
      nextDate: nextDate.toIso8601String(),
      isActive: true,
      templateTransaction: Transaction(
        id: '${ruleId}_template',
        type: 'expense',
        amount: account.debtPaymentAmount!,
        date: nextDate.toIso8601String(),
        accountId: sourceId,
        note: '${account.name} payment',
        categoryId: 'debt_payment',
        isRecurring: true,
        expenseSubType: 'subscription',
      ),
    );

    if (existingIdx != -1) {
      // Keep the existing nextDate if the rule already existed (don't reset the schedule)
      final existing = _recurringRules[existingIdx];
      _recurringRules[existingIdx] = rule.copyWith(nextDate: existing.nextDate);
    } else {
      _recurringRules.add(rule);
    }

    final uid = _userId;
    if (uid != null)
      SupabaseSyncService.saveRecurringRule(
          uid, _recurringRules.firstWhere((r) => r.id == ruleId));
  }

  /// Auto-credits salary for each account where today >= salaryDay and
  /// the salary has not yet been credited this calendar month.
  void processSalaries() {
    final today = DateTime.now();
    final thisMonth = '${today.year}-${today.month.toString().padLeft(2, '0')}';
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
          final idx = _accounts
              .indexWhere((a) => a.id == rule.templateTransaction.accountId);
          if (idx != -1) {
            _accounts[idx] = _accounts[idx].copyWith(
              balance: _accounts[idx].balance +
                  (isIncome
                      ? rule.templateTransaction.amount
                      : -rule.templateTransaction.amount),
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
            nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day,
                nextDate.hour, nextDate.minute);
            break;
          default: // monthly
            nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day,
                nextDate.hour, nextDate.minute);
        }

        // If this is a debt payment (Account-based), reduce the debt account balance
        if (rule.id.startsWith('debt_') && !rule.id.startsWith('debtgoal_')) {
          final debtAccountId = rule.id.substring(5); // strip 'debt_' prefix
          final debtIdx = _accounts.indexWhere((a) => a.id == debtAccountId);
          if (debtIdx != -1) {
            final newBalance =
                _accounts[debtIdx].balance - rule.templateTransaction.amount;
            _accounts[debtIdx] = _accounts[debtIdx].copyWith(
              balance: newBalance < 0 ? 0 : newBalance,
            );
          }
        }

        // If this is a Goal-based debt payment, increase the goal's currentAmount
        if (rule.id.startsWith('debtgoal_')) {
          final goalId = rule.id.substring(9); // strip 'debtgoal_' prefix
          final goalIdx = _goals.indexWhere((g) => g.id == goalId);
          if (goalIdx != -1) {
            final newPaid = (_goals[goalIdx].currentAmount +
                    rule.templateTransaction.amount)
                .clamp(0, _goals[goalIdx].targetAmount)
                .toDouble();
            _goals[goalIdx] = _goals[goalIdx].copyWith(currentAmount: newPaid);
            final uid = _userId;
            if (uid != null) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
          }
        }

        // If this is a savings goal auto-save, increase the goal's currentAmount
        if (rule.id.startsWith('savingsgoal_')) {
          final goalId = rule.id.substring(12); // strip 'savingsgoal_' prefix
          final goalIdx = _goals.indexWhere((g) => g.id == goalId);
          if (goalIdx != -1) {
            final newSaved = (_goals[goalIdx].currentAmount +
                    rule.templateTransaction.amount)
                .clamp(0, _goals[goalIdx].targetAmount)
                .toDouble();
            _goals[goalIdx] = _goals[goalIdx].copyWith(currentAmount: newSaved);
            final uid = _userId;
            if (uid != null) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
          }
        }

        // Sync transaction to Supabase
        final uid = _userId;
        if (uid != null) {
          SupabaseSyncService.saveTransaction(uid, tx);
          if (rule.templateTransaction.accountId != cashOnHandId) {
            final idx = _accounts
                .indexWhere((a) => a.id == rule.templateTransaction.accountId);
            if (idx != -1) SupabaseSyncService.saveAccount(uid, _accounts[idx]);
          }
          // Sync updated debt account balance
          if (rule.id.startsWith('debt_')) {
            final debtAccountId = rule.id.substring(5);
            final debtIdx = _accounts.indexWhere((a) => a.id == debtAccountId);
            if (debtIdx != -1)
              SupabaseSyncService.saveAccount(uid, _accounts[debtIdx]);
          }
        }
        changed = true;
      }

      if (safetyCounter > 0) {
        // Update the rule with the new nextDate (full ISO string with time)
        _recurringRules[i] =
            rule.copyWith(nextDate: nextDate.toIso8601String());

        // Auto-deactivate debt payment rules when the debt is fully paid
        if (rule.id.startsWith('debt_') && !rule.id.startsWith('debtgoal_')) {
          final debtAccountId = rule.id.substring(5);
          final debtIdx = _accounts.indexWhere((a) => a.id == debtAccountId);
          if (debtIdx != -1 && _accounts[debtIdx].balance <= 0) {
            _recurringRules[i] = _recurringRules[i].copyWith(isActive: false);
            if (kDebugMode)
              debugPrint(
                  '[AppProvider] Debt ${_accounts[debtIdx].name} fully paid — subscription deactivated');
          }
        }

        // Auto-deactivate Goal-based debt payment rules when fully paid
        if (rule.id.startsWith('debtgoal_')) {
          final goalId = rule.id.substring(9);
          final goalIdx = _goals.indexWhere((g) => g.id == goalId);
          if (goalIdx != -1 &&
              _goals[goalIdx].currentAmount >= _goals[goalIdx].targetAmount) {
            _recurringRules[i] = _recurringRules[i].copyWith(isActive: false);
            if (kDebugMode)
              debugPrint(
                  '[AppProvider] Debt goal ${_goals[goalIdx].name} fully paid — subscription deactivated');
          }
        }

        // Auto-deactivate savings goal auto-save rules when target reached
        if (rule.id.startsWith('savingsgoal_')) {
          final goalId = rule.id.substring(12);
          final goalIdx = _goals.indexWhere((g) => g.id == goalId);
          if (goalIdx != -1 &&
              _goals[goalIdx].currentAmount >= _goals[goalIdx].targetAmount) {
            _recurringRules[i] = _recurringRules[i].copyWith(isActive: false);
            if (kDebugMode)
              debugPrint(
                  '[AppProvider] Savings goal ${_goals[goalIdx].name} reached — auto-save deactivated');
          }
        }

        final uid = _userId;
        if (uid != null)
          SupabaseSyncService.saveRecurringRule(uid, _recurringRules[i]);
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
        // Deduct: expense, withdrawal, transfer, goal_contribution, debt_payment
        if (transaction.type == 'expense' ||
            transaction.type == 'withdrawal' ||
            transaction.type == 'transfer' ||
            transaction.type == 'goal_contribution' ||
            transaction.type == 'debt_payment') {
          newBalance -= transaction.totalWithFees; // amount + bank fees
        }
        // Add: income, lending_collection
        else if (transaction.type == 'income' ||
            transaction.type == 'lending_collection') {
          newBalance += transaction.amount;
        }
        _accounts[idx] = account.copyWith(balance: newBalance);
        changedAccounts.add(_accounts[idx]);
      }
    }

    // Update destination account for transfers (skip if sending to a person / cash)
    if (transaction.type == 'transfer' &&
        transaction.toAccountId != null &&
        !isCashDest) {
      final idx = _accounts.indexWhere((a) => a.id == transaction.toAccountId);
      if (idx != -1) {
        final toAccount = _accounts[idx];
        _accounts[idx] =
            toAccount.copyWith(balance: toAccount.balance + transaction.amount);
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
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = _transactions[idx];

    // Reverse the balance effect on the source account
    final changedAccounts = <dynamic>[];
    if (old.accountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == old.accountId);
      if (ai != -1) {
        double bal = _accounts[ai].balance;
        if (old.type == 'expense' ||
            old.type == 'withdrawal' ||
            old.type == 'transfer' ||
            old.type == 'goal_contribution' ||
            old.type == 'debt_payment') {
          bal += old.totalWithFees;
        } else if (old.type == 'income' || old.type == 'lending_collection') {
          bal -= old.amount;
        }
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
        changedAccounts.add(_accounts[ai]);
      }
    }
    // Reverse the balance effect on transfer destination
    if (old.type == 'transfer' &&
        old.toAccountId != null &&
        old.toAccountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == old.toAccountId);
      if (ai != -1) {
        _accounts[ai] =
            _accounts[ai].copyWith(balance: _accounts[ai].balance - old.amount);
        changedAccounts.add(_accounts[ai]);
      }
    }

    _transactions.removeAt(idx);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.deleteTransaction(uid, id);
      if (changedAccounts.isNotEmpty) {
        SupabaseSyncService.saveMultipleAccounts(uid, changedAccounts);
      }
    }
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
        if (old.type == 'expense' ||
            old.type == 'withdrawal' ||
            old.type == 'transfer' ||
            old.type == 'goal_contribution' ||
            old.type == 'debt_payment') {
          bal += old.totalWithFees;
        } else if (old.type == 'income' || old.type == 'lending_collection') {
          bal -= old.amount;
        }
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }
    // Apply new effect on account balance
    if (updated.accountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == updated.accountId);
      if (ai != -1) {
        double bal = _accounts[ai].balance;
        if (updated.type == 'expense' ||
            updated.type == 'withdrawal' ||
            updated.type == 'transfer' ||
            updated.type == 'goal_contribution' ||
            updated.type == 'debt_payment') {
          bal -= updated.totalWithFees;
        } else if (updated.type == 'income' ||
            updated.type == 'lending_collection') {
          bal += updated.amount;
        }
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }

    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, updated);
      // Sync all affected account balances
      final changedAccountIds = <String>{};
      if (old.accountId != cashOnHandId) changedAccountIds.add(old.accountId);
      if (updated.accountId != cashOnHandId)
        changedAccountIds.add(updated.accountId);
      final changedAccounts =
          _accounts.where((a) => changedAccountIds.contains(a.id)).toList();
      if (changedAccounts.isNotEmpty) {
        SupabaseSyncService.saveMultipleAccounts(uid, changedAccounts);
      }
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
    var shouldAdjustSourceBalance = holding.affectsSourceBalance &&
        holding.sourceAccountId != null &&
        holding.sourceAmount != null &&
        holding.sourceAmount! > 0;

    Account? changedAccount;
    if (shouldAdjustSourceBalance) {
      final sourceIdx =
          _accounts.indexWhere((a) => a.id == holding.sourceAccountId);
      if (sourceIdx != -1) {
        changedAccount = _accounts[sourceIdx].copyWith(
          balance: _accounts[sourceIdx].balance - holding.sourceAmount!,
        );
        _accounts[sourceIdx] = changedAccount;
      } else {
        shouldAdjustSourceBalance = false;
      }
    }

    final normalizedHolding =
        holding.copyWith(affectsSourceBalance: shouldAdjustSourceBalance);
    _holdings.add(normalizedHolding);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveHolding(uid, normalizedHolding);
      if (changedAccount != null) {
        SupabaseSyncService.saveAccount(uid, changedAccount);
      }
    }
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
      note:
          'Sold $sharesToSell × ${holding.symbol} @ \$${sellPrice.toStringAsFixed(2)}',
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
    // Also remove any goal-linked recurring rules.
    final ruleIds = ['debtgoal_$id', 'savingsgoal_$id'];
    final uid = _userId;
    for (final ruleId in ruleIds) {
      final ruleIdx = _recurringRules.indexWhere((r) => r.id == ruleId);
      if (ruleIdx != -1) {
        _recurringRules.removeAt(ruleIdx);
        if (uid != null) SupabaseSyncService.deleteRecurringRule(uid, ruleId);
      }
    }
    _goals.removeWhere((g) => g.id == id);
    _saveToLocal();
    notifyListeners();
    if (uid != null) SupabaseSyncService.deleteGoal(uid, id);
  }

  /// Creates, updates, or removes the recurring rule that auto-pays a debt goal.
  void syncDebtPaymentRuleForGoal(Goal goal) {
    final ruleId = 'debtgoal_${goal.id}';
    final existingIdx = _recurringRules.indexWhere((r) => r.id == ruleId);
    final hasPayment = goal.type == 'debt' &&
        goal.monthlyPayment != null &&
        goal.monthlyPayment! > 0;

    if (!hasPayment) {
      if (existingIdx != -1) {
        _recurringRules.removeAt(existingIdx);
        final uid = _userId;
        if (uid != null) SupabaseSyncService.deleteRecurringRule(uid, ruleId);
      }
      _saveToLocal();
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final day = goal.paymentDay ?? 1;
    DateTime nextDate = DateTime(now.year, now.month, day);
    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(now.year, now.month + 1, day);
    }

    final sourceId = goal.paymentSourceAccountId ?? cashOnHandId;

    final rule = RecurringRule(
      id: ruleId,
      frequency: 'monthly',
      nextDate: nextDate.toIso8601String(),
      isActive: true,
      templateTransaction: Transaction(
        id: '${ruleId}_template',
        type: 'expense',
        amount: goal.monthlyPayment!,
        date: nextDate.toIso8601String(),
        accountId: sourceId,
        note: '${goal.name} payment',
        categoryId: 'debt_payment',
        isRecurring: true,
        expenseSubType: 'subscription',
      ),
    );

    if (existingIdx != -1) {
      final existing = _recurringRules[existingIdx];
      _recurringRules[existingIdx] = rule.copyWith(nextDate: existing.nextDate);
    } else {
      _recurringRules.add(rule);
    }

    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null)
      SupabaseSyncService.saveRecurringRule(
          uid, _recurringRules.firstWhere((r) => r.id == ruleId));
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
  void contributeToGoalFromSource(
      String goalId, double amount, String sourceAccountId) {
    final goal =
        _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
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
        _accounts[idx] =
            _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
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
      if (changedAccount != null)
        SupabaseSyncService.saveAccount(uid, changedAccount);
      if (goalIdx != -1) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
    }
  }

  /// Pay toward a debt goal and deduct from the source.
  /// Always creates a transaction so it appears in Recent Transactions.
  /// Records money returned to someone for a personal debt (money goes OUT of sourceAccount).
  void recordPersonalDebtReturn(
      String goalId, double amount, String sourceAccountId) {
    final goal =
        _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'personal_debt_return',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Returned to ${goal.name}',
      description: goal.categoryId,
      accountId: sourceAccountId,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash handled by totalCash getter via transactions)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] =
            _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal currentAmount
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      _goals[goalIdx] = _goals[goalIdx].copyWith(
        currentAmount: (_goals[goalIdx].currentAmount + amount)
            .clamp(0, _goals[goalIdx].targetAmount),
      );
    }

    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (changedAccount != null)
        SupabaseSyncService.saveAccount(uid, changedAccount);
      if (goalIdx != -1) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
    }
  }

  /// Records money received from a personal debt (someone returning money to you).
  /// Adds amount to the target account and marks the debt as partially/fully returned.
  void receiveDebtPayment(
      String goalId, double amount, String targetAccountId) {
    final goal =
        _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'income',
      amount: amount,
      date: DateTime.now().toIso8601String(),
      note: 'Received: ${goal.name}',
      accountId: targetAccountId,
      categoryId: 'debt_payment',
    );
    _transactions.add(txn);

    Account? changedAccount;
    // ADD to target account (positive inflow)
    if (targetAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == targetAccountId);
      if (idx != -1) {
        _accounts[idx] =
            _accounts[idx].copyWith(balance: _accounts[idx].balance + amount);
        changedAccount = _accounts[idx];
      }
    }
    // If cash: totalCash getter automatically includes income transactions

    // Update goal currentAmount (tracks how much has been returned)
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      _goals[goalIdx] = _goals[goalIdx].copyWith(
        currentAmount: (_goals[goalIdx].currentAmount + amount)
            .clamp(0, _goals[goalIdx].targetAmount),
      );
    }

    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (changedAccount != null)
        SupabaseSyncService.saveAccount(uid, changedAccount);
      if (goalIdx != -1) SupabaseSyncService.saveGoal(uid, _goals[goalIdx]);
    }
  }

  void payDebt(String goalId, double amount, String sourceAccountId) {
    final goal =
        _goals.firstWhere((g) => g.id == goalId, orElse: () => _goals.first);
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
        _accounts[idx] =
            _accounts[idx].copyWith(balance: _accounts[idx].balance - amount);
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
      if (changedAccount != null)
        SupabaseSyncService.saveAccount(uid, changedAccount);
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
        .where((t) =>
            t.type == 'expense' &&
            t.categoryId == categoryId &&
            DateTime.parse(t.date)
                .isAfter(startOfMonth.subtract(const Duration(days: 1))))
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
  }

  void setThemeMode(String mode) {
    // mode: 'light', 'dark', 'system'
    _settings = _settings.copyWith(
      themeMode: mode,
      isDarkMode: mode == 'dark',
    );
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, _settings);
  }

  void setLocale(String locale) {
    _settings = _settings.copyWith(locale: locale);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, _settings);
  }

  // ============================================
  // CALCULATIONS (read-only, no sync needed)
  // ============================================

  double get totalCash {
    if (_cachedTotalCash != null) return _cachedTotalCash!;
    double cash = 0;
    for (final t in _transactions) {
      if (t.type == 'withdrawal') {
        cash += t.amount; // Cash received (fees already deducted from bank)
      } else if (t.accountId == cashOnHandId) {
        if (t.type == 'expense' ||
            t.type == 'transfer' ||
            t.type == 'goal_contribution' ||
            t.type == 'debt_payment') {
          cash -= t.totalWithFees;
        } else if (t.type == 'income' || t.type == 'lending_collection') {
          cash += t.amount;
        }
      }
      if (t.type == 'transfer' && t.toAccountId == cashOnHandId) {
        cash += t.amount;
      }
    }
    _cachedTotalCash = cash;
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
    if (_cachedNetWorth != null) return _cachedNetWorth!;
    // Non-investment accounts with includeInNetWorth
    final bankAssets = _accounts
        .where((a) => a.includeInNetWorth && a.type != 'investment')
        .fold(0.0, (sum, a) => sum + a.balance);
    final cash = totalCash;
    // Investment account balances + portfolio positions
    final investments = totalInvestmentValue;
    // Savings goal amounts (money set aside - already deducted from account balance)
    final savingsAmounts = totalSavingsGoals;
    final debtRemaining = _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    final personalDebtRemaining = _goals
        .where((g) => g.type == 'personal_debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    _cachedNetWorth = bankAssets +
        cash +
        investments +
        savingsAmounts -
        debtRemaining +
        personalDebtRemaining;
    return _cachedNetWorth!;
  }

  double get totalSavingsTarget {
    return _goals
        .where(_isSavingsGoal)
        .fold<double>(0.0, (sum, g) => sum + g.targetAmount);
  }

  /// Balance for a specific account, or combined balance of all non-investment
  /// accounts + cash when [accountId] is null.
  double getBalanceForAccount(String? accountId) {
    if (accountId != null) {
      return _accounts
          .where((a) => a.id == accountId)
          .fold(0.0, (sum, a) => sum + a.balance);
    }
    final bankBalance = _accounts
        .where((a) => a.type != 'investment')
        .fold(0.0, (sum, a) => sum + a.balance);
    return bankBalance + totalCash;
  }

  /// Investment value for a specific account (if it's an investment type),
  /// or total investment value when [accountId] is null or non-investment.
  double getInvestmentValueForAccount(String? accountId) {
    if (accountId != null) {
      final acct = _accounts.where((a) => a.id == accountId).firstOrNull;
      if (acct != null && acct.type == 'investment') {
        return acct.balance + getTotalPortfolioValue();
      }
    }
    return totalInvestmentValue;
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
    if (_cachedTotalSavingsGoals != null) return _cachedTotalSavingsGoals!;
    _cachedTotalSavingsGoals = _goals
        .where(_isSavingsGoal)
        .fold<double>(0.0, (sum, g) => sum + g.currentAmount);
    return _cachedTotalSavingsGoals!;
  }

  bool _isSavingsGoal(Goal goal) {
    return goal.type == 'savings' ||
        goal.type == 'goal' ||
        goal.type == 'custom';
  }

  double get totalDebtRemaining {
    if (_cachedTotalDebtRemaining != null) return _cachedTotalDebtRemaining!;
    _cachedTotalDebtRemaining = _goals
        .where((g) => g.type == 'debt')
        .fold<double>(
            0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    return _cachedTotalDebtRemaining!;
  }

  double get totalInvestmentValue {
    if (_cachedTotalInvestmentValue != null)
      return _cachedTotalInvestmentValue!;
    // Investment account balances + portfolio (holdings) value
    final investmentAccounts = _accounts
        .where((a) => a.type == 'investment')
        .fold(0.0, (sum, a) => sum + a.balance);
    _cachedTotalInvestmentValue = investmentAccounts + getTotalPortfolioValue();
    return _cachedTotalInvestmentValue!;
  }

  // ============================================
  // DARET (ROSCA) METHODS
  // ============================================

  void addDaret(Daret daret) {
    _darets.add(daret);
    _syncDaretRecurringRule(daret);
    _saveToLocal();
    notifyListeners();
  }

  void updateDaret(Daret daret) {
    final index = _darets.indexWhere((d) => d.id == daret.id);
    if (index != -1) {
      _darets[index] = daret;
      _syncDaretRecurringRule(daret);
      _saveToLocal();
      notifyListeners();
    }
  }

  void deleteDaret(String id) {
    // Remove recurring rules
    final contribRuleId = 'daret_contrib_$id';
    _recurringRules.removeWhere((r) => r.id == contribRuleId);
    _darets.removeWhere((d) => d.id == id);
    _saveToLocal();
    notifyListeners();
  }

  /// Creates or updates the monthly contribution recurring rule for a daret.
  void _syncDaretRecurringRule(Daret daret) {
    final ruleId = 'daret_contrib_${daret.id}';
    final existingIdx = _recurringRules.indexWhere((r) => r.id == ruleId);

    if (!daret.isActive || daret.isComplete) {
      if (existingIdx != -1) {
        _recurringRules.removeAt(existingIdx);
      }
      return;
    }

    final now = DateTime.now();
    final day = daret.paymentDay;
    DateTime nextDate = DateTime(now.year, now.month, day);
    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(now.year, now.month + 1, day);
    }

    final rule = RecurringRule(
      id: ruleId,
      frequency: 'monthly',
      nextDate: nextDate.toIso8601String(),
      isActive: true,
      templateTransaction: Transaction(
        id: '${ruleId}_template',
        type: 'daret_contribution',
        amount: daret.monthlyPayment,
        date: nextDate.toIso8601String(),
        accountId: daret.paymentSourceId,
        note: 'Daret: ${daret.name}',
        categoryId: daret.id,
        isRecurring: true,
      ),
    );

    if (existingIdx != -1) {
      final existing = _recurringRules[existingIdx];
      _recurringRules[existingIdx] = rule.copyWith(nextDate: existing.nextDate);
    } else {
      _recurringRules.add(rule);
    }
  }

  /// Process monthly daret contribution: deduct from source account.
  void processDaretContribution(String daretId) {
    final idx = _darets.indexWhere((d) => d.id == daretId);
    if (idx == -1) return;
    final daret = _darets[idx];

    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'daret_contribution',
      amount: daret.monthlyPayment,
      date: DateTime.now().toIso8601String(),
      note: 'Daret: ${daret.name}',
      accountId: daret.paymentSourceId,
      categoryId: daret.id,
    );
    _transactions.add(txn);

    // Deduct from source account
    if (daret.paymentSourceId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == daret.paymentSourceId);
      if (ai != -1) {
        _accounts[ai] = _accounts[ai].copyWith(
          balance: _accounts[ai].balance - daret.monthlyPayment,
        );
      }
    }

    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (daret.paymentSourceId != cashOnHandId) {
        final ai = _accounts.indexWhere((a) => a.id == daret.paymentSourceId);
        if (ai != -1) SupabaseSyncService.saveAccount(uid, _accounts[ai]);
      }
    }
  }

  /// Check and process daret payout for the current month.
  void checkDaretPayout(String daretId) {
    final idx = _darets.indexWhere((d) => d.id == daretId);
    if (idx == -1) return;
    final daret = _darets[idx];

    if (!daret.payoutMonths.contains(daret.currentMonth)) return;

    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'daret_payout',
      amount: daret.singlePayoutAmount,
      date: DateTime.now().toIso8601String(),
      note: 'Daret payout: ${daret.name} (Month ${daret.currentMonth})',
      accountId: daret.destinationAccountId,
      categoryId: daret.id,
    );
    _transactions.add(txn);

    // Credit destination account
    if (daret.destinationAccountId != cashOnHandId) {
      final ai =
          _accounts.indexWhere((a) => a.id == daret.destinationAccountId);
      if (ai != -1) {
        _accounts[ai] = _accounts[ai].copyWith(
          balance: _accounts[ai].balance + daret.singlePayoutAmount,
        );
      }
    }

    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveTransaction(uid, txn);
      if (daret.destinationAccountId != cashOnHandId) {
        final ai =
            _accounts.indexWhere((a) => a.id == daret.destinationAccountId);
        if (ai != -1) SupabaseSyncService.saveAccount(uid, _accounts[ai]);
      }
    }
  }

  /// Get total net position across all active darets
  /// (totalReceived - totalPaid so far)
  double get totalDaretNetPosition {
    return _darets.where((d) => d.isActive).fold(0.0, (sum, d) {
      return sum + d.totalReceivedSoFar - d.totalPaidSoFar;
    });
  }

  /// Get total remaining liability across all active darets
  double get totalDaretLiability {
    return _darets.where((d) => d.isActive).fold(0.0, (sum, d) {
      return sum + d.remainingLiability;
    });
  }
}
