import 'dart:convert';

import 'package:uuid/uuid.dart';

class DaretPayment {
  const DaretPayment({
    required this.daretId,
    required this.daretName,
    required this.round,
    required this.dueDate,
    required this.amount,
    required this.accountId,
    required this.isPayout,
  });

  final String daretId;
  final String daretName;
  final int round;
  final DateTime dueDate;
  final double amount;
  final String accountId;
  final bool isPayout;

  String get transactionType =>
      isPayout ? 'daret_payout' : 'daret_contribution';
  String get id => const Uuid().v5(
      Namespace.url.value, 'vvollet:daret:$daretId:$round:$transactionType');
}

class Daret {
  final String id;
  final String name;
  final double contributionPerShare;
  final int totalShares;
  final int userShares;
  final List<int> payoutMonths; // 1-based month indices when user gets paid
  final String startDate; // ISO 8601
  final String paymentSourceId; // account ID or 'cash_on_hand'
  final String destinationAccountId; // where payout is deposited
  final int paymentDay; // day of month for contributions and scheduled payouts
  final bool isActive;

  Daret({
    required this.id,
    required this.name,
    required this.contributionPerShare,
    required this.totalShares,
    this.userShares = 1,
    required this.payoutMonths,
    required this.startDate,
    required this.paymentSourceId,
    required this.destinationAccountId,
    this.paymentDay = 1,
    this.isActive = true,
  });

  // ── Calculations ──────────────────────────────────────────────

  /// Amount the user pays each month
  double get monthlyPayment => contributionPerShare * userShares;

  /// Amount received in a single payout round
  double get singlePayoutAmount => contributionPerShare * totalShares;

  /// Total the user will receive across all their payout months
  double get totalCyclePayout => singlePayoutAmount * userShares;

  /// Total the user will pay over the entire cycle
  double get totalCycleContribution => monthlyPayment * totalShares;

  DateTime? dueDateForRound(int round) {
    final start = DateTime.tryParse(startDate);
    if (start == null || round < 1 || round > totalShares) return null;
    final firstDay = DateTime(start.year, start.month, start.day);
    final month = DateTime(start.year, start.month + round - 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final scheduled =
        DateTime(month.year, month.month, paymentDay.clamp(1, lastDay));
    return scheduled.isBefore(firstDay) ? firstDay : scheduled;
  }

  Iterable<DaretPayment> paymentsThrough(DateTime date) sync* {
    if (!isActive ||
        !monthlyPayment.isFinite ||
        !singlePayoutAmount.isFinite ||
        monthlyPayment <= 0 ||
        singlePayoutAmount <= 0) {
      return;
    }
    final today = DateTime(date.year, date.month, date.day);
    for (var round = 1; round <= totalShares; round++) {
      final due = dueDateForRound(round);
      if (due == null || due.isAfter(today)) break;
      yield DaretPayment(
        daretId: id,
        daretName: name,
        round: round,
        dueDate: due,
        amount: monthlyPayment,
        accountId: paymentSourceId,
        isPayout: false,
      );
      if (payoutMonths.contains(round)) {
        yield DaretPayment(
          daretId: id,
          daretName: name,
          round: round,
          dueDate: due,
          amount: singlePayoutAmount,
          accountId: destinationAccountId,
          isPayout: true,
        );
      }
    }
  }

  /// Net gain/loss over the cycle (always 0 in a fair daret)
  double get netGainLoss => totalCyclePayout - totalCycleContribution;

  /// Which month (1-based) we are currently in, based on startDate
  int get currentMonth {
    final start = DateTime.parse(startDate);
    final now = DateTime.now();
    if (now.isBefore(start)) return 0;
    final months = (now.year - start.year) * 12 + (now.month - start.month) + 1;
    return months.clamp(1, totalShares);
  }

  /// Progress as fraction (0.0 – 1.0)
  double get progress => totalShares > 0 ? currentMonth / totalShares : 0;

  // ── Serialization ─────────────────────────────────────────────

  Daret copyWith({
    String? id,
    String? name,
    double? contributionPerShare,
    int? totalShares,
    int? userShares,
    List<int>? payoutMonths,
    String? startDate,
    String? paymentSourceId,
    String? destinationAccountId,
    int? paymentDay,
    bool? isActive,
  }) {
    return Daret(
      id: id ?? this.id,
      name: name ?? this.name,
      contributionPerShare: contributionPerShare ?? this.contributionPerShare,
      totalShares: totalShares ?? this.totalShares,
      userShares: userShares ?? this.userShares,
      payoutMonths: payoutMonths ?? this.payoutMonths,
      startDate: startDate ?? this.startDate,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      paymentDay: paymentDay ?? this.paymentDay,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contributionPerShare': contributionPerShare,
      'totalShares': totalShares,
      'userShares': userShares,
      'payoutMonths': payoutMonths,
      'startDate': startDate,
      'paymentSourceId': paymentSourceId,
      'destinationAccountId': destinationAccountId,
      'paymentDay': paymentDay,
      'isActive': isActive,
    };
  }

  factory Daret.fromJson(Map<String, dynamic> json) {
    return Daret(
      id: json['id'],
      name: json['name'],
      contributionPerShare: (json['contributionPerShare'] as num).toDouble(),
      totalShares: json['totalShares'] as int,
      userShares: json['userShares'] as int? ?? 1,
      payoutMonths:
          (json['payoutMonths'] as List).map((e) => e as int).toList(),
      startDate: json['startDate'],
      paymentSourceId: json['paymentSourceId'],
      destinationAccountId: json['destinationAccountId'],
      paymentDay: json['paymentDay'] as int? ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Daret.fromJsonString(String str) => Daret.fromJson(jsonDecode(str));
}
