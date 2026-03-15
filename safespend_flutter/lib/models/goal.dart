import 'dart:convert';

class Goal {
  final String id;
  final String type; // 'savings', 'debt', 'investment', 'custom'
  final String name;
  final double targetAmount;
  final String? targetDate;
  final double currentAmount;
  final int priority;
  final String? categoryId;
  final String icon;
  final String color;

  Goal({
    required this.id,
    this.type = 'savings',
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.currentAmount = 0,
    this.priority = 0,
    this.categoryId,
    this.icon = '🎯',
    this.color = '#B8860B',
  });

  Goal copyWith({
    String? id,
    String? type,
    String? name,
    double? targetAmount,
    String? targetDate,
    double? currentAmount,
    int? priority,
    String? categoryId,
    String? icon,
    String? color,
  }) {
    return Goal(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      currentAmount: currentAmount ?? this.currentAmount,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'targetAmount': targetAmount,
      'targetDate': targetDate,
      'currentAmount': currentAmount,
      'priority': priority,
      'categoryId': categoryId,
      'icon': icon,
      'color': color,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      type: json['type'] ?? 'savings',
      name: json['name'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      targetDate: json['targetDate'],
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      priority: json['priority'] ?? 0,
      categoryId: json['categoryId'],
      icon: json['icon'] ?? '🎯',
      color: json['color'] ?? '#B8860B',
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Goal.fromJsonString(String str) => Goal.fromJson(jsonDecode(str));
}
