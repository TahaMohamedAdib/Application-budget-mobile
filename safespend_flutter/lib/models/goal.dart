import 'dart:convert';

const Object _notProvided = Object();

class Goal {
  final String id;
  final String type; // 'savings', 'debt', 'investment', 'custom'
  final String name;
  final String? description;
  final double targetAmount;
  final String? targetDate;
  final double currentAmount;
  final int priority;
  final String? categoryId;
  final String icon;
  final String? imagePath; // custom icon from gallery
  final String color;

  // Debt monthly payment (only relevant when type == 'debt')
  final double? monthlyPayment; // fixed monthly instalment
  final int? paymentDay; // day of month (1–28)
  final String? paymentSourceAccountId; // account ID to debit from

  Goal({
    required this.id,
    this.type = 'savings',
    required this.name,
    this.description,
    required this.targetAmount,
    this.targetDate,
    this.currentAmount = 0,
    this.priority = 0,
    this.categoryId,
    this.icon = '🎯',
    this.imagePath,
    this.color = '#B8860B',
    this.monthlyPayment,
    this.paymentDay,
    this.paymentSourceAccountId,
  });

  Goal copyWith({
    String? id,
    String? type,
    String? name,
    Object? description = _notProvided,
    double? targetAmount,
    Object? targetDate = _notProvided,
    double? currentAmount,
    int? priority,
    Object? categoryId = _notProvided,
    String? icon,
    Object? imagePath = _notProvided,
    String? color,
    Object? monthlyPayment = _notProvided,
    Object? paymentDay = _notProvided,
    Object? paymentSourceAccountId = _notProvided,
  }) {
    return Goal(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: identical(description, _notProvided)
          ? this.description
          : description as String?,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: identical(targetDate, _notProvided)
          ? this.targetDate
          : targetDate as String?,
      currentAmount: currentAmount ?? this.currentAmount,
      priority: priority ?? this.priority,
      categoryId: identical(categoryId, _notProvided)
          ? this.categoryId
          : categoryId as String?,
      icon: icon ?? this.icon,
      imagePath: identical(imagePath, _notProvided)
          ? this.imagePath
          : imagePath as String?,
      color: color ?? this.color,
      monthlyPayment: identical(monthlyPayment, _notProvided)
          ? this.monthlyPayment
          : monthlyPayment as double?,
      paymentDay: identical(paymentDay, _notProvided)
          ? this.paymentDay
          : paymentDay as int?,
      paymentSourceAccountId: identical(paymentSourceAccountId, _notProvided)
          ? this.paymentSourceAccountId
          : paymentSourceAccountId as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate,
      'currentAmount': currentAmount,
      'priority': priority,
      'categoryId': categoryId,
      'icon': icon,
      'imagePath': imagePath,
      'color': color,
      'monthlyPayment': monthlyPayment,
      'paymentDay': paymentDay,
      'paymentSourceAccountId': paymentSourceAccountId,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      type: json['type'] ?? 'savings',
      name: json['name'],
      description: json['description'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      targetDate: json['targetDate'],
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      priority: json['priority'] ?? 0,
      categoryId: json['categoryId'],
      icon: json['icon'] ?? '🎯',
      imagePath: json['imagePath'],
      color: json['color'] ?? '#B8860B',
      monthlyPayment: (json['monthlyPayment'] as num?)?.toDouble(),
      paymentDay: json['paymentDay'] as int?,
      paymentSourceAccountId: json['paymentSourceAccountId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Goal.fromJsonString(String str) => Goal.fromJson(jsonDecode(str));
}
