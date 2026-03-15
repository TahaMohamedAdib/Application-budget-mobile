import 'dart:convert';
import 'transaction.dart';

class RecurringRule {
  final String id;
  final Transaction templateTransaction;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String nextDate;
  final bool isActive;

  RecurringRule({
    required this.id,
    required this.templateTransaction,
    required this.frequency,
    required this.nextDate,
    this.isActive = true,
  });

  RecurringRule copyWith({
    String? id,
    Transaction? templateTransaction,
    String? frequency,
    String? nextDate,
    bool? isActive,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      templateTransaction: templateTransaction ?? this.templateTransaction,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateTransaction': templateTransaction.toJson(),
      'frequency': frequency,
      'nextDate': nextDate,
      'isActive': isActive,
    };
  }

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['id'],
      templateTransaction: Transaction.fromJson(json['templateTransaction']),
      frequency: json['frequency'],
      nextDate: json['nextDate'],
      isActive: json['isActive'] ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory RecurringRule.fromJsonString(String str) => RecurringRule.fromJson(jsonDecode(str));
}
