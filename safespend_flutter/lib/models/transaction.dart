import 'dart:convert';

/// Sentinel distinguishing "argument omitted" from an explicit `null` in
/// [Transaction.copyWith], so nullable fields can be cleared to null.
const Object _unset = Object();

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
  final String? daretId; // Linked daret (ROSCA) contribution or payout
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
    this.daretId,
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
    Object? note = _unset,
    Object? description = _unset,
    Object? categoryId = _unset,
    String? accountId,
    Object? toAccountId = _unset,
    Object? goalId = _unset,
    Object? daretId = _unset,
    bool? isRecurring,
    Object? imagePath = _unset,
    Object? expenseSubType = _unset,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      date: date ?? this.date,
      note: identical(note, _unset) ? this.note : note as String?,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      categoryId:
          identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
      accountId: accountId ?? this.accountId,
      toAccountId: identical(toAccountId, _unset)
          ? this.toAccountId
          : toAccountId as String?,
      goalId: identical(goalId, _unset) ? this.goalId : goalId as String?,
      daretId: identical(daretId, _unset) ? this.daretId : daretId as String?,
      isRecurring: isRecurring ?? this.isRecurring,
      imagePath:
          identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      expenseSubType: identical(expenseSubType, _unset)
          ? this.expenseSubType
          : expenseSubType as String?,
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
      'daretId': daretId,
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
      daretId: json['daretId'],
      isRecurring: json['isRecurring'] ?? false,
      imagePath: json['imagePath'],
      expenseSubType: json['expenseSubType'],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Transaction.fromJsonString(String str) =>
      Transaction.fromJson(jsonDecode(str));
}
