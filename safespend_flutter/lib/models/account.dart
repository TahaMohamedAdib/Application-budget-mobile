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

  // Salary auto-credit
  final double? salaryAmount; // monthly salary to auto-add
  final int? salaryDay;       // day of month (1–31)
  final String? lastSalaryDate; // 'yyyy-MM' — month salary was last credited

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.color,
    this.includeInNetWorth = true,
    this.imagePath,
    this.salaryAmount,
    this.salaryDay,
    this.lastSalaryDate,
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
    double? salaryAmount,
    int? salaryDay,
    String? lastSalaryDate,
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
      salaryAmount: salaryAmount ?? this.salaryAmount,
      salaryDay: salaryDay ?? this.salaryDay,
      lastSalaryDate: lastSalaryDate ?? this.lastSalaryDate,
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
      'salaryAmount': salaryAmount,
      'salaryDay': salaryDay,
      'lastSalaryDate': lastSalaryDate,
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
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble(),
      salaryDay: json['salaryDay'] as int?,
      lastSalaryDate: json['lastSalaryDate'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Account.fromJsonString(String str) => Account.fromJson(jsonDecode(str));
}
