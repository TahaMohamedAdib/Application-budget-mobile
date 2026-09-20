/// Advances [from] by one recurrence while preserving its wall-clock time.
///
/// Calendar arithmetic is intentional here. Adding a 24-hour [Duration] can
/// land on the wrong local hour across daylight-saving changes, and Dart's
/// normalisation of `DateTime(year, month + 1, 31)` skips February entirely.
DateTime advanceRecurringDate(
  DateTime from,
  String frequency, {
  int? scheduledDay,
}) {
  DateTime atDate(int year, int month, int day) => DateTime(
        year,
        month,
        day,
        from.hour,
        from.minute,
        from.second,
        from.millisecond,
        from.microsecond,
      );

  switch (frequency) {
    case 'daily':
      return atDate(from.year, from.month, from.day + 1);
    case 'weekly':
      return atDate(from.year, from.month, from.day + 7);
    case 'yearly':
      final targetDay = scheduledDay ?? from.day;
      final lastDay = DateTime(from.year + 1, from.month + 1, 0).day;
      return atDate(from.year + 1, from.month, targetDay.clamp(1, lastDay));
    default:
      final targetDay = scheduledDay ?? from.day;
      final targetMonth = DateTime(from.year, from.month + 1, 1);
      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      return atDate(
        targetMonth.year,
        targetMonth.month,
        targetDay.clamp(1, lastDay),
      );
  }
}
