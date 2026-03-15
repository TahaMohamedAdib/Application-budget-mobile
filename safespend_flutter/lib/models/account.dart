import 'dart:convert';

class Account {
  final String id;
  final String name;
  final String type; // 'bank', 'savings', 'investment', 'debt'
  final double balance;
  final String? bankName;
  final String? color;
  final bool includeInNetWorth;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.color,
    this.includeInNetWorth = true,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? bankName,
    String? color,
    bool? includeInNetWorth,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      color: color ?? this.color,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
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
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Account.fromJsonString(String str) => Account.fromJson(jsonDecode(str));
}
