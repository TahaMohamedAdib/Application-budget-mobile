import 'dart:convert';

/// Midnight on the same calendar day — pay-date maths must not be thrown off
/// by the time component of `DateTime.now()`.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar-day arithmetic. `Duration(days: n)` is 24*n *hours*, so adding a
/// fortnight across a daylight-saving change lands an hour early and drags the
/// pay date onto the previous day. Rebuilding the date lets DateTime normalise
/// the overflow instead.
DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Whole calendar days from [a] to [b], likewise immune to DST.
int _daysBetween(DateTime a, DateTime b) =>
    (_dateOnly(b).difference(_dateOnly(a)).inHours / 24).round();

class Account {
  final String id;
  final String name;
  final String type; // 'bank', 'savings', 'investment', 'debt'
  final double balance;
  final String? bankName;
  final String? color;
  final bool includeInNetWorth;
  final String? imagePath;
  final String? addedAt;

  // ── Salary auto-credit ──
  //
  // [salaryAmount] is the amount of a single pay packet, not a monthly total:
  // for a weekly earner it is one week's pay. Use [monthlySalaryEquivalent]
  // when a per-month figure is wanted.
  final double? salaryAmount;

  /// 'monthly' (default), 'weekly' or 'biweekly'. Null is read as 'monthly'
  /// so accounts written before pay cycles existed keep their behaviour.
  final String? salaryFrequency;

  /// Monthly: day of month, 1–31 (clamped to the last day in short months).
  /// Weekly / bi-weekly: ISO weekday, 1 = Monday … 7 = Sunday.
  final int? salaryDay;

  /// Any past pay date, as 'yyyy-MM-dd'. Fixes which fortnight a bi-weekly
  /// cycle lands on; ignored by the other two frequencies.
  final String? salaryAnchorDate;

  /// The last pay date credited. Written as 'yyyy-MM-dd'; historic rows hold
  /// 'yyyy-MM' from when only monthly salaries existed and are still read.
  final String? lastSalaryDate;

  // Debt monthly payment (only for type == 'debt')
  final double? debtPaymentAmount; // fixed monthly instalment
  final int? debtPaymentDay; // day of month (1–31)
  final String? debtPaymentSourceId; // account ID to debit from

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.color,
    this.includeInNetWorth = true,
    this.imagePath,
    this.addedAt,
    this.salaryAmount,
    this.salaryFrequency,
    this.salaryDay,
    this.salaryAnchorDate,
    this.lastSalaryDate,
    this.debtPaymentAmount,
    this.debtPaymentDay,
    this.debtPaymentSourceId,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? bankName,
    String? color,
    bool? includeInNetWorth,
    String? imagePath,
    String? addedAt,
    double? salaryAmount,
    String? salaryFrequency,
    int? salaryDay,
    String? salaryAnchorDate,
    String? lastSalaryDate,
    double? debtPaymentAmount,
    int? debtPaymentDay,
    String? debtPaymentSourceId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      color: color ?? this.color,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      imagePath: imagePath ?? this.imagePath,
      addedAt: addedAt ?? this.addedAt,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      salaryFrequency: salaryFrequency ?? this.salaryFrequency,
      salaryDay: salaryDay ?? this.salaryDay,
      salaryAnchorDate: salaryAnchorDate ?? this.salaryAnchorDate,
      lastSalaryDate: lastSalaryDate ?? this.lastSalaryDate,
      debtPaymentAmount: debtPaymentAmount ?? this.debtPaymentAmount,
      debtPaymentDay: debtPaymentDay ?? this.debtPaymentDay,
      debtPaymentSourceId: debtPaymentSourceId ?? this.debtPaymentSourceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'bankName': bankName,
      'color': color,
      'includeInNetWorth': includeInNetWorth,
      'imagePath': imagePath,
      'addedAt': addedAt,
      'salaryAmount': salaryAmount,
      'salaryFrequency': salaryFrequency,
      'salaryDay': salaryDay,
      'salaryAnchorDate': salaryAnchorDate,
      'lastSalaryDate': lastSalaryDate,
      'debtPaymentAmount': debtPaymentAmount,
      'debtPaymentDay': debtPaymentDay,
      'debtPaymentSourceId': debtPaymentSourceId,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      bankName: json['bankName'],
      color: json['color'],
      includeInNetWorth: json['includeInNetWorth'] ?? true,
      imagePath: json['imagePath'],
      addedAt: json['addedAt'],
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble(),
      salaryFrequency: json['salaryFrequency'] as String?,
      salaryDay: json['salaryDay'] as int?,
      salaryAnchorDate: json['salaryAnchorDate'] as String?,
      lastSalaryDate: json['lastSalaryDate'],
      debtPaymentAmount: (json['debtPaymentAmount'] as num?)?.toDouble(),
      debtPaymentDay: json['debtPaymentDay'] as int?,
      debtPaymentSourceId: json['debtPaymentSourceId'] as String?,
    );
  }

  // ── Pay cycle ─────────────────────────────────────────────────────────────

  /// Average number of pay packets in a month, per frequency. 52 weeks over
  /// 12 months, so weekly is 52/12 and bi-weekly 26/12 — using a flat 4 and 2
  /// would under-count by roughly a month's pay a year.
  static const Map<String, double> payPacketsPerMonth = {
    'monthly': 1,
    'biweekly': 26 / 12,
    'weekly': 52 / 12,
  };

  /// Frequency with the legacy null case resolved.
  String get effectiveSalaryFrequency =>
      payPacketsPerMonth.containsKey(salaryFrequency)
          ? salaryFrequency!
          : 'monthly';

  /// [salaryAmount] expressed per month, whatever the underlying cycle.
  /// This is what feeds budgeting — a weekly wage of 500 is 2166.67 a month.
  double get monthlySalaryEquivalent {
    final amount = salaryAmount;
    if (amount == null || amount <= 0) return 0;
    return amount * payPacketsPerMonth[effectiveSalaryFrequency]!;
  }

  /// Whether this account is set up to auto-credit a salary at all.
  bool get hasSalarySchedule => (salaryAmount ?? 0) > 0 && salaryDay != null;

  /// Every pay date strictly after [after] and on or before [until].
  ///
  /// Returned in chronological order so a caller that has been offline for
  /// weeks credits each missed packet once, rather than collapsing them into
  /// a single payment.
  List<DateTime> payDatesBetween(DateTime after, DateTime until) {
    if (!hasSalarySchedule) return const [];
    final dates = <DateTime>[];
    final start = _dateOnly(after);
    final end = _dateOnly(until);

    switch (effectiveSalaryFrequency) {
      case 'monthly':
        // Walk months from the one containing `after`, clamping the requested
        // day into each month so the 31st still pays out in February.
        var cursor = DateTime(start.year, start.month);
        while (true) {
          final lastDay = DateTime(cursor.year, cursor.month + 1, 0).day;
          final date =
              DateTime(cursor.year, cursor.month, salaryDay!.clamp(1, lastDay));
          if (date.isAfter(end)) break;
          if (date.isAfter(start)) dates.add(date);
          cursor = DateTime(cursor.year, cursor.month + 1);
        }
      case 'weekly':
      case 'biweekly':
        final step = effectiveSalaryFrequency == 'weekly' ? 7 : 14;
        var date = _firstPayOnOrBefore(start, step);
        while (true) {
          date = _addDays(date, step);
          if (date.isAfter(end)) break;
          if (date.isAfter(start)) dates.add(date);
        }
    }
    return dates;
  }

  /// The latest pay date on or before [from], used to phase the weekly and
  /// bi-weekly walks. Bi-weekly is aligned to [salaryAnchorDate] so the cycle
  /// stays on the same fortnight across devices.
  DateTime _firstPayOnOrBefore(DateTime from, int step) {
    final weekday = salaryDay!.clamp(1, 7);
    // Most recent occurrence of the chosen weekday, on or before `from`.
    var date = _addDays(from, -((from.weekday - weekday + 7) % 7));

    if (step == 14) {
      final anchorText = salaryAnchorDate;
      final anchor = anchorText == null ? null : DateTime.tryParse(anchorText);
      if (anchor != null) {
        final anchorDay = _dateOnly(anchor);
        // Shift back a week when `date` falls on the off-fortnight.
        final weeksApart = (_daysBetween(anchorDay, date) / 7).round();
        if (weeksApart.isOdd) date = _addDays(date, -7);
      }
    }
    return date;
  }

  /// Sets the pay schedule.
  ///
  /// [copyWith] cannot express this: its `??` semantics read a null argument
  /// as "leave unchanged", so it can set a salary but never remove one. These
  /// two make the difference explicit at the call site.
  Account withSalary({
    required double amount,
    required String frequency,
    required int day,
    String? anchorDate,
  }) =>
      Account(
        id: id,
        name: name,
        type: type,
        balance: balance,
        bankName: bankName,
        color: color,
        includeInNetWorth: includeInNetWorth,
        imagePath: imagePath,
        addedAt: addedAt,
        salaryAmount: amount,
        salaryFrequency: frequency,
        salaryDay: day,
        // Only a fortnightly cycle needs phasing; keeping a stale anchor on
        // the others would be noise in the row.
        salaryAnchorDate: frequency == 'biweekly'
            ? (anchorDate ??
                salaryAnchorDate ??
                DateTime.now().toIso8601String().substring(0, 10))
            : null,
        lastSalaryDate: lastSalaryDate,
        debtPaymentAmount: debtPaymentAmount,
        debtPaymentDay: debtPaymentDay,
        debtPaymentSourceId: debtPaymentSourceId,
      );

  /// Removes the pay schedule entirely, including the record of the last
  /// credit — leaving that behind would suppress the first payment if a
  /// salary were added again later in the same month.
  Account withoutSalary() => Account(
        id: id,
        name: name,
        type: type,
        balance: balance,
        bankName: bankName,
        color: color,
        includeInNetWorth: includeInNetWorth,
        imagePath: imagePath,
        addedAt: addedAt,
        debtPaymentAmount: debtPaymentAmount,
        debtPaymentDay: debtPaymentDay,
        debtPaymentSourceId: debtPaymentSourceId,
      );

  String toJsonString() => jsonEncode(toJson());

  factory Account.fromJsonString(String str) =>
      Account.fromJson(jsonDecode(str));
}
