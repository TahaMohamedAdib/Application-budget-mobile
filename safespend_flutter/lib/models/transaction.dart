import 'dart:convert';

class Transaction {
  final String id;
  final String type; // 'expense', 'income', 'transfer', 'withdrawal'
  final double amount;
  final String date;
  final String? note;
  final String? categoryId;
  final String accountId;
  final String? toAccountId; // For transfers
  final bool isRecurring;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.isRecurring = false,
  });

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? date,
    String? note,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    bool? isRecurring,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date,
      'note': note,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'isRecurring': isRecurring,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      note: json['note'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Transaction.fromJsonString(String str) => Transaction.fromJson(jsonDecode(str));
}
