import 'dart:io';
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

class SupabaseSyncService {
  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Throws if Supabase is unavailable — callers must be wrapped in try-catch.
  static SupabaseClient get _db {
    final c = _client;
    if (c == null) throw Exception('Supabase not available (local mode)');
    return c;
  }

  static String? get currentUserId => _client?.auth.currentUser?.id;

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
      print('[Supabase] Error loading profile: $e');
      return null;
    }
  }

  static Future<void> saveProfile(String userId, Settings settings) async {
    try {
      await _db.from('profiles').upsert({
        'id': userId,
        'currency': settings.currency,
        'monthly_income': settings.monthlyIncome,
        'theme': settings.isDarkMode ? 'dark' : 'light',
        'net_worth_scope': settings.netWorthScope,
        'selected_account_id': settings.selectedAccountId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[Supabase] Error saving profile: $e');
    }
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
    'salary_amount': a.salaryAmount,
    'salary_day': a.salaryDay,
    'last_salary_date': a.lastSalaryDate,
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
    salaryAmount: (a['salary_amount'] as num?)?.toDouble(),
    salaryDay: a['salary_day'] as int?,
    lastSalaryDate: a['last_salary_date'],
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
      print('[Supabase] Error loading accounts: $e');
      return [];
    }
  }

  static Future<void> saveAccount(String userId, Account account) async {
    try {
      await _db.from('accounts').upsert(_accountToRow(userId, account));
    } catch (e) {
      print('[Supabase] Error saving account: $e');
    }
  }

  static Future<void> saveMultipleAccounts(String userId, List<Account> accounts) async {
    if (accounts.isEmpty) return;
    try {
      final rows = accounts.map((a) => _accountToRow(userId, a)).toList();
      await _db.from('accounts').upsert(rows);
    } catch (e) {
      print('[Supabase] Error saving multiple accounts: $e');
    }
  }

  static Future<void> deleteAccount(String userId, String accountId) async {
    try {
      await _db
          .from('accounts')
          .delete()
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting account: $e');
    }
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
  };

  static Transaction _rowToTransaction(Map<String, dynamic> t) => Transaction(
    id: t['id'],
    type: t['type'] ?? 'expense',
    amount: (t['amount'] as num?)?.toDouble() ?? 0,
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
      print('[Supabase] Error loading transactions: $e');
      return [];
    }
  }

  static Future<void> saveTransaction(String userId, Transaction transaction) async {
    try {
      await _db.from('transactions').upsert(_transactionToRow(userId, transaction));
    } catch (e) {
      print('[Supabase] Error saving transaction: $e');
    }
  }

  static Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _db
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting transaction: $e');
    }
  }

  // ============================================
  // STORAGE — RECEIPTS
  // ============================================

  /// Uploads a local image file to Supabase Storage bucket 'receipts'.
  /// Returns the public URL on success, or null if upload fails.
  static Future<String?> uploadReceipt(String userId, String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final ext = localPath.split('.').last.toLowerCase();
      final fileName = '$userId/${const Uuid().v4()}.$ext';
      await _db.storage.from('receipts').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      return _db.storage.from('receipts').getPublicUrl(fileName);
    } catch (e) {
      print('[Supabase Storage] Error uploading receipt: $e');
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
      print('[Supabase] Error loading goals: $e');
      return [];
    }
  }

  static Future<void> saveGoal(String userId, Goal goal) async {
    try {
      await _db.from('goals').upsert(_goalToRow(userId, goal));
    } catch (e) {
      print('[Supabase] Error saving goal: $e');
    }
  }

  static Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _db
          .from('goals')
          .delete()
          .eq('id', goalId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting goal: $e');
    }
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
      print('[Supabase] Error loading recurring rules: $e');
      return [];
    }
  }

  static Future<void> saveRecurringRule(String userId, RecurringRule rule) async {
    try {
      await _db.from('recurring_rules').upsert(_ruleToRow(userId, rule));
    } catch (e) {
      print('[Supabase] Error saving recurring rule: $e');
    }
  }

  static Future<void> deleteRecurringRule(String userId, String ruleId) async {
    try {
      await _db
          .from('recurring_rules')
          .delete()
          .eq('id', ruleId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting recurring rule: $e');
    }
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
      print('[Supabase] Error loading holdings: $e');
      return [];
    }
  }

  static Future<void> saveHolding(String userId, Holding holding) async {
    try {
      await _db.from('stock_holdings').upsert(_holdingToRow(userId, holding));
    } catch (e) {
      print('[Supabase] Error saving holding: $e');
    }
  }

  static Future<void> deleteHolding(String userId, String holdingId) async {
    try {
      await _db
          .from('stock_holdings')
          .delete()
          .eq('id', holdingId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting holding: $e');
    }
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
      print('[Supabase] Error loading categories: $e');
      return [];
    }
  }

  static Future<void> saveCategory(String userId, Category category) async {
    try {
      await _db.from('user_categories').upsert(
        _categoryToRow(userId, category),
        onConflict: 'user_id,category_id',
      );
    } catch (e) {
      print('[Supabase] Error saving category: $e');
    }
  }

  static Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await _db
          .from('user_categories')
          .delete()
          .eq('category_id', categoryId)
          .eq('user_id', userId);
    } catch (e) {
      print('[Supabase] Error deleting category: $e');
    }
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
