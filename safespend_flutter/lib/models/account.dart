import 'dart:convert';

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
    int? salaryDay,
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
      salaryDay: salaryDay ?? this.salaryDay,
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
      'salaryDay': salaryDay,
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
      salaryDay: json['salaryDay'] as int?,
      lastSalaryDate: json['lastSalaryDate'],
      debtPaymentAmount: (json['debtPaymentAmount'] as num?)?.toDouble(),
      debtPaymentDay: json['debtPaymentDay'] as int?,
      debtPaymentSourceId: json['debtPaymentSourceId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Account.fromJsonString(String str) => Account.fromJson(jsonDecode(str));
}
