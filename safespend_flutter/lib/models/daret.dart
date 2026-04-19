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

  /// Total received so far (payouts in months <= currentMonth)
  double get totalReceivedSoFar {
    return payoutMonths.where((m) => m <= currentMonth).length * singlePayoutAmount;
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
      payoutMonths: (json['payoutMonths'] as List).map((e) => e as int).toList(),
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
