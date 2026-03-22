import 'dart:convert';

class Settings {
  final String currency;
  final double monthlyIncome;
  final bool isDarkMode;
  final String netWorthScope; // 'all' or specific account ID
  final String? selectedAccountId;
  final bool? notificationsEnabled;

  Settings({
    this.currency = 'USD',
    this.monthlyIncome = 0,
    this.isDarkMode = false,
    this.netWorthScope = 'all',
    this.selectedAccountId,
    this.notificationsEnabled = true,
  });

  Settings copyWith({
    String? currency,
    double? monthlyIncome,
    bool? isDarkMode,
    String? netWorthScope,
    String? selectedAccountId,
    bool? notificationsEnabled,
  }) {
    return Settings(
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      netWorthScope: netWorthScope ?? this.netWorthScope,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'monthlyIncome': monthlyIncome,
      'isDarkMode': isDarkMode,
      'netWorthScope': netWorthScope,
      'selectedAccountId': selectedAccountId,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      currency: json['currency'] ?? 'USD',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      isDarkMode: json['isDarkMode'] ?? false,
      netWorthScope: json['netWorthScope'] ?? 'all',
      selectedAccountId: json['selectedAccountId'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Settings.fromJsonString(String str) => Settings.fromJson(jsonDecode(str));
}
