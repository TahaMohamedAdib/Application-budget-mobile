/// Pure scheduling rules for VVollet's on-device notifications.
///
/// Keeping calendar and quiet-hour rules out of the platform plugin makes them
/// deterministic to test and prevents financial data from entering notification
/// payloads.
class NotificationPlanner {
  static const int reminderDays = 14;

  /// Returns the next [reminderDays] reminder times. A day which already has a
  /// user-entered expense is omitted. Times in the past are never returned.
  static List<DateTime> expenseReminders({
    required DateTime now,
    required int minutesAfterMidnight,
    required Iterable<DateTime> expenseDates,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
  }) {
    final expenseDays = expenseDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    final result = <DateTime>[];
    for (var offset = 0; offset < reminderDays; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (expenseDays.contains(day)) continue;
      var scheduled = DateTime(day.year, day.month, day.day,
          minutesAfterMidnight ~/ 60, minutesAfterMidnight % 60);
      if (!scheduled.isAfter(now)) continue;
      scheduled = afterQuietHours(
        scheduled,
        enabled: quietHoursEnabled,
        start: quietHoursStart,
        end: quietHoursEnd,
      );
      result.add(scheduled);
    }
    return result;
  }

  /// Schedules a due reminder at 09:00 on the day before a future due date.
  static DateTime? dueTomorrowReminder({
    required DateTime dueDate,
    required DateTime now,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
  }) {
    var scheduled = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9);
    if (!scheduled.isAfter(now)) return null;
    return afterQuietHours(scheduled,
        enabled: quietHoursEnabled, start: quietHoursStart, end: quietHoursEnd);
  }

  /// Moves an instant out of a quiet interval. Supports intervals crossing
  /// midnight, e.g. 22:00–07:00.
  static DateTime afterQuietHours(
    DateTime value, {
    required bool enabled,
    required int start,
    required int end,
  }) {
    if (!enabled || start == end) return value;
    final minute = value.hour * 60 + value.minute;
    final quiet = start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
    if (!quiet) return value;
    final isAfterStart = start < end || minute >= start;
    final date = isAfterStart
        ? DateTime(value.year, value.month, value.day + (start < end ? 0 : 1))
        : DateTime(value.year, value.month, value.day);
    return DateTime(date.year, date.month, date.day, end ~/ 60, end % 60);
  }
}
