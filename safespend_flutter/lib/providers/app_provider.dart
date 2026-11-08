import '../utils/system_note.dart';
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
import '../data/legacy_migration.dart';
import '../data/local_database.dart';
import '../data/local_repository.dart';
import '../data/sync_engine.dart';
import '../services/supabase_sync_service.dart';
import '../services/image_service.dart';
import '../services/notifications/notification_service.dart';
import '../utils/recurring_dates.dart';
import '../l10n/app_localizations.dart';

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
  bool _hasSeenAppTour = false;
  Set<String> _seenFeatureGuides = {};
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
  bool get hasSeenAppTour => _hasSeenAppTour;
  bool get supabaseDataLoaded => _supabaseDataLoaded;
  String? get selectedAccountId => _selectedAccountId;

  bool hasSeenFeatureGuide(String feature) =>
      _seenFeatureGuides.contains(feature);

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

  /// Notification failures must never block a financial mutation.
  void _refreshNotifications() {
    if (_settings.notificationsEnabled != true) return;
    unawaited(NotificationService.instance
        .refresh(
      settings: _settings,
      transactions: _transactions,
      recurringRules: _recurringRules,
    )
        .catchError((Object e) {
      if (kDebugMode) debugPrint('[notifications] refresh failed: $e');
    }));
    if (_settings.budgetAlerts) {
      unawaited(NotificationService.instance
          .evaluateBudgets(
            categories: _categories,
            spendingFor: getCategorySpending,
          )
          .catchError((Object e) {
        if (kDebugMode) debugPrint('[notifications] budget check failed: $e');
      }));
    }
  }

  // ── Local-first store ─────────────────────────────────────────────
  //
  // Reads come from SQLite and writes go to SQLite plus a durable queue, so a
  // change made with no network is complete the moment it is saved.
  //
  // The SharedPreferences blobs are still written alongside, for one release.
  // They are the rollback path: if the SQLite layer misbehaves on a device we
  // cannot reproduce, the old loader still finds intact data. A later release
  // removes the dual write.
  final LocalRepository _repository = LocalRepository();
  late final SyncEngine _syncEngine = SyncEngine(repository: _repository);
  late final LegacyMigration _legacyMigration =
      LegacyMigration(repository: _repository);

  /// Sync state for the UI, so a screen can show pending or failed work
  /// without reaching into the engine.
  ValueListenable<SyncStatusSnapshot> get syncStatus => _syncEngine.status;

  /// True once this session has a local database to read from.
  bool _repositoryReady = false;

  /// Whether the user has changes the server has not acknowledged. Used to
  /// warn before a sign-out that would strand them.
  Future<bool> hasUnsyncedChanges() async {
    final uid = _userId;
    if (uid == null) return false;
    return _repository.hasUnsyncedChanges(uid);
  }

  /// Prepares the local store for [userId] and starts background sync.
  ///
  /// Runs the one-time import from the old blobs first: until that has
  /// happened, SQLite is empty and reading from it would show a returning
  /// user an empty app.
  /// Lets tests put the UI into a given sync state without a live engine.
  ///
  /// The alternative is casting [syncStatus] back to its notifier at the call
  /// site, which couples every such test to the engine's internals.
  @visibleForTesting
  void debugSetSyncStatus(SyncStatusSnapshot status) {
    _syncEngine.status.value = status;
  }

  /// Pushes queued work now, for a user who just pulled to refresh or tapped
  /// retry. Safe to call when offline: the engine reports the offline phase
  /// and leaves the queue intact.
  Future<void> syncNow() async {
    if (!_repositoryReady) return;
    await _syncEngine.sync();
  }

  /// Requeues work that failed permanently. See [SyncEngine.retryFailed].
  Future<void> retryFailedSync() async {
    if (!_repositoryReady) return;
    await _syncEngine.retryFailed();
  }

  Future<void> initializeLocalStore(String userId) async {
    try {
      final result = await _legacyMigration.migrateIfNeeded(userId);
      if (kDebugMode && result.migrated) {
        debugPrint('[AppProvider] migrated ${result.totalRecords} records '
            'into the local database');
      }
      _repositoryReady = true;
      await _syncEngine.start(userId);
    } catch (e) {
      // A failure here costs background sync, not the app: the provider keeps
      // using the SharedPreferences path it has always used.
      _repositoryReady = false;
      if (kDebugMode) {
        debugPrint('[AppProvider] local store unavailable, '
            'continuing on the legacy cache: $e');
      }
    }
  }

  /// Mirrors the in-memory state into SQLite.
  ///
  /// Called from [_performSave] so every existing mutation site keeps working
  /// unchanged — there are around forty-five of them, and rewriting each by
  /// hand is where a balance bug would get in.
  ///
  /// `markDirty: false` because the mutation sites already hand their change
  /// to [SupabaseSyncService], which owns the push. Marking these dirty would
  /// queue a second copy of every write.
  Future<void> _mirrorToRepository() async {
    final uid = _userId;
    if (uid == null || !_repositoryReady) return;
    try {
      await _repository.replaceAll(
        userId: uid,
        accounts: _accounts,
        transactions: _transactions,
        goals: _goals,
        holdings: _holdings,
        categories: _categories,
        recurringRules: _recurringRules,
        darets: _darets,
        settings: _settings.toJson(),
        markDirty: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AppProvider] local mirror failed: $e');
    }
  }

  /// Loads this user's data from SQLite.
  ///
  /// Returns false when there is nothing stored yet, so the caller can fall
  /// back rather than show an empty app.
  Future<bool> _loadFromRepository(String userId) async {
    if (!_repositoryReady) return false;
    try {
      final results = await Future.wait([
        _repository.accounts(userId),
        _repository.transactions(userId),
        _repository.goals(userId),
        _repository.holdings(userId),
        _repository.categories(userId),
        _repository.recurringRules(userId),
        _repository.darets(userId),
      ]);

      final accounts = results[0] as List<Account>;
      final transactions = results[1] as List<Transaction>;
      if (accounts.isEmpty && transactions.isEmpty) return false;

      _accounts = accounts;
      _transactions = transactions;
      _goals = results[2] as List<Goal>;
      _holdings = results[3] as List<Holding>;
      _categories = results[4] as List<Category>;
      _recurringRules = results[5] as List<RecurringRule>;
      _darets = results[6] as List<Daret>;

      final storedSettings = await _repository.settings(userId);
      if (storedSettings != null) {
        _settings = Settings.fromJson(storedSettings);
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppProvider] local read failed: $e');
      return false;
    }
  }

  /// Load ALL data from Supabase for the authenticated user.
  /// Falls back to SharedPreferences if not authenticated or on error.
  Future<void> loadFromSupabase(String userId) async {
    if (_supabaseLoadInProgress) return;
    _supabaseLoadInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Bring up the local store before anything else: it is what the app
      // reads from, and the one-time import from the old blobs happens here.
      await initializeLocalStore(userId);

      // Serve local data immediately. A returning user sees their accounts at
      // once rather than a spinner, and an offline launch shows the real app
      // instead of an empty one. The server pull below refines this.
      if (await _loadFromRepository(userId)) {
        _isLoading = false;
        _localDataLoaded = true;
        notifyListeners();
        processSalaries();
        processSubscriptions();
      }

      // Pending offline work no longer skips the pull. It used to, because a
      // pull could overwrite unsynced changes wholesale; the repository now
      // protects dirty rows one at a time, so skipping would only cost the
      // user edits they made on another device.
      unawaited(_syncEngine.sync());

      final data = await SupabaseSyncService.loadAllUserData(userId);

      if (data['settings'] != null) {
        _settings = _settings.withRemoteProfile(data['settings'] as Settings);
      }
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
  void clearData({String? userId}) {
    // Captured before the fields are reset: the Supabase session may already
    // be gone by the time the wipe runs, and a null id would wipe nothing.
    // Account deletion invalidates the Supabase session before the local wipe.
    // Its caller therefore supplies the identity captured while it was still
    // authenticated; ordinary sign-out continues to resolve the current one.
    final signingOutUserId = userId ?? _userId;
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
    _setupComplete = false;
    _supabaseLoadInProgress = false;
    // Deliberately left true. `localDataLoaded` means "we know what is in local
    // storage", not "local storage has something in it" — and after this method
    // we know exactly what is there, because we just emptied it. Clearing the
    // flag stranded the app on the splash screen after sign-out: the splash is
    // gated on it, and nothing re-runs loadData() to set it again.
    _localDataLoaded = true;
    notifyListeners();
    unawaited(SupabaseSyncService.clearPendingRetryQueue());
    // Notification cleanup is best-effort. A platform-plugin failure must not
    // prevent sign-out/account deletion from clearing the person's data.
    unawaited(NotificationService.instance.cancelAll().catchError((Object e) {
      if (kDebugMode) {
        debugPrint('[AppProvider] notification cleanup failed: $e');
      }
    }));
    _clearLocalCache();
    _clearRepository(signingOutUserId);
  }

  /// Stops sync and removes this user's local rows at sign-out.
  ///
  /// Both halves matter. Leaving the engine running would have it sync a user
  /// who is no longer signed in, and leaving the rows would let the next
  /// account on this device read the previous one's finances.
  void _clearRepository(String? userId) {
    unawaited(_syncEngine.stop());
    _repositoryReady = false;
    if (userId == null) return;
    unawaited(
      LocalDatabase.instance.wipeUser(userId).catchError((Object e) {
        if (kDebugMode) debugPrint('[AppProvider] local wipe failed: $e');
      }),
    );
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
      _applyDeviceLocale(PlatformDispatcher.instance.locales);
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
      // Versioned so users who only saw the old generic slide deck receive
      // the redesigned, task-focused tour once.
      _hasSeenAppTour = prefs.getBool('has_seen_app_tour_v2') ?? false;
      _seenFeatureGuides =
          (prefs.getStringList('seen_feature_guides_v2') ?? const <String>[])
              .toSet();
    } catch (e) {
      if (kDebugMode)
        debugPrint('[AppProvider] Critical error in loadData: $e');
    } finally {
      _isLoading = false;
      _localDataLoaded = true;
      notifyListeners();
      processSalaries();
      processSubscriptions();
      _refreshNotifications();
    }
  }

  Future<void> markSetupComplete() async {
    _setupComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    notifyListeners();
  }

  /// Marks the guided app tour as seen so it never auto-shows again.
  /// The tour can still be replayed manually (e.g. from Settings).
  Future<void> markAppTourSeen() async {
    if (_hasSeenAppTour) return;
    _hasSeenAppTour = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_app_tour_v2', true);
    notifyListeners();
  }

  /// Contextual help is progressive: each major feature introduces itself on
  /// first visit, then stays out of the user's way. The full tour remains
  /// replayable from Settings.
  Future<void> markFeatureGuideSeen(String feature) async {
    if (!_seenFeatureGuides.add(feature)) return;
    final prefs = await SharedPreferences.getInstance();
    final sorted = _seenFeatureGuides.toList()..sort();
    await prefs.setStringList('seen_feature_guides_v2', sorted);
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
      _refreshNotifications();

      // Mirror into SQLite, which is the store the app will read from. Awaited
      // after the blobs rather than alongside them: if this throws, the legacy
      // cache is already durable and the user has lost nothing.
      await _mirrorToRepository();
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
    _syncEngine.dispose();
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
    if (!_accounts.any((a) => a.id == id)) return;
    // Remove associated history with its normal reversal logic so surviving
    // transfer accounts, cash, and linked goal progress remain consistent.
    final transactions = _transactions
        .where((t) => t.accountId == id || t.toAccountId == id)
        .map((t) => t.id)
        .toList();
    for (final transactionId in transactions) {
      deleteTransaction(transactionId);
    }
    final rules = _recurringRules
        .where((r) =>
            r.id == 'debt_$id' ||
            r.templateTransaction.accountId == id ||
            r.templateTransaction.toAccountId == id)
        .map((r) => r.id)
        .toList();
    for (final ruleId in rules) {
      deleteRecurringRule(ruleId);
    }
    _accounts.removeWhere((a) => a.id == id);
    if (_selectedAccountId == id) _selectedAccountId = null;
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
        note: systemNote('debtPayment', account.name),
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

  /// Auto-credits every pay packet that has fallen due since the account was
  /// last paid, for all three pay cycles.
  ///
  /// Each due date is credited separately rather than merged: a weekly earner
  /// who opens the app after a month away gets four dated salary transactions,
  /// so the balance history stays truthful.
  ///
  /// The first run for an account has no `lastSalaryDate` to work from. It
  /// credits only the most recent due date rather than back-filling from the
  /// beginning of time — inventing months of income the user never told us
  /// about would be worse than missing one packet.
  void processSalaries() {
    final today = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _accounts.length; i++) {
      final acc = _accounts[i];
      if (!acc.hasSalarySchedule) continue;

      var due = acc.payDatesBetween(_lastSalaryBoundary(acc), today);
      if (due.isEmpty) continue;

      // No history yet — take the latest due date only.
      if (acc.lastSalaryDate == null) due = [due.last];

      var account = acc;
      for (final payDate in due) {
        final tx = Transaction(
          id: const Uuid().v4(),
          type: 'income',
          amount: account.salaryAmount!,
          date: payDate.toIso8601String().substring(0, 10),
          note: systemNote('systemSalary'),
          accountId: account.id,
        );
        _transactions.add(tx);
        account = account.copyWith(
          balance: account.balance + account.salaryAmount!,
          lastSalaryDate: payDate.toIso8601String().substring(0, 10),
        );

        final uid = _userId;
        if (uid != null) SupabaseSyncService.saveTransaction(uid, tx);
      }

      _accounts[i] = account;
      changed = true;

      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveAccount(uid, account);
    }

    if (changed) {
      _saveToLocal();
      notifyListeners();
    }
  }

  /// The date after which pay packets are still owed.
  ///
  /// Handles both storage formats of `lastSalaryDate`: the current
  /// 'yyyy-MM-dd', and the legacy 'yyyy-MM' that meant "paid for this month",
  /// which resolves to the last day of that month.
  DateTime _lastSalaryBoundary(Account acc) {
    final raw = acc.lastSalaryDate;
    if (raw == null) {
      // Look back one full cycle so exactly one packet can be due.
      final lookback = switch (acc.effectiveSalaryFrequency) {
        'weekly' => 8,
        'biweekly' => 15,
        _ => 32,
      };
      return DateTime.now().subtract(Duration(days: lookback));
    }
    if (raw.length == 7) {
      final month = DateTime.tryParse('$raw-01');
      if (month != null) return DateTime(month.year, month.month + 1, 0);
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
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
      bool stopRule = false;

      // Process each overdue period (max 24 to avoid infinite loop on very old rules)
      while (!nextDate.isAfter(now) && safetyCounter < 24) {
        safetyCounter++;

        final isIncome = rule.templateTransaction.type == 'income';
        final amount = _recurringAmountDue(rule);
        if (amount <= 0) {
          stopRule = true;
          changed = true;
          break;
        }

        // Create transaction for this due date/time
        final tx = Transaction(
          id: const Uuid().v4(),
          type: rule.id.startsWith('debt_') || rule.id.startsWith('debtgoal_')
              ? 'debt_payment'
              : rule.templateTransaction.type,
          amount: amount,
          date: nextDate.toIso8601String(),
          note: rule.templateTransaction.note,
          categoryId: rule.id.startsWith('debtgoal_')
              ? rule.id.substring(9)
              : rule.id.startsWith('savingsgoal_')
                  ? rule.id.substring(12)
                  : rule.templateTransaction.categoryId,
          toAccountId: rule.id.startsWith('debt_')
              ? rule.id.substring(5)
              : rule.templateTransaction.toAccountId,
          fees: rule.templateTransaction.fees,
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
                  (isIncome ? amount : -tx.totalWithFees),
            );
          }
        }

        // Advance nextDate by one period, preserving time of day
        nextDate = advanceRecurringDate(
          nextDate,
          rule.frequency,
          scheduledDay: _scheduledDay(rule, nextDate.day),
        );

        // If this is a debt payment (Account-based), reduce the debt account balance
        if (rule.id.startsWith('debt_') && !rule.id.startsWith('debtgoal_')) {
          final debtAccountId = rule.id.substring(5); // strip 'debt_' prefix
          final debtIdx = _accounts.indexWhere((a) => a.id == debtAccountId);
          if (debtIdx != -1) {
            final newBalance = _accounts[debtIdx].balance - amount;
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
            final newPaid = (_goals[goalIdx].currentAmount + amount)
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
            final newSaved = (_goals[goalIdx].currentAmount + amount)
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
        if (stopRule) {
          _recurringRules[i] = _recurringRules[i].copyWith(isActive: false);
        }

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

  double _recurringAmountDue(RecurringRule rule) {
    final scheduled = rule.templateTransaction.amount;
    if (rule.id.startsWith('debt_') && !rule.id.startsWith('debtgoal_')) {
      final debtId = rule.id.substring(5);
      final debt = _accounts.where((a) => a.id == debtId).firstOrNull;
      final remaining = debt == null ? 0.0 : debt.balance;
      return remaining <= 0 ? 0 : scheduled.clamp(0, remaining).toDouble();
    }
    if (rule.id.startsWith('debtgoal_')) {
      final goalId = rule.id.substring(9);
      final goal = _goals.where((g) => g.id == goalId).firstOrNull;
      final remaining =
          goal == null ? 0.0 : goal.targetAmount - goal.currentAmount;
      return remaining <= 0 ? 0 : scheduled.clamp(0, remaining).toDouble();
    }
    if (rule.id.startsWith('savingsgoal_')) {
      final goalId = rule.id.substring(12);
      final goal = _goals.where((g) => g.id == goalId).firstOrNull;
      final remaining =
          goal == null ? 0.0 : goal.targetAmount - goal.currentAmount;
      return remaining <= 0 ? 0 : scheduled.clamp(0, remaining).toDouble();
    }
    return scheduled;
  }

  int _scheduledDay(RecurringRule rule, int fallback) {
    if (rule.id.startsWith('debt_') && !rule.id.startsWith('debtgoal_')) {
      final debtId = rule.id.substring(5);
      final debt = _accounts.where((a) => a.id == debtId).firstOrNull;
      if (debt?.debtPaymentDay != null) return debt!.debtPaymentDay!;
    }
    if (rule.id.startsWith('debtgoal_')) {
      final goalId = rule.id.substring(9);
      final goal = _goals.where((g) => g.id == goalId).firstOrNull;
      if (goal?.paymentDay != null) return goal!.paymentDay!;
    }
    if (rule.id.startsWith('savingsgoal_')) {
      final goalId = rule.id.substring(12);
      final goal = _goals.where((g) => g.id == goalId).firstOrNull;
      if (goal?.paymentDay != null) return goal!.paymentDay!;
    }
    if (rule.id.startsWith('daret_contrib_')) {
      final daretId = rule.id.substring(15);
      final daret = _darets.where((d) => d.id == daretId).firstOrNull;
      if (daret != null) return daret.paymentDay;
    }
    return DateTime.tryParse(rule.templateTransaction.date)?.day ?? fallback;
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
            transaction.type == 'debt_payment' ||
            transaction.type == 'personal_debt_return' ||
            transaction.type == 'daret_contribution') {
          newBalance -= transaction.totalWithFees; // amount + bank fees
        }
        // Add: income, lending_collection
        else if (transaction.type == 'income' ||
            transaction.type == 'lending_collection' ||
            transaction.type == 'daret_payout') {
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

  // Payment records and goal progress must reverse together on edits/deletions.
  bool _tracksGoal(Transaction t) =>
      const {
        'goal_contribution',
        'debt_payment',
        'personal_debt_return',
        'lending_collection',
        'income',
      }.contains(t.type) &&
      _goals.any((g) => g.id == t.categoryId);

  void _adjustLinkedProgress(Transaction t, double direction) {
    if (_tracksGoal(t)) {
      final index = _goals.indexWhere((g) => g.id == t.categoryId);
      final goal = _goals[index];
      _goals[index] = goal.copyWith(
        currentAmount: (goal.currentAmount + direction * t.amount)
            .clamp(0, double.infinity)
            .toDouble(),
      );
      final uid = _userId;
      if (uid != null) SupabaseSyncService.saveGoal(uid, _goals[index]);
    }
    if (t.type == 'debt_payment' && t.toAccountId != null) {
      final index = _accounts
          .indexWhere((a) => a.id == t.toAccountId && a.type == 'debt');
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          balance: _accounts[index].balance - direction * t.amount,
        );
        final uid = _userId;
        if (uid != null) SupabaseSyncService.saveAccount(uid, _accounts[index]);
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
            old.type == 'debt_payment' ||
            old.type == 'personal_debt_return' ||
            old.type == 'daret_contribution') {
          bal += old.totalWithFees;
        } else if (old.type == 'income' ||
            old.type == 'lending_collection' ||
            old.type == 'daret_payout') {
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

    _adjustLinkedProgress(old, -1);
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
    if (!updated.amount.isFinite ||
        updated.amount <= 0 ||
        !updated.fees.isFinite ||
        updated.fees < 0) return;
    if (_tracksGoal(updated)) {
      final goal = _goals.firstWhere((g) => g.id == updated.categoryId);
      final previous = _tracksGoal(old) && old.categoryId == updated.categoryId
          ? old.amount
          : 0.0;
      if (updated.amount > goal.targetAmount - goal.currentAmount + previous)
        return;
    }
    _adjustLinkedProgress(old, -1);
    _adjustLinkedProgress(updated, 1);
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
            old.type == 'debt_payment' ||
            old.type == 'personal_debt_return' ||
            old.type == 'daret_contribution') {
          bal += old.totalWithFees;
        } else if (old.type == 'income' ||
            old.type == 'lending_collection' ||
            old.type == 'daret_payout') {
          bal -= old.amount;
        }
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }
    // Reverse the old receiving side of a transfer.
    if (old.type == 'transfer' &&
        old.toAccountId != null &&
        old.toAccountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == old.toAccountId);
      if (ai != -1) {
        _accounts[ai] =
            _accounts[ai].copyWith(balance: _accounts[ai].balance - old.amount);
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
            updated.type == 'debt_payment' ||
            updated.type == 'personal_debt_return' ||
            updated.type == 'daret_contribution') {
          bal -= updated.totalWithFees;
        } else if (updated.type == 'income' ||
            updated.type == 'lending_collection' ||
            updated.type == 'daret_payout') {
          bal += updated.amount;
        }
        _accounts[ai] = _accounts[ai].copyWith(balance: bal);
      }
    }
    // Apply the new receiving side of a transfer.
    if (updated.type == 'transfer' &&
        updated.toAccountId != null &&
        updated.toAccountId != cashOnHandId) {
      final ai = _accounts.indexWhere((a) => a.id == updated.toAccountId);
      if (ai != -1) {
        _accounts[ai] = _accounts[ai]
            .copyWith(balance: _accounts[ai].balance + updated.amount);
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
      if (old.toAccountId != null && old.toAccountId != cashOnHandId) {
        changedAccountIds.add(old.toAccountId!);
      }
      if (updated.accountId != cashOnHandId)
        changedAccountIds.add(updated.accountId);
      if (updated.toAccountId != null && updated.toAccountId != cashOnHandId) {
        changedAccountIds.add(updated.toAccountId!);
      }
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
      note: systemNote('sell', '$sharesToSell ${holding.symbol}'),
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
    for (final ruleId in ['debtgoal_$id', 'savingsgoal_$id']) {
      deleteRecurringRule(ruleId);
    }
    _goals.removeWhere((g) => g.id == id);
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
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
        note: systemNote('debtPayment', goal.name),
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
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx == -1 || !amount.isFinite || amount <= 0) return;
    if (sourceAccountId != cashOnHandId &&
        !_accounts.any((a) => a.id == sourceAccountId)) return;
    final goal = _goals[goalIdx];
    if (goal.currentAmount >= goal.targetAmount) return;
    final appliedAmount =
        amount.clamp(0, goal.targetAmount - goal.currentAmount).toDouble();
    if (appliedAmount <= 0) return;
    final txn = Transaction(
      id: const Uuid().v4(),
      type: 'goal_contribution',
      amount: appliedAmount,
      date: DateTime.now().toIso8601String(),
      note: systemNote('savingsGoal', goal.name),
      accountId: sourceAccountId,
      categoryId: goal.id,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx]
            .copyWith(balance: _accounts[idx].balance - appliedAmount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal
    _goals[goalIdx] = _goals[goalIdx].copyWith(
      currentAmount: _goals[goalIdx].currentAmount + appliedAmount,
    );

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
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx == -1 || !amount.isFinite || amount <= 0) return;
    if (sourceAccountId != cashOnHandId &&
        !_accounts.any((a) => a.id == sourceAccountId)) return;
    final goal = _goals[goalIdx];
    if (goal.currentAmount >= goal.targetAmount) return;
    final appliedAmount =
        amount.clamp(0, goal.targetAmount - goal.currentAmount).toDouble();
    if (appliedAmount <= 0) return;
    final txn = Transaction(
      id: const Uuid().v4(),
      type: 'personal_debt_return',
      amount: appliedAmount,
      date: DateTime.now().toIso8601String(),
      note: systemNote('debtPayment', goal.name),
      description: goal.categoryId,
      accountId: sourceAccountId,
      categoryId: goal.id,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash handled by totalCash getter via transactions)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx]
            .copyWith(balance: _accounts[idx].balance - appliedAmount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal currentAmount
    _goals[goalIdx] = _goals[goalIdx].copyWith(
      currentAmount: _goals[goalIdx].currentAmount + appliedAmount,
    );

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
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx == -1 || !amount.isFinite || amount <= 0) return;
    if (targetAccountId != cashOnHandId &&
        !_accounts.any((a) => a.id == targetAccountId)) return;
    final goal = _goals[goalIdx];
    if (goal.currentAmount >= goal.targetAmount) return;
    final appliedAmount =
        amount.clamp(0, goal.targetAmount - goal.currentAmount).toDouble();
    if (appliedAmount <= 0) return;
    final txn = Transaction(
      id: const Uuid().v4(),
      type: 'income',
      amount: appliedAmount,
      date: DateTime.now().toIso8601String(),
      note: systemNote('received', goal.name),
      accountId: targetAccountId,
      categoryId: goal.id,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // ADD to target account (positive inflow)
    if (targetAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == targetAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx]
            .copyWith(balance: _accounts[idx].balance + appliedAmount);
        changedAccount = _accounts[idx];
      }
    }
    // If cash: totalCash getter automatically includes income transactions

    // Update goal currentAmount (tracks how much has been returned)
    _goals[goalIdx] = _goals[goalIdx].copyWith(
      currentAmount: _goals[goalIdx].currentAmount + appliedAmount,
    );

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
    final goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx == -1 || !amount.isFinite || amount <= 0) return;
    if (sourceAccountId != cashOnHandId &&
        !_accounts.any((a) => a.id == sourceAccountId)) return;
    final goal = _goals[goalIdx];
    if (goal.currentAmount >= goal.targetAmount) return;
    final appliedAmount =
        amount.clamp(0, goal.targetAmount - goal.currentAmount).toDouble();
    if (appliedAmount <= 0) return;
    final txn = Transaction(
      id: const Uuid().v4(),
      type: 'debt_payment',
      amount: appliedAmount,
      date: DateTime.now().toIso8601String(),
      note: systemNote('debtPayment', goal.name),
      accountId: sourceAccountId,
      categoryId: goal.id,
    );
    _transactions.add(txn);

    Account? changedAccount;
    // Deduct from source account (cash deduction handled by totalCash getter)
    if (sourceAccountId != cashOnHandId) {
      final idx = _accounts.indexWhere((a) => a.id == sourceAccountId);
      if (idx != -1) {
        _accounts[idx] = _accounts[idx]
            .copyWith(balance: _accounts[idx].balance - appliedAmount);
        changedAccount = _accounts[idx];
      }
    }

    // Update goal
    _goals[goalIdx] = _goals[goalIdx].copyWith(
      currentAmount: _goals[goalIdx].currentAmount + appliedAmount,
    );

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
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    return _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'expense' &&
          t.categoryId == categoryId &&
          date != null &&
          !date.isBefore(startOfMonth) &&
          date.isBefore(startOfNextMonth);
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  // ============================================
  // SETTINGS METHODS
  // ============================================

  /// Total monthly income implied by every account's pay schedule.
  ///
  /// Derived rather than stored, so it cannot drift from the schedules it
  /// summarises. Weekly and fortnightly wages are annualised properly — see
  /// [Account.monthlySalaryEquivalent].
  double get monthlyIncomeFromSalaries => _accounts.fold(
        0.0,
        (sum, account) => sum + account.monthlySalaryEquivalent,
      );

  /// Writes a pay schedule onto [accountId], or clears it when [amount] is
  /// null, and keeps `settings.monthlyIncome` in step.
  ///
  /// Budgeting reads `settings.monthlyIncome`; the schedule lives on the
  /// account. Updating one without the other is what left safe-to-spend
  /// stale, so both move together here.
  void setAccountSalary(
    String accountId, {
    required double? amount,
    String frequency = 'monthly',
    int day = 1,
  }) {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    _accounts[index] = amount == null || amount <= 0
        ? _accounts[index].withoutSalary()
        : _accounts[index].withSalary(
            amount: amount,
            frequency: frequency,
            day: day,
          );

    _settings = _settings.copyWith(monthlyIncome: monthlyIncomeFromSalaries);

    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.saveAccount(uid, _accounts[index]);
      SupabaseSyncService.saveProfile(uid, _settings);
    }
  }

  void updateSettings(Settings settings) {
    _settings = settings;
    _saveToLocal();
    notifyListeners();
    _refreshNotifications();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, settings);
  }

  /// Stores [localPath] as the user's profile picture and uploads it.
  ///
  /// The app-owned local copy is applied immediately. If Storage is offline or
  /// not configured yet, its upload is persisted in the retry queue instead
  /// of rejecting the user's picture.
  Future<bool> setProfilePicture(String localPath) async {
    final uid = _userId;
    // Local mode has no account to attach a picture to, and nothing would
    // survive a reinstall, so this is refused rather than silently kept.
    if (uid == null) return false;

    final previous = _settings.avatarPath;
    final durablePath = await ImageService.persistProfilePicture(localPath);
    if (durablePath == null) return false;

    _settings = _settings.copyWith(avatarPath: durablePath);
    _saveToLocal();
    notifyListeners();

    final objectPath = await SupabaseSyncService.uploadAvatar(uid, durablePath);
    if (objectPath != null) {
      _settings = _settings.copyWith(avatarPath: objectPath);
      _saveToLocal();
      notifyListeners();
      await ImageService.deleteLocalImage(durablePath);
    }

    // The upload uses a stable per-user name, so a replacement overwrites in
    // place and there is nothing to clean up unless the path actually moved.
    await ImageService.deleteLocalImage(previous);
    // Current uploads always use the same remote object name, so Storage
    // replaced the old remote bytes in place. Deleting `previous` here is
    // unsafe for legacy signed URLs that resolve to that same new object.
    return true;
  }

  /// Clears the profile picture and deletes the stored file.
  Future<void> removeProfilePicture() async {
    final previous = _settings.avatarPath;
    _settings = _settings.copyWith(avatarPath: null);
    _saveToLocal();
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      await SupabaseSyncService.cancelPendingAvatarUpload(uid);
      await SupabaseSyncService.saveAvatarReference(uid, null);
    }

    // Remove the object after the reference is gone, so a failure here leaves
    // an orphaned file rather than a profile pointing at a deleted image.
    if (previous != null && previous.isNotEmpty) {
      await ImageService.deleteLocalImage(previous);
      await SupabaseSyncService.deleteStoredObject(
          SupabaseSyncService.avatarsBucket, previous);
    }
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
    _settings = _settings.copyWith(
      locale: S.normalizeLocaleCode(locale),
      localeManuallySelected: true,
    );
    _saveToLocal();
    notifyListeners();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProfile(uid, _settings);
  }

  /// Refreshes the automatic language only while the person has not made an
  /// explicit choice. Public for lifecycle integration and deterministic tests.
  void applyDeviceLocales(Iterable<Locale> locales) {
    if (_settings.localeManuallySelected) return;
    final resolved = S.resolveDeviceLocale(locales);
    if (_settings.locale == resolved) return;
    _settings = _settings.copyWith(locale: resolved);
    _saveToLocal();
    notifyListeners();
  }

  void _applyDeviceLocale(Iterable<Locale> locales) {
    if (_settings.localeManuallySelected) return;
    final resolved = S.resolveDeviceLocale(locales);
    if (_settings.locale == resolved) return;
    _settings = _settings.copyWith(locale: resolved);
    _saveToLocal();
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
            t.type == 'debt_payment' ||
            t.type == 'personal_debt_return' ||
            t.type == 'daret_contribution') {
          cash -= t.totalWithFees;
        } else if (t.type == 'income' ||
            t.type == 'lending_collection' ||
            t.type == 'daret_payout') {
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

    final safeToSpendMonth = getSafeToSpendMonth();
    return daysRemaining > 0 ? safeToSpendMonth / daysRemaining : 0;
  }

  double getSafeToSpendMonth() {
    final now = DateTime.now();
    const outflowTypes = {
      'expense',
      'goal_contribution',
      'debt_payment',
      'personal_debt_return',
      'daret_contribution',
    };
    final spent = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          outflowTypes.contains(t.type);
    }).fold<double>(0, (sum, t) => sum + t.totalWithFees);
    return _settings.monthlyIncome - spent;
  }

  double getNetWorth() {
    if (_cachedNetWorth != null) return _cachedNetWorth!;
    // Non-investment accounts with includeInNetWorth
    final bankAssets = _accounts
        .where((a) => a.includeInNetWorth && a.type != 'investment')
        .fold(
            0.0,
            (sum, a) =>
                sum + (a.type == 'debt' ? -a.balance.abs() : a.balance));
    final cash = totalCash;
    // Investment account balances + portfolio positions
    final investments = _accounts
            .where((a) => a.type == 'investment' && a.includeInNetWorth)
            .fold(0.0, (sum, a) => sum + a.balance) +
        getTotalPortfolioValue();
    final debtRemaining = _goals
        .where((g) => g.type == 'debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    final personalDebtRemaining = _goals
        .where((g) => g.type == 'personal_debt')
        .fold(0.0, (sum, g) => sum + (g.targetAmount - g.currentAmount));
    _cachedNetWorth = bankAssets +
        cash +
        investments +
        totalSavingsGoals -
        debtRemaining +
        personalDebtRemaining;
    return _cachedNetWorth!;
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
        .where((g) => g.type == 'savings' || g.type == 'custom')
        .fold<double>(0.0, (sum, g) => sum + g.currentAmount);
    return _cachedTotalSavingsGoals!;
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
        note: systemNote('savingsCircle', daret.name),
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
      id: const Uuid().v4(),
      type: 'daret_contribution',
      amount: daret.monthlyPayment,
      date: DateTime.now().toIso8601String(),
      note: systemNote('savingsCircle', daret.name),
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

    final now = DateTime.now();
    final alreadyPaid = _transactions.any((t) {
      if (t.type != 'daret_payout' || t.categoryId != daret.id) return false;
      final date = DateTime.tryParse(t.date);
      return date != null && date.year == now.year && date.month == now.month;
    });
    if (alreadyPaid) return;

    final txn = Transaction(
      id: const Uuid().v4(),
      type: 'daret_payout',
      amount: daret.singlePayoutAmount,
      date: now.toIso8601String(),
      note: systemNote('received', daret.name),
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
