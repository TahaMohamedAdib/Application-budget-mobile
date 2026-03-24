import 'dart:convert';

class Transaction {
  final String id;
  final String type; // 'expense', 'income', 'transfer', 'withdrawal'
  final double amount;
  final String date;
  final String? note;
  final String? description;
  final String? categoryId;
  final String accountId;
  final String? toAccountId; // For transfers
  final bool isRecurring;
  final String? imagePath;
  final String? expenseSubType; // 'subscription' | 'bill' | null (expense only)

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.description,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.isRecurring = false,
    this.imagePath,
    this.expenseSubType,
  });

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? date,
    String? note,
    String? description,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    bool? isRecurring,
    String? imagePath,
    String? expenseSubType,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      isRecurring: isRecurring ?? this.isRecurring,
      imagePath: imagePath ?? this.imagePath,
      expenseSubType: expenseSubType ?? this.expenseSubType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date,
      'note': note,
      'description': description,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'isRecurring': isRecurring,
      'imagePath': imagePath,
      'expenseSubType': expenseSubType,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      note: json['note'],
      description: json['description'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      isRecurring: json['isRecurring'] ?? false,
      imagePath: json['imagePath'],
      expenseSubType: json['expenseSubType'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Transaction.fromJsonString(String str) => Transaction.fromJson(jsonDecode(str));
}
