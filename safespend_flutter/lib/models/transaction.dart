import 'dart:convert';

class Transaction {
  final String id;
  final String type; // 'expense', 'income', 'transfer', 'withdrawal'
  final double amount;
  final double fees; // Bank fees added on top of amount
  final String date;
  final String? note;
  final String? description;
  final String? categoryId;
  final String accountId;
  final String? toAccountId; // For transfers
  final String? goalId; // Linked savings goal, debt, or personal debt
  final bool isRecurring;
  final String? imagePath;
  final String? expenseSubType; // 'subscription' | 'bill' | null (expense only)

  /// Total deducted from account = amount + fees
  double get totalWithFees => amount + fees;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.fees = 0,
    required this.date,
    this.note,
    this.description,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.goalId,
    this.isRecurring = false,
    this.imagePath,
    this.expenseSubType,
  });

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    double? fees,
    String? date,
    String? note,
    String? description,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? goalId,
    bool? isRecurring,
    String? imagePath,
    String? expenseSubType,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      date: date ?? this.date,
      note: note ?? this.note,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      goalId: goalId ?? this.goalId,
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
      'fees': fees,
      'date': date,
      'note': note,
      'description': description,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'goalId': goalId,
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
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
      date: json['date'],
      note: json['note'],
      description: json['description'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      goalId: json['goalId'],
      isRecurring: json['isRecurring'] ?? false,
      imagePath: json['imagePath'],
      expenseSubType: json['expenseSubType'],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Transaction.fromJsonString(String str) =>
      Transaction.fromJson(jsonDecode(str));
}
