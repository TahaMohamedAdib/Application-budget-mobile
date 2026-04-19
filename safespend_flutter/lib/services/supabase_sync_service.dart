import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../models/holding.dart';
import '../models/category.dart';
import '../models/settings.dart';

enum _SyncOperationType {
  saveProfile,
  saveAccount,
  saveMultipleAccounts,
  deleteAccount,
  saveTransaction,
  deleteTransaction,
  saveGoal,
  deleteGoal,
  saveRecurringRule,
  deleteRecurringRule,
  saveHolding,
  deleteHolding,
  saveCategory,
  deleteCategory,
  saveConversation,
  saveAllConversations,
  deleteConversation,
  saveProject,
  deleteProject,
}

class _QueuedSyncOperation {
  const _QueuedSyncOperation({
    required this.type,
    required this.userId,
    this.payload,
  });

  final _SyncOperationType type;
  final String userId;
  final Object? payload;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'userId': userId,
    'payload': payload,
  };

  factory _QueuedSyncOperation.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = _SyncOperationType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => _SyncOperationType.saveProfile,
    );

    return _QueuedSyncOperation(
      type: type,
      userId: json['userId'] as String? ?? '',
      payload: json['payload'],
    );
  }
}

class SupabaseSyncService {
  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Throws if Supabase is unavailable — callers must be wrapped in try-catch.
  static SupabaseClient get _db {
    final c = _client;
    if (c == null) throw Exception('Supabase not available (local mode)');
    return c;
  }

  static String? get currentUserId => _client?.auth.currentUser?.id;

  // ── Retry queue for failed sync operations ──
  static final List<_QueuedSyncOperation> _retryQueue = [];
  static bool _retrying = false;
  static bool _offlineSyncInitialized = false;
  static SharedPreferences? _prefs;
  static Connectivity? _connectivity;
  static StreamSubscription<dynamic>? _connectivitySubscription;
  static const String _retryQueueStorageKey = 'supabase_retry_queue_v1';

  static Future<void> initializeOfflineSync() async {
    if (_offlineSyncInitialized) return;

    _prefs ??= await SharedPreferences.getInstance();
    _connectivity ??= Connectivity();
    await _loadRetryQueueFromStorage();
    _offlineSyncInitialized = true;

    _connectivitySubscription ??=
        _connectivity!.onConnectivityChanged.listen((dynamic result) {
      if (_hasConnection(result)) {
        unawaited(flushRetryQueue());
      }
    });

    try {
      final current = await _connectivity!.checkConnectivity();
      if (_hasConnection(current)) {
        unawaited(flushRetryQueue());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Supabase] Connectivity bootstrap failed: $e');
      }
    }
  }

  static Future<void> _loadRetryQueueFromStorage() async {
    final raw = _prefs?.getString(_retryQueueStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _retryQueue
        ..clear()
        ..addAll(decoded.map((item) => _QueuedSyncOperation.fromJson(
              Map<String, dynamic>.from(item as Map),
            )));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Supabase] Failed to restore retry queue: $e');
      }
      _retryQueue.clear();
      await _prefs?.remove(_retryQueueStorageKey);
    }
  }

  static Future<void> _persistRetryQueue() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_retryQueue.isEmpty) {
      await _prefs!.remove(_retryQueueStorageKey);
      return;
    }

    final encoded =
        jsonEncode(_retryQueue.map((operation) => operation.toJson()).toList());
    await _prefs!.setString(_retryQueueStorageKey, encoded);
  }

  static bool _hasConnection(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((entry) => entry != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  static Future<bool> _isProbablyOnline() async {
    try {
      await initializeOfflineSync();
      final connectivity = _connectivity;
      if (connectivity == null) return true;
      final current = await connectivity.checkConnectivity();
      return _hasConnection(current);
    } catch (_) {
      return true;
    }
  }

  static Future<void> _enqueueRetry(_QueuedSyncOperation operation) async {
    _retryQueue.add(operation);
    await _persistRetryQueue();
  }

  static Future<void> _syncWithRetry(
    _QueuedSyncOperation queuedOperation,
    Future<void> Function() operation,
  ) async {
    await initializeOfflineSync();

    if (!await _isProbablyOnline()) {
      if (kDebugMode) {
        debugPrint(
            '[Supabase] Offline detected, queued ${queuedOperation.type.name}');
      }
      await _enqueueRetry(queuedOperation);
      return;
    }

    try {
      await operation();
      if (_retryQueue.isNotEmpty) {
        unawaited(flushRetryQueue());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Supabase] Sync failed, queued for retry: $e');
      }
      await _enqueueRetry(queuedOperation);
    }
  }

  static Future<void> flushRetryQueue() async {
    await initializeOfflineSync();
    if (_retrying || _retryQueue.isEmpty) return;
    final activeUserId = currentUserId;
    if (activeUserId == null) return;

    _retrying = true;
    try {
      final pending = List<_QueuedSyncOperation>.from(_retryQueue);
      _retryQueue.clear();
      await _persistRetryQueue();

      for (final op in pending) {
        if (op.userId != activeUserId) {
          _retryQueue.add(op);
          continue;
        }

        try {
          await _performQueuedOperation(op);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[Supabase] Retry still failing: $e');
          }
          _retryQueue.add(op);
        }
      }
    } finally {
      await _persistRetryQueue();
      _retrying = false;
    }
  }

  static int get pendingRetryCount => _retryQueue.length;

  static Future<bool> hasPendingOperationsForUser(String userId) async {
    await initializeOfflineSync();
    return _retryQueue.any((operation) => operation.userId == userId);
  }

  static Future<void> clearPendingRetryQueue({String? userId}) async {
    await initializeOfflineSync();
    if (userId == null) {
      _retryQueue.clear();
    } else {
      _retryQueue.removeWhere((operation) => operation.userId == userId);
    }
    await _persistRetryQueue();
  }

  static Map<String, dynamic> _payloadAsMap(Object? payload) =>
      Map<String, dynamic>.from(payload as Map);

  static List<Map<String, dynamic>> _payloadAsMapList(Object? payload) =>
      (payload as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();

  static Future<void> _performQueuedOperation(
      _QueuedSyncOperation operation) async {
    switch (operation.type) {
      case _SyncOperationType.saveProfile:
        await _saveProfileRemote(
          operation.userId,
          Settings.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.saveAccount:
        await _saveAccountRemote(
          operation.userId,
          Account.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.saveMultipleAccounts:
        await _saveMultipleAccountsRemote(
          operation.userId,
          _payloadAsMapList(operation.payload)
              .map(Account.fromJson)
              .toList(),
        );
        return;
      case _SyncOperationType.deleteAccount:
        await _deleteAccountRemote(operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveTransaction:
        await _saveTransactionRemote(
          operation.userId,
          Transaction.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.deleteTransaction:
        await _deleteTransactionRemote(
            operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveGoal:
        await _saveGoalRemote(
          operation.userId,
          Goal.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.deleteGoal:
        await _deleteGoalRemote(operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveRecurringRule:
        await _saveRecurringRuleRemote(
          operation.userId,
          RecurringRule.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.deleteRecurringRule:
        await _deleteRecurringRuleRemote(
            operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveHolding:
        await _saveHoldingRemote(
          operation.userId,
          Holding.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.deleteHolding:
        await _deleteHoldingRemote(operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveCategory:
        await _saveCategoryRemote(
          operation.userId,
          Category.fromJson(_payloadAsMap(operation.payload)),
        );
        return;
      case _SyncOperationType.deleteCategory:
        await _deleteCategoryRemote(
            operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveConversation:
        await _saveConversationRemote(
          operation.userId,
          _payloadAsMap(operation.payload),
        );
        return;
      case _SyncOperationType.saveAllConversations:
        await _saveAllConversationsRemote(
          operation.userId,
          _payloadAsMapList(operation.payload),
        );
        return;
      case _SyncOperationType.deleteConversation:
        await _deleteConversationRemote(
            operation.userId, operation.payload as String);
        return;
      case _SyncOperationType.saveProject:
        await _saveProjectRemote(
          operation.userId,
          _payloadAsMap(operation.payload),
        );
        return;
      case _SyncOperationType.deleteProject:
        await _deleteProjectRemote(
            operation.userId, operation.payload as String);
        return;
    }
  }

  // ============================================
  // PROFILE / SETTINGS
  // ============================================

  static Future<Settings?> loadProfile(String userId) async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return Settings(
        currency: data['currency'] ?? 'USD',
        monthlyIncome: (data['monthly_income'] as num?)?.toDouble() ?? 0,
        isDarkMode: (data['theme'] ?? 'dark') == 'dark',
        netWorthScope: data['net_worth_scope'] ?? 'all',
        selectedAccountId: data['selected_account_id'],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading profile: $e');
      return null;
    }
  }

  static Future<void> _saveProfileRemote(String userId, Settings settings) async {
    await _db.from('profiles').upsert({
      'id': userId,
      'currency': settings.currency,
      'monthly_income': settings.monthlyIncome,
      'theme': settings.isDarkMode ? 'dark' : 'light',
      'net_worth_scope': settings.netWorthScope,
      'selected_account_id': settings.selectedAccountId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveProfile(String userId, Settings settings) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveProfile,
        userId: userId,
        payload: settings.toJson(),
      ),
      () => _saveProfileRemote(userId, settings),
    );
  }

  // ============================================
  // ACCOUNTS
  // ============================================

  static Map<String, dynamic> _accountToRow(String userId, Account a) => {
    'id': a.id,
    'user_id': userId,
    'type': a.type,
    'name': a.name,
    'balance': a.balance,
    'color': a.color ?? '#B8860B',
    'icon': a.imagePath,
    'bank_name': a.bankName,
    'include_in_net_worth': a.includeInNetWorth,
    'image_path': a.imagePath,
    'added_at': a.addedAt,
    'salary_amount': a.salaryAmount,
    'salary_day': a.salaryDay,
    'last_salary_date': a.lastSalaryDate,
    'debt_payment_amount': a.debtPaymentAmount,
    'debt_payment_day': a.debtPaymentDay,
    'debt_payment_source_id': a.debtPaymentSourceId,
    'updated_at': DateTime.now().toIso8601String(),
  };

  static Account _rowToAccount(Map<String, dynamic> a) => Account(
    id: a['id'],
    type: a['type'] ?? 'bank',
    name: a['name'] ?? '',
    balance: (a['balance'] as num?)?.toDouble() ?? 0,
    bankName: a['bank_name'],
    color: a['color'],
    includeInNetWorth: a['include_in_net_worth'] ?? true,
    imagePath: a['image_path'] ?? a['icon'],
    addedAt: a['added_at'] ?? a['created_at'],
    salaryAmount: (a['salary_amount'] as num?)?.toDouble(),
    salaryDay: a['salary_day'] as int?,
    lastSalaryDate: a['last_salary_date'],
    debtPaymentAmount: (a['debt_payment_amount'] as num?)?.toDouble(),
    debtPaymentDay: a['debt_payment_day'] as int?,
    debtPaymentSourceId: a['debt_payment_source_id'] as String?,
  );

  static Future<List<Account>> loadAccounts(String userId) async {
    try {
      final data = await _db
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return data.map<Account>(_rowToAccount).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading accounts: $e');
      return [];
    }
  }

  static Future<void> _saveAccountRemote(String userId, Account account) async {
    await _db.from('accounts').upsert(_accountToRow(userId, account));
  }

  static Future<void> saveAccount(String userId, Account account) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveAccount,
        userId: userId,
        payload: account.toJson(),
      ),
      () => _saveAccountRemote(userId, account),
    );
  }

  static Future<void> _saveMultipleAccountsRemote(
      String userId, List<Account> accounts) async {
    final rows = accounts.map((account) => _accountToRow(userId, account)).toList();
    await _db.from('accounts').upsert(rows);
  }

  static Future<void> saveMultipleAccounts(
      String userId, List<dynamic> accounts) async {
    if (accounts.isEmpty) return;
    final normalized = accounts.map((account) => account as Account).toList();
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveMultipleAccounts,
        userId: userId,
        payload: normalized.map((account) => account.toJson()).toList(),
      ),
      () => _saveMultipleAccountsRemote(userId, normalized),
    );
  }

  static Future<void> _deleteAccountRemote(String userId, String accountId) async {
    await _db
        .from('accounts')
        .delete()
        .eq('id', accountId)
        .eq('user_id', userId);
  }

  static Future<void> deleteAccount(String userId, String accountId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteAccount,
        userId: userId,
        payload: accountId,
      ),
      () => _deleteAccountRemote(userId, accountId),
    );
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  static Map<String, dynamic> _transactionToRow(String userId, Transaction t) => {
    'id': t.id,
    'user_id': userId,
    'account_id': t.accountId.isEmpty ? null : t.accountId,
    'to_account_id': t.toAccountId,
    'type': t.type,
    'amount': t.amount,
    'category_id': t.categoryId,
    'note': t.note,
    'date': t.date,
    'is_recurring': t.isRecurring,
    'image_path': t.imagePath,
    'expense_sub_type': t.expenseSubType,
    'fees': t.fees,
  };

  static Transaction _rowToTransaction(Map<String, dynamic> t) => Transaction(
    id: t['id'],
    type: t['type'] ?? 'expense',
    amount: (t['amount'] as num?)?.toDouble() ?? 0,
    fees: (t['fees'] as num?)?.toDouble() ?? 0,
    date: t['date'] ?? DateTime.now().toIso8601String(),
    accountId: t['account_id'] ?? '',
    toAccountId: t['to_account_id'],
    categoryId: t['category_id'],
    note: t['note'],
    isRecurring: t['is_recurring'] ?? false,
    imagePath: t['image_path'],
    expenseSubType: t['expense_sub_type'],
  );

  static Future<List<Transaction>> loadTransactions(String userId) async {
    try {
      final data = await _db
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);
      return data.map<Transaction>(_rowToTransaction).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading transactions: $e');
      return [];
    }
  }

  static Future<void> _saveTransactionRemote(
      String userId, Transaction transaction) async {
    await _db.from('transactions').upsert(_transactionToRow(userId, transaction));
  }

  static Future<void> saveTransaction(String userId, Transaction transaction) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveTransaction,
        userId: userId,
        payload: transaction.toJson(),
      ),
      () => _saveTransactionRemote(userId, transaction),
    );
  }

  static Future<void> _deleteTransactionRemote(
      String userId, String transactionId) async {
    await _db
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);
  }

  static Future<void> deleteTransaction(String userId, String transactionId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteTransaction,
        userId: userId,
        payload: transactionId,
      ),
      () => _deleteTransactionRemote(userId, transactionId),
    );
  }

  // ============================================
  // STORAGE — RECEIPTS
  // ============================================

  /// Uploads a local image file to Supabase Storage bucket 'receipts'.
  /// Returns the public URL on success, or null if upload fails.
  static Future<String?> uploadReceipt(String userId, String localPath) async {
    return _uploadToStorage(userId, localPath, 'receipts');
  }

  /// Uploads a local image file to Supabase Storage bucket 'logos'.
  /// Returns the public URL on success, or null if upload fails.
  static Future<String?> uploadAccountLogo(String userId, String localPath) async {
    return _uploadToStorage(userId, localPath, 'logos');
  }

  static Future<String?> _uploadToStorage(String userId, String localPath, String bucket) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      // Receipts/photos are compressed before upload to save storage space.
      // All image uploads (receipts and logos) are compressed before storing.
      final Uint8List bytes = await ImageService.compressReceipt(localPath);
      const String ext = 'jpg';

      final fileName = '$userId/${const Uuid().v4()}.$ext';
      await _db.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      return _db.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase Storage] Error uploading to $bucket: $e');
      return null;
    }
  }

  // ============================================
  // GOALS
  // ============================================

  static Map<String, dynamic> _goalToRow(String userId, Goal g) => {
    'id': g.id,
    'user_id': userId,
    'type': g.type,
    'name': g.name,
    'target_amount': g.targetAmount,
    'current_amount': g.currentAmount,
    'target_date': g.targetDate,
    'priority': g.priority,
    'category_id': g.categoryId,
    'icon': g.icon,
    'color': g.color,
    'monthly_payment': g.monthlyPayment,
    'payment_day': g.paymentDay,
    'payment_source_account_id': g.paymentSourceAccountId,
    'updated_at': DateTime.now().toIso8601String(),
  };

  static Goal _rowToGoal(Map<String, dynamic> g) => Goal(
    id: g['id'],
    type: g['type'] ?? 'savings',
    name: g['name'] ?? '',
    targetAmount: (g['target_amount'] as num?)?.toDouble() ?? 0,
    currentAmount: (g['current_amount'] as num?)?.toDouble() ?? 0,
    targetDate: g['target_date'],
    priority: g['priority'] ?? 1,
    categoryId: g['category_id'],
    icon: g['icon'] ?? '\u{1F3AF}',
    color: g['color'] ?? '#B8860B',
    monthlyPayment: (g['monthly_payment'] as num?)?.toDouble(),
    paymentDay: g['payment_day'] as int?,
    paymentSourceAccountId: g['payment_source_account_id'] as String?,
  );

  static Future<List<Goal>> loadGoals(String userId) async {
    try {
      final data = await _db
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return data.map<Goal>(_rowToGoal).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading goals: $e');
      return [];
    }
  }

  static Future<void> _saveGoalRemote(String userId, Goal goal) async {
    await _db.from('goals').upsert(_goalToRow(userId, goal));
  }

  static Future<void> saveGoal(String userId, Goal goal) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveGoal,
        userId: userId,
        payload: goal.toJson(),
      ),
      () => _saveGoalRemote(userId, goal),
    );
  }

  static Future<void> _deleteGoalRemote(String userId, String goalId) async {
    await _db
        .from('goals')
        .delete()
        .eq('id', goalId)
        .eq('user_id', userId);
  }

  static Future<void> deleteGoal(String userId, String goalId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteGoal,
        userId: userId,
        payload: goalId,
      ),
      () => _deleteGoalRemote(userId, goalId),
    );
  }

  // ============================================
  // RECURRING RULES
  // ============================================

  static Map<String, dynamic> _ruleToRow(String userId, RecurringRule rule) => {
    'id': rule.id,
    'user_id': userId,
    'cadence': rule.frequency,
    'next_date': rule.nextDate,
    'is_active': rule.isActive,
    'amount': rule.templateTransaction.amount,
    'category_id': rule.templateTransaction.categoryId,
    'note': rule.templateTransaction.note,
    'template_account_id': rule.templateTransaction.accountId.isEmpty
        ? null
        : rule.templateTransaction.accountId,
    'template_to_account_id': rule.templateTransaction.toAccountId,
    'template_type': rule.templateTransaction.type,
    'template_merchant': rule.templateTransaction.note,
    'template_is_recurring': true,
    'updated_at': DateTime.now().toIso8601String(),
  };

  static RecurringRule _rowToRule(Map<String, dynamic> r) => RecurringRule(
    id: r['id'],
    frequency: r['cadence'] ?? 'monthly',
    nextDate: r['next_date'] ?? DateTime.now().toIso8601String(),
    isActive: r['is_active'] ?? true,
    templateTransaction: Transaction(
      id: '${r['id']}_template',
      amount: (r['amount'] as num?)?.toDouble() ?? 0,
      type: r['template_type'] ?? 'expense',
      accountId: r['template_account_id'] ?? '',
      toAccountId: r['template_to_account_id'],
      categoryId: r['category_id'],
      note: r['note'],
      date: r['next_date'] ?? DateTime.now().toIso8601String(),
      isRecurring: true,
    ),
  );

  static Future<List<RecurringRule>> loadRecurringRules(String userId) async {
    try {
      final data = await _db
          .from('recurring_rules')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return data.map<RecurringRule>(_rowToRule).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading recurring rules: $e');
      return [];
    }
  }

  static Future<void> _saveRecurringRuleRemote(
      String userId, RecurringRule rule) async {
    await _db.from('recurring_rules').upsert(_ruleToRow(userId, rule));
  }

  static Future<void> saveRecurringRule(String userId, RecurringRule rule) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveRecurringRule,
        userId: userId,
        payload: rule.toJson(),
      ),
      () => _saveRecurringRuleRemote(userId, rule),
    );
  }

  static Future<void> _deleteRecurringRuleRemote(
      String userId, String ruleId) async {
    await _db
        .from('recurring_rules')
        .delete()
        .eq('id', ruleId)
        .eq('user_id', userId);
  }

  static Future<void> deleteRecurringRule(String userId, String ruleId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteRecurringRule,
        userId: userId,
        payload: ruleId,
      ),
      () => _deleteRecurringRuleRemote(userId, ruleId),
    );
  }

  // ============================================
  // STOCK HOLDINGS (Portfolio)
  // ============================================

  static Map<String, dynamic> _holdingToRow(String userId, Holding h) => {
    'id': h.id,
    'user_id': userId,
    'ticker': h.symbol,
    'title': h.title,
    'quantity': h.shares,
    'buy_price': h.costBasis,
    'current_price': h.currentPrice,
    'notes': h.notes,
    'purchase_date': h.purchaseDate,
    'source_account_id': h.sourceAccountId,
    'affects_source_balance': h.affectsSourceBalance,
    'source_amount': h.sourceAmount,
    'last_updated': DateTime.now().toIso8601String(),
  };

  static Holding _rowToHolding(Map<String, dynamic> h) => Holding(
    id: h['id'],
    symbol: h['ticker'] ?? '',
    title: h['title'],
    shares: (h['quantity'] as num?)?.toDouble() ?? 0,
    costBasis: (h['buy_price'] as num?)?.toDouble() ?? 0,
    currentPrice: (h['current_price'] as num?)?.toDouble() ?? 0,
    notes: h['notes'],
    purchaseDate: h['purchase_date'] as String?,
    sourceAccountId: h['source_account_id'] as String?,
    affectsSourceBalance: h['affects_source_balance'] ?? false,
    sourceAmount: (h['source_amount'] as num?)?.toDouble(),
  );

  static Future<List<Holding>> loadHoldings(String userId) async {
    try {
      final data = await _db
          .from('stock_holdings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return data.map<Holding>(_rowToHolding).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading holdings: $e');
      return [];
    }
  }

  static Future<void> _saveHoldingRemote(String userId, Holding holding) async {
    await _db.from('stock_holdings').upsert(_holdingToRow(userId, holding));
  }

  static Future<void> saveHolding(String userId, Holding holding) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveHolding,
        userId: userId,
        payload: holding.toJson(),
      ),
      () => _saveHoldingRemote(userId, holding),
    );
  }

  static Future<void> _deleteHoldingRemote(
      String userId, String holdingId) async {
    await _db
        .from('stock_holdings')
        .delete()
        .eq('id', holdingId)
        .eq('user_id', userId);
  }

  static Future<void> deleteHolding(String userId, String holdingId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteHolding,
        userId: userId,
        payload: holdingId,
      ),
      () => _deleteHoldingRemote(userId, holdingId),
    );
  }

  // ============================================
  // USER CATEGORIES
  // ============================================

  static Map<String, dynamic> _categoryToRow(String userId, Category c) => {
    'user_id': userId,
    'category_id': c.id,
    'group_name': c.group,
    'name': c.name,
    'icon': c.icon,
    'color': c.color,
    'budget_limit': c.budgetLimit,
  };

  static Category _rowToCategory(Map<String, dynamic> c) => Category(
    id: c['category_id'] ?? c['id'],
    name: c['name'] ?? '',
    group: c['group_name'] ?? 'variable',
    icon: c['icon'] ?? 'category',
    color: c['color'] ?? '#22c55e',
    budgetLimit: (c['budget_limit'] as num?)?.toDouble() ?? 0,
  );

  static Future<List<Category>> loadCategories(String userId) async {
    try {
      final data = await _db
          .from('user_categories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return data.map<Category>(_rowToCategory).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading categories: $e');
      return [];
    }
  }

  static Future<void> _saveCategoryRemote(
      String userId, Category category) async {
    await _db.from('user_categories').upsert(
      _categoryToRow(userId, category),
      onConflict: 'user_id,category_id',
    );
  }

  static Future<void> saveCategory(String userId, Category category) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveCategory,
        userId: userId,
        payload: category.toJson(),
      ),
      () => _saveCategoryRemote(userId, category),
    );
  }

  static Future<void> _deleteCategoryRemote(
      String userId, String categoryId) async {
    await _db
        .from('user_categories')
        .delete()
        .eq('category_id', categoryId)
        .eq('user_id', userId);
  }

  static Future<void> deleteCategory(String userId, String categoryId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteCategory,
        userId: userId,
        payload: categoryId,
      ),
      () => _deleteCategoryRemote(userId, categoryId),
    );
  }

  // ============================================
  // AI CONVERSATIONS
  // ============================================

  static Future<List<Map<String, dynamic>>> loadConversations(String userId) async {
    try {
      final data = await _db
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading conversations: $e');
      return [];
    }
  }

  static Future<void> _saveConversationRemote(
      String userId, Map<String, dynamic> convoJson) async {
    await _db.from('ai_conversations').upsert({
      'id': convoJson['id'],
      'user_id': userId,
      'title': convoJson['title'],
      'messages': convoJson['messages'],
      'history': convoJson['history'],
      'is_archived': convoJson['isArchived'] ?? false,
      'project_id': convoJson['projectId'],
      'created_at': convoJson['createdAt'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveConversation(String userId, Map<String, dynamic> convoJson) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveConversation,
        userId: userId,
        payload: convoJson,
      ),
      () => _saveConversationRemote(userId, convoJson),
    );
  }

  static Future<void> _saveAllConversationsRemote(
      String userId, List<Map<String, dynamic>> convos) async {
    final rows = convos.map((c) => {
          'id': c['id'],
          'user_id': userId,
          'title': c['title'],
          'messages': c['messages'],
          'history': c['history'],
          'is_archived': c['isArchived'] ?? false,
          'project_id': c['projectId'],
          'created_at': c['createdAt'],
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();
    await _db.from('ai_conversations').upsert(rows);
  }

  static Future<void> saveAllConversations(String userId, List<Map<String, dynamic>> convos) async {
    if (convos.isEmpty) return;
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveAllConversations,
        userId: userId,
        payload: convos,
      ),
      () => _saveAllConversationsRemote(userId, convos),
    );
  }

  static Future<void> _deleteConversationRemote(
      String userId, String convoId) async {
    await _db
        .from('ai_conversations')
        .delete()
        .eq('id', convoId)
        .eq('user_id', userId);
  }

  static Future<void> deleteConversation(String userId, String convoId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteConversation,
        userId: userId,
        payload: convoId,
      ),
      () => _deleteConversationRemote(userId, convoId),
    );
  }

  // ============================================
  // AI PROJECTS
  // ============================================

  static Future<List<Map<String, dynamic>>> loadProjects(String userId) async {
    try {
      final data = await _db
          .from('ai_projects')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] Error loading projects: $e');
      return [];
    }
  }

  static Future<void> _saveProjectRemote(
      String userId, Map<String, dynamic> projectJson) async {
    await _db.from('ai_projects').upsert({
      'id': projectJson['id'],
      'user_id': userId,
      'name': projectJson['name'],
      'created_at': projectJson['createdAt'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveProject(String userId, Map<String, dynamic> projectJson) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.saveProject,
        userId: userId,
        payload: projectJson,
      ),
      () => _saveProjectRemote(userId, projectJson),
    );
  }

  static Future<void> _deleteProjectRemote(
      String userId, String projectId) async {
    await _db
        .from('ai_projects')
        .delete()
        .eq('id', projectId)
        .eq('user_id', userId);
  }

  static Future<void> deleteProject(String userId, String projectId) async {
    await _syncWithRetry(
      _QueuedSyncOperation(
        type: _SyncOperationType.deleteProject,
        userId: userId,
        payload: projectId,
      ),
      () => _deleteProjectRemote(userId, projectId),
    );
  }

  // ============================================
  // FULL LOAD (on login)
  // ============================================

  static Future<Map<String, dynamic>> loadAllUserData(String userId) async {
    final results = await Future.wait([
      loadProfile(userId),
      loadAccounts(userId),
      loadTransactions(userId),
      loadGoals(userId),
      loadRecurringRules(userId),
      loadHoldings(userId),
      loadCategories(userId),
    ]);

    return {
      'settings': results[0] as Settings?,
      'accounts': results[1] as List<Account>,
      'transactions': results[2] as List<Transaction>,
      'goals': results[3] as List<Goal>,
      'recurringRules': results[4] as List<RecurringRule>,
      'holdings': results[5] as List<Holding>,
      'categories': results[6] as List<Category>,
    };
  }
}
