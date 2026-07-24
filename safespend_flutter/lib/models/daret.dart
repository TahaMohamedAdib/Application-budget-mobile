import 'dart:convert';

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
  final int paymentDay; // day of month for contributions (1–28)
  final bool isActive;

  /// Highest daret month (1-based) for which a payout transaction has already
  /// been generated. Persisted so restarting the app never duplicates payouts.
  final int lastPayoutMonthProcessed;

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
    this.lastPayoutMonthProcessed = 0,
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

  /// Whether the daret cycle is complete
  bool get isComplete => currentMonth >= totalShares;

  /// How many months remain
  int get remainingMonths => (totalShares - currentMonth).clamp(0, totalShares);

  /// Remaining liability: what the user still owes
  double get remainingLiability => remainingMonths * monthlyPayment;

  /// Total already paid so far
  double get totalPaidSoFar => currentMonth * monthlyPayment;

  /// Total actually received so far: payouts whose month has been processed
  /// (i.e. a real `daret_payout` transaction credited an account). This reflects
  /// account balances rather than the calendar, so the screen never shows money
  /// that was never received. Falls back to the calendar view for legacy darets
  /// that predate payout processing (lastPayoutMonthProcessed == 0 while the
  /// cycle has already advanced past a scheduled payout).
  double get totalReceivedSoFar {
    final effectiveMonth = lastPayoutMonthProcessed > 0
        ? lastPayoutMonthProcessed
        : currentMonth;
    return payoutMonths.where((m) => m <= effectiveMonth).length *
        singlePayoutAmount;
  }

  /// Payout months that are due (<= currentMonth) but not yet processed.
  List<int> get pendingPayoutMonths {
    return payoutMonths
        .where((m) => m <= currentMonth && m > lastPayoutMonthProcessed)
        .toList()
      ..sort();
  }

  /// Next payout month (0 if none remaining)
  int get nextPayoutMonth {
    final upcoming = payoutMonths.where((m) => m > currentMonth).toList()..sort();
    return upcoming.isNotEmpty ? upcoming.first : 0;
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
    int? lastPayoutMonthProcessed,
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
      lastPayoutMonthProcessed:
          lastPayoutMonthProcessed ?? this.lastPayoutMonthProcessed,
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
      'lastPayoutMonthProcessed': lastPayoutMonthProcessed,
    };
  }

  factory Daret.fromJson(Map<String, dynamic> json) {
    return Daret(
      id: json['id'],
      name: json['name'],
      contributionPerShare: (json['contributionPerShare'] as num).toDouble(),
      totalShares: json['totalShares'] as int,
      userShares: json['userShares'] as int? ?? 1,
      payoutMonths: (json['payoutMonths'] as List).map((e) => e as int).toList(),
      startDate: json['startDate'],
      paymentSourceId: json['paymentSourceId'],
      destinationAccountId: json['destinationAccountId'],
      paymentDay: json['paymentDay'] as int? ?? 1,
      isActive: json['isActive'] ?? true,
      lastPayoutMonthProcessed: json['lastPayoutMonthProcessed'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Daret.fromJsonString(String str) => Daret.fromJson(jsonDecode(str));
}
