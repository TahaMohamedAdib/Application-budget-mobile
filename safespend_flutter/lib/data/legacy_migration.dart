import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/daret.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import 'local_repository.dart';

/// Moves an existing install's data out of the SharedPreferences JSON blobs
/// and into SQLite, once.
///
/// This runs on the upgrade path for every user who already has data, so it is
/// the single most destructive-if-wrong piece of this change. Three rules
/// follow from that:
///
///  1. **The old blobs are not deleted.** They stay as a fallback until a
///     later release retires them. Disk is cheap; a user's ledger is not.
///  2. **It is idempotent.** A crash mid-run leaves the flag unset, so the
///     next launch re-imports from blobs that were never touched.
///  3. **Partial parses do not abort the run.** One corrupt entity list must
///     not cost the user the other seven.
class LegacyMigration {
  LegacyMigration({required LocalRepository repository})
      : _repository = repository;

  final LocalRepository _repository;

  /// Per-user, because two accounts can share a device and each needs its own
  /// import from the blobs that were current when it was last signed in.
  static String _flagKey(String userId) => 'sqlite_migrated_v1_$userId';

  static const _accountsKey = 'accounts';
  static const _transactionsKey = 'transactions';
  static const _settingsKey = 'settings';
  static const _recurringRulesKey = 'recurringRules';
  static const _holdingsKey = 'holdings';
  static const _goalsKey = 'goals';
  static const _daretsKey = 'darets';
  static const _categoriesKey = 'categories';

  Future<bool> hasMigrated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flagKey(userId)) ?? false;
  }

  /// Imports the legacy blobs for [userId] if they have not been imported yet.
  ///
  /// Returns what was moved, so the caller can log it and so the tests can
  /// assert on counts rather than on side effects.
  Future<MigrationResult> migrateIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey(userId)) ?? false) {
      return const MigrationResult.skipped();
    }

    final accounts = _decodeList(
      prefs.getString(_accountsKey),
      Account.fromJson,
      _accountsKey,
    );
    final transactions = _decodeList(
      prefs.getString(_transactionsKey),
      Transaction.fromJson,
      _transactionsKey,
    );
    final goals =
        _decodeList(prefs.getString(_goalsKey), Goal.fromJson, _goalsKey);
    final holdings = _decodeList(
      prefs.getString(_holdingsKey),
      Holding.fromJson,
      _holdingsKey,
    );
    final categories = _decodeList(
      prefs.getString(_categoriesKey),
      Category.fromJson,
      _categoriesKey,
    );
    final recurringRules = _decodeList(
      prefs.getString(_recurringRulesKey),
      RecurringRule.fromJson,
      _recurringRulesKey,
    );
    final darets =
        _decodeList(prefs.getString(_daretsKey), Daret.fromJson, _daretsKey);

    Map<String, dynamic>? settings;
    final rawSettings = prefs.getString(_settingsKey);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      try {
        settings = jsonDecode(rawSettings) as Map<String, dynamic>;
      } catch (error) {
        debugPrint('migration: settings blob unreadable, skipping: $error');
      }
    }

    final isEmpty = accounts.isEmpty &&
        transactions.isEmpty &&
        goals.isEmpty &&
        holdings.isEmpty &&
        categories.isEmpty &&
        recurringRules.isEmpty &&
        darets.isEmpty &&
        settings == null;

    if (isEmpty) {
      // A fresh install. Flag it so we do not re-scan the blobs every launch.
      await prefs.setBool(_flagKey(userId), true);
      return const MigrationResult.skipped();
    }

    // `markDirty: false`, deliberately. This data came from a client that was
    // already syncing it, so the server has it; marking it dirty would enqueue
    // a full re-upload of the user's entire history on first launch after the
    // update. Anything the server is genuinely missing arrives on the next
    // edit, and the pull reconciles the rest.
    await _repository.replaceAll(
      userId: userId,
      accounts: accounts,
      transactions: transactions,
      goals: goals,
      holdings: holdings,
      categories: categories,
      recurringRules: recurringRules,
      darets: darets,
      settings: settings,
      markDirty: false,
    );

    // Set only after the write commits: if the app dies above this line the
    // flag stays unset and the next launch starts over from untouched blobs.
    await prefs.setBool(_flagKey(userId), true);

    return MigrationResult(
      migrated: true,
      accounts: accounts.length,
      transactions: transactions.length,
      goals: goals.length,
      holdings: holdings.length,
      categories: categories.length,
      recurringRules: recurringRules.length,
      darets: darets.length,
      settings: settings != null,
    );
  }

  /// Decodes one blob, tolerating both a malformed blob and individual
  /// malformed records inside an otherwise good one.
  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
    String label,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (error) {
      debugPrint('migration: $label blob unreadable, skipping: $error');
      return <T>[];
    }

    final result = <T>[];
    for (final entry in decoded) {
      try {
        result.add(fromJson(entry as Map<String, dynamic>));
      } catch (error) {
        // One bad record costs one record, not the list.
        debugPrint('migration: dropped a malformed $label record: $error');
      }
    }
    return result;
  }
}

/// What a migration run moved.
@immutable
class MigrationResult {
  const MigrationResult({
    required this.migrated,
    this.accounts = 0,
    this.transactions = 0,
    this.goals = 0,
    this.holdings = 0,
    this.categories = 0,
    this.recurringRules = 0,
    this.darets = 0,
    this.settings = false,
  });

  const MigrationResult.skipped() : this(migrated: false);

  final bool migrated;
  final int accounts;
  final int transactions;
  final int goals;
  final int holdings;
  final int categories;
  final int recurringRules;
  final int darets;
  final bool settings;

  int get totalRecords =>
      accounts +
      transactions +
      goals +
      holdings +
      categories +
      recurringRules +
      darets;

  @override
  String toString() => migrated
      ? 'MigrationResult(records: $totalRecords, settings: $settings)'
      : 'MigrationResult(skipped)';
}
