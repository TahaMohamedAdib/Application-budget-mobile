import 'dart:convert';

class Settings {
  final String currency;
  final double monthlyIncome;
  final bool isDarkMode;
  final String themeMode; // 'light', 'dark', 'system'
  final String netWorthScope; // 'all' or specific account ID
  final String? selectedAccountId;
  final bool? notificationsEnabled;
  final String locale; // 'en', 'fr', 'ar', 'es', etc.

  Settings({
    this.currency = 'USD',
    this.monthlyIncome = 0,
    this.isDarkMode = false,
    this.themeMode = 'system',
    this.netWorthScope = 'all',
    this.selectedAccountId,
    this.notificationsEnabled = true,
    this.locale = 'en',
  });

  Settings copyWith({
    String? currency,
    double? monthlyIncome,
    bool? isDarkMode,
    String? themeMode,
    String? netWorthScope,
    String? selectedAccountId,
    bool? notificationsEnabled,
    String? locale,
  }) {
    return Settings(
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeMode: themeMode ?? this.themeMode,
      netWorthScope: netWorthScope ?? this.netWorthScope,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'monthlyIncome': monthlyIncome,
      'isDarkMode': isDarkMode,
      'themeMode': themeMode,
      'netWorthScope': netWorthScope,
      'selectedAccountId': selectedAccountId,
      'notificationsEnabled': notificationsEnabled,
      'locale': locale,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      currency: json['currency'] ?? 'USD',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      isDarkMode: json['isDarkMode'] ?? false,
      themeMode: json['themeMode'] ?? 'system',
      netWorthScope: json['netWorthScope'] ?? 'all',
      selectedAccountId: json['selectedAccountId'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      locale: json['locale'] ?? 'en',
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Settings.fromJsonString(String str) => Settings.fromJson(jsonDecode(str));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          currency == other.currency &&
          monthlyIncome == other.monthlyIncome &&
          isDarkMode == other.isDarkMode &&
          themeMode == other.themeMode &&
          netWorthScope == other.netWorthScope &&
          selectedAccountId == other.selectedAccountId &&
          notificationsEnabled == other.notificationsEnabled &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(
        currency, monthlyIncome, isDarkMode, themeMode,
        netWorthScope, selectedAccountId, notificationsEnabled, locale,
      );
}
