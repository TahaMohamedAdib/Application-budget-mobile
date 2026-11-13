import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/notifications/notification_planner.dart';

void main() {
  group('NotificationPlanner', () {
    test('skips days which already contain a user expense', () {
      final now = DateTime(2026, 11, 7, 8);
      final reminders = NotificationPlanner.expenseReminders(
        now: now,
        minutesAfterMidnight: 20 * 60,
        expenseDates: [DateTime(2026, 11, 7, 10)],
        quietHoursEnabled: false,
        quietHoursStart: 0,
        quietHoursEnd: 0,
      );
      expect(reminders.first, DateTime(2026, 11, 8, 20));
      expect(reminders, hasLength(NotificationPlanner.reminderDays - 1));
    });

    test('moves a quiet-hours reminder to quiet-hours end', () {
      expect(
        NotificationPlanner.afterQuietHours(DateTime(2026, 11, 7, 23),
            enabled: true, start: 22 * 60, end: 7 * 60),
        DateTime(2026, 11, 8, 7),
      );
      expect(
        NotificationPlanner.afterQuietHours(DateTime(2026, 11, 7, 4),
            enabled: true, start: 22 * 60, end: 7 * 60),
        DateTime(2026, 11, 7, 7),
      );
    });

    test('does not schedule a stale due-tomorrow reminder', () {
      final now = DateTime(2026, 11, 7, 10);
      expect(
        NotificationPlanner.dueTomorrowReminder(
            dueDate: DateTime(2026, 11, 8),
            now: now,
            quietHoursEnabled: false,
            quietHoursStart: 0,
            quietHoursEnd: 0),
        isNull,
      );
    });
  });
}
