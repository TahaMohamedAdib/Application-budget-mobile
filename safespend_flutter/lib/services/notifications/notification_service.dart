import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/recurring_rule.dart';
import '../../models/category.dart';
import '../../models/settings.dart';
import '../../models/transaction.dart';
import 'notification_planner.dart';

/// Privacy-preserving local notification boundary. No device token, financial
/// amount, merchant, or account value is sent off-device or placed in payloads.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _expenseBaseId = 71000;
  static const _billsBaseId = 72000;
  static const _expenseChannel = 'expense_reminders';
  static const _billChannel = 'bill_reminders';
  static const _budgetChannel = 'budget_alerts';

  Future<void> initialize() async {
    if (_ready) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_stat_vvollet');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> refresh({
    required Settings settings,
    required Iterable<Transaction> transactions,
    required Iterable<RecurringRule> recurringRules,
  }) async {
    await initialize();
    await _cancelRange(_expenseBaseId, _expenseBaseId + 20);
    await _cancelRange(_billsBaseId, _billsBaseId + 100);
    if (settings.notificationsEnabled != true) return;
    final now = DateTime.now();
    if (settings.expenseReminderEnabled) {
      final expenseDates = transactions
          .where((t) => t.type == 'expense' && !t.isRecurring)
          .map((t) => DateTime.tryParse(t.date))
          .whereType<DateTime>();
      final dates = NotificationPlanner.expenseReminders(
        now: now,
        minutesAfterMidnight: settings.expenseReminderMinutes,
        expenseDates: expenseDates,
        quietHoursEnabled: settings.quietHoursEnabled,
        quietHoursStart: settings.quietHoursStart,
        quietHoursEnd: settings.quietHoursEnd,
      );
      for (var i = 0; i < dates.length; i++) {
        await _schedule(
            _expenseBaseId + i,
            dates[i],
            _expenseDetails,
            'Log today\'s spending',
            'Take a moment to add what you spent today.',
            'v1|expense');
      }
    }
    if (settings.billReminders) {
      var index = 0;
      for (final rule in recurringRules
          .where((r) => r.isActive && r.templateTransaction.type != 'income')) {
        final due = DateTime.tryParse(rule.nextDate);
        if (due == null) continue;
        final date = NotificationPlanner.dueTomorrowReminder(
            dueDate: due,
            now: now,
            quietHoursEnabled: settings.quietHoursEnabled,
            quietHoursStart: settings.quietHoursStart,
            quietHoursEnd: settings.quietHoursEnd);
        if (date == null || index >= 100) continue;
        await _schedule(
            _billsBaseId + index++,
            date,
            _billDetails,
            'Payment due tomorrow',
            'A bill or subscription is due tomorrow.',
            'v1|bill');
      }
    }
  }

  Future<void> showBudgetAlert({required bool limitReached}) async {
    await initialize();
    await _plugin.show(
        id: limitReached ? 73001 : 73000,
        title: limitReached ? 'Budget limit reached' : 'Budget almost used',
        body: limitReached
            ? 'A budget has reached its monthly limit.'
            : 'A budget has reached 80% this month.',
        notificationDetails: _budgetDetails,
        payload: 'v1|budget');
  }

  /// Emits each monthly threshold once per category, and re-arms it if an edit
  /// or deletion returns the category below the threshold.
  Future<void> evaluateBudgets({
    required Iterable<Category> categories,
    required double Function(String categoryId) spendingFor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final month = '${now.year}-${now.month}';
    for (final category in categories) {
      if (category.budgetLimit <= 0) continue;
      final ratio = spendingFor(category.id) / category.budgetLimit;
      for (final threshold in const [0.8, 1.0]) {
        final key = 'notification_budget_${category.id}_${month}_$threshold';
        if (ratio >= threshold && !prefs.containsKey(key)) {
          await showBudgetAlert(limitReached: threshold == 1.0);
          await prefs.setBool(key, true);
        } else if (ratio < threshold) {
          await prefs.remove(key);
        }
      }
    }
  }

  Future<void> _cancelRange(int start, int end) async {
    for (var id = start; id < end; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _schedule(int id, DateTime date, NotificationDetails details,
          String title, String body, String payload) =>
      _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          payload: payload,
          scheduledDate: tz.TZDateTime.from(date, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);

  NotificationDetails get _expenseDetails => const NotificationDetails(
      android: AndroidNotificationDetails(_expenseChannel, 'Expense reminders',
          channelDescription: 'Reminders to record spending',
          importance: Importance.defaultImportance));
  NotificationDetails get _billDetails => const NotificationDetails(
      android: AndroidNotificationDetails(_billChannel, 'Bill reminders',
          channelDescription: 'Upcoming bill reminders',
          importance: Importance.defaultImportance));
  NotificationDetails get _budgetDetails => const NotificationDetails(
      android: AndroidNotificationDetails(_budgetChannel, 'Budget alerts',
          channelDescription: 'Budget threshold alerts',
          importance: Importance.high));
}
