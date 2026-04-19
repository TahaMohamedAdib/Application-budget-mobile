import 'dart:convert';

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
  final double? monthlyPayment;         // fixed monthly instalment
  final int? paymentDay;                // day of month (1–28)
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
    String? description,
    double? targetAmount,
    String? targetDate,
    double? currentAmount,
    int? priority,
    String? categoryId,
    String? icon,
    String? imagePath,
    String? color,
    double? monthlyPayment,
    int? paymentDay,
    String? paymentSourceAccountId,
  }) {
    return Goal(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      currentAmount: currentAmount ?? this.currentAmount,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      paymentDay: paymentDay ?? this.paymentDay,
      paymentSourceAccountId: paymentSourceAccountId ?? this.paymentSourceAccountId,
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
