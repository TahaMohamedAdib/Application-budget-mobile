import 'dart:convert';

class Category {
  final String id;
  final String name;
  final String group; // 'fixed' or 'variable'
  final String icon;
  final String color;
  final double budgetLimit; // monthly spending cap (0 = no limit set)

  Category({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    required this.color,
    this.budgetLimit = 0.0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? group,
    String? icon,
    String? color,
    double? budgetLimit,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'icon': icon,
      'color': color,
      'budgetLimit': budgetLimit,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      group: json['group'],
      icon: json['icon'],
      color: json['color'],
      budgetLimit: (json['budgetLimit'] ?? 0.0).toDouble(),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Category.fromJsonString(String str) => Category.fromJson(jsonDecode(str));
}

// Default categories
final List<Category> defaultCategories = [
  // Fixed
  Category(id: 'rent', name: 'Rent/House', group: 'fixed', icon: 'home', color: '#ef4444'),
  Category(id: 'utilities', name: 'Utilities', group: 'fixed', icon: 'flash', color: '#f97316'),
  Category(id: 'phone', name: 'Phone/Internet', group: 'fixed', icon: 'phone', color: '#8b5cf6'),
  Category(id: 'subscriptions', name: 'Subscriptions', group: 'fixed', icon: 'tv', color: '#ec4899'),
  Category(id: 'insurance', name: 'Insurance', group: 'fixed', icon: 'shield', color: '#06b6d4'),
  Category(id: 'loans', name: 'Loans', group: 'fixed', icon: 'credit_card', color: '#64748b'),
  
  // Variable
  Category(id: 'subscriptions_budget', name: 'Subscriptions', group: 'variable', icon: 'autorenew', color: '#ec4899'),
  Category(id: 'groceries', name: 'Groceries', group: 'variable', icon: 'shopping_cart', color: '#10B981'),
  Category(id: 'fuel', name: 'Fuel/Transport', group: 'variable', icon: 'car', color: '#3b82f6'),
  Category(id: 'eating-out', name: 'Dining Out', group: 'variable', icon: 'restaurant', color: '#f59e0b'),
  Category(id: 'shopping', name: 'Shopping', group: 'variable', icon: 'shopping_bag', color: '#a855f7'),
  Category(id: 'health', name: 'Health & Fitness', group: 'variable', icon: 'favorite', color: '#ef4444'),
  Category(id: 'entertainment', name: 'Entertainment', group: 'variable', icon: 'sports_esports', color: '#10b981'),
  Category(id: 'personal', name: 'Personal Care', group: 'variable', icon: 'face', color: '#ec4899'),
  Category(id: 'education', name: 'Education', group: 'variable', icon: 'school', color: '#3b82f6'),
  Category(id: 'travel', name: 'Travel', group: 'variable', icon: 'flight', color: '#06b6d4'),
  Category(id: 'gifts', name: 'Gifts & Donations', group: 'variable', icon: 'card_giftcard', color: '#f97316'),
  Category(id: 'pets', name: 'Pets', group: 'variable', icon: 'pets', color: '#8b5cf6'),
  Category(id: 'other', name: 'Other', group: 'variable', icon: 'more_horiz', color: '#64748b'),
];
