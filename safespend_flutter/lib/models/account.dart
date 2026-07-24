import 'dart:convert';

/// Sentinel distinguishing "argument omitted" from an explicit `null` in
/// [Account.copyWith], so nullable fields can be cleared to null.
const Object _unset = Object();

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

  // Salary auto-credit
  final double? salaryAmount; // monthly salary to auto-add
  final int? salaryDay;       // day of month (1–31)
  final String? lastSalaryDate; // 'yyyy-MM' — month salary was last credited

  // Debt monthly payment (only for type == 'debt')
  final double? debtPaymentAmount;    // fixed monthly instalment
  final int? debtPaymentDay;          // day of month (1–31)
  final String? debtPaymentSourceId;  // account ID to debit from

  /// Last local mutation time (ISO-8601). Used for sync conflict resolution.
  final String? updatedAt;

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
    this.salaryDay,
    this.lastSalaryDate,
    this.debtPaymentAmount,
    this.debtPaymentDay,
    this.debtPaymentSourceId,
    this.updatedAt,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    Object? bankName = _unset,
    Object? color = _unset,
    bool? includeInNetWorth,
    Object? imagePath = _unset,
    Object? addedAt = _unset,
    Object? salaryAmount = _unset,
    Object? salaryDay = _unset,
    Object? lastSalaryDate = _unset,
    Object? debtPaymentAmount = _unset,
    Object? debtPaymentDay = _unset,
    Object? debtPaymentSourceId = _unset,
    String? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: identical(bankName, _unset) ? this.bankName : bankName as String?,
      color: identical(color, _unset) ? this.color : color as String?,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      imagePath:
          identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      addedAt: identical(addedAt, _unset) ? this.addedAt : addedAt as String?,
      salaryAmount: identical(salaryAmount, _unset)
          ? this.salaryAmount
          : salaryAmount as double?,
      salaryDay:
          identical(salaryDay, _unset) ? this.salaryDay : salaryDay as int?,
      lastSalaryDate: identical(lastSalaryDate, _unset)
          ? this.lastSalaryDate
          : lastSalaryDate as String?,
      debtPaymentAmount: identical(debtPaymentAmount, _unset)
          ? this.debtPaymentAmount
          : debtPaymentAmount as double?,
      debtPaymentDay: identical(debtPaymentDay, _unset)
          ? this.debtPaymentDay
          : debtPaymentDay as int?,
      debtPaymentSourceId: identical(debtPaymentSourceId, _unset)
          ? this.debtPaymentSourceId
          : debtPaymentSourceId as String?,
      // A copyWith call represents a local mutation → refresh the sync stamp
      // unless the caller pins it explicitly (e.g. restoring from remote).
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
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
      'salaryDay': salaryDay,
      'lastSalaryDate': lastSalaryDate,
      'debtPaymentAmount': debtPaymentAmount,
      'debtPaymentDay': debtPaymentDay,
      'debtPaymentSourceId': debtPaymentSourceId,
      'updatedAt': updatedAt,
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
      salaryDay: json['salaryDay'] as int?,
      lastSalaryDate: json['lastSalaryDate'],
      debtPaymentAmount: (json['debtPaymentAmount'] as num?)?.toDouble(),
      debtPaymentDay: json['debtPaymentDay'] as int?,
      debtPaymentSourceId: json['debtPaymentSourceId'] as String?,
      updatedAt: json['updatedAt'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Account.fromJsonString(String str) => Account.fromJson(jsonDecode(str));
}
