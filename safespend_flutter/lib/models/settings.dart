import 'dart:convert';

/// User preferences.
///
/// Persistence is split in two:
///
/// * The five fields the `profiles` table has columns for (currency,
///   monthlyIncome, isDarkMode, netWorthScope, selectedAccountId) round-trip
///   through Supabase and follow the account across devices.
/// * Everything else is device-local — it is written to SharedPreferences as
///   the full JSON blob but has no remote column. Adding a remote column for
///   these would mean a migration, so they deliberately stay on-device.
///
/// Because a remotely-loaded profile can only ever populate that first group,
/// never assign one straight over the live settings — use [withRemoteProfile],
/// which keeps the device-local group intact.
class Settings {
  // ── Synced with the `profiles` table ──
  final String currency;
  final double monthlyIncome;
  final bool isDarkMode;
  final String netWorthScope; // 'all' or specific account ID
  final String? selectedAccountId;

  // ── Device-local: general ──
  final String themeMode; // 'light', 'dark', 'system'
  final String locale; // 'en', 'fr', 'ar', 'es', etc.

  // ── Device-local: appearance ──
  /// Multiplier applied on top of the platform text scale. 0.9 – 1.3.
  final double textScale;

  /// Renders balances as dots until explicitly revealed.
  final bool hideAmounts;

  // ── Device-local: number & date formatting ──
  final int decimalPlaces; // 0 or 2
  final bool compactNumbers; // 12.4K instead of 12,400.00
  final String dateFormat; // 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'
  final int firstDayOfWeek; // DateTime.monday .. DateTime.sunday

  // ── Device-local: notifications ──
  final bool? notificationsEnabled;
  final bool billReminders;
  final bool budgetAlerts;
  final bool dailySummary;
  final bool weeklyReport;
  final bool largeTransactionAlerts;
  final double largeTransactionThreshold;
  final bool quietHoursEnabled;
  final int quietHoursStart; // minutes from midnight
  final int quietHoursEnd;

  // ── Device-local: security & privacy ──
  final bool appLockEnabled;

  /// Minutes of background time before the lock re-arms. 0 = immediately.
  final int autoLockMinutes;

  /// Masks the screen in the app switcher.
  final bool maskOnAppSwitch;

  final bool analyticsEnabled;
  final bool crashReportsEnabled;

  const Settings({
    this.currency = 'USD',
    this.monthlyIncome = 0,
    this.isDarkMode = false,
    this.netWorthScope = 'all',
    this.selectedAccountId,
    this.themeMode = 'system',
    this.locale = 'en',
    this.textScale = 1.0,
    this.hideAmounts = false,
    this.decimalPlaces = 2,
    this.compactNumbers = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.firstDayOfWeek = DateTime.monday,
    this.notificationsEnabled = true,
    this.billReminders = true,
    this.budgetAlerts = true,
    this.dailySummary = false,
    this.weeklyReport = true,
    this.largeTransactionAlerts = false,
    this.largeTransactionThreshold = 1000,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22 * 60,
    this.quietHoursEnd = 7 * 60,
    this.appLockEnabled = false,
    this.autoLockMinutes = 0,
    this.maskOnAppSwitch = false,
    this.analyticsEnabled = true,
    this.crashReportsEnabled = true,
  });

  Settings copyWith({
    String? currency,
    double? monthlyIncome,
    bool? isDarkMode,
    String? netWorthScope,
    String? selectedAccountId,
    String? themeMode,
    String? locale,
    double? textScale,
    bool? hideAmounts,
    int? decimalPlaces,
    bool? compactNumbers,
    String? dateFormat,
    int? firstDayOfWeek,
    bool? notificationsEnabled,
    bool? billReminders,
    bool? budgetAlerts,
    bool? dailySummary,
    bool? weeklyReport,
    bool? largeTransactionAlerts,
    double? largeTransactionThreshold,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? appLockEnabled,
    int? autoLockMinutes,
    bool? maskOnAppSwitch,
    bool? analyticsEnabled,
    bool? crashReportsEnabled,
  }) {
    return Settings(
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      netWorthScope: netWorthScope ?? this.netWorthScope,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      textScale: textScale ?? this.textScale,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      compactNumbers: compactNumbers ?? this.compactNumbers,
      dateFormat: dateFormat ?? this.dateFormat,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      billReminders: billReminders ?? this.billReminders,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      dailySummary: dailySummary ?? this.dailySummary,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      largeTransactionAlerts:
          largeTransactionAlerts ?? this.largeTransactionAlerts,
      largeTransactionThreshold:
          largeTransactionThreshold ?? this.largeTransactionThreshold,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      maskOnAppSwitch: maskOnAppSwitch ?? this.maskOnAppSwitch,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    );
  }

  /// Folds a profile loaded from Supabase into these settings.
  ///
  /// Only the fields the `profiles` table actually stores are taken from
  /// [remote]; every device-local preference is preserved. Without this,
  /// signing in resets theme mode, language and every preference below to
  /// their defaults, because [Settings] objects built by
  /// `SupabaseSyncService.loadProfile` carry defaults for all of them.
  Settings withRemoteProfile(Settings remote) {
    return copyWith(
      currency: remote.currency,
      monthlyIncome: remote.monthlyIncome,
      isDarkMode: remote.isDarkMode,
      netWorthScope: remote.netWorthScope,
      selectedAccountId: remote.selectedAccountId,
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
      'textScale': textScale,
      'hideAmounts': hideAmounts,
      'decimalPlaces': decimalPlaces,
      'compactNumbers': compactNumbers,
      'dateFormat': dateFormat,
      'firstDayOfWeek': firstDayOfWeek,
      'billReminders': billReminders,
      'budgetAlerts': budgetAlerts,
      'dailySummary': dailySummary,
      'weeklyReport': weeklyReport,
      'largeTransactionAlerts': largeTransactionAlerts,
      'largeTransactionThreshold': largeTransactionThreshold,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'appLockEnabled': appLockEnabled,
      'autoLockMinutes': autoLockMinutes,
      'maskOnAppSwitch': maskOnAppSwitch,
      'analyticsEnabled': analyticsEnabled,
      'crashReportsEnabled': crashReportsEnabled,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    // Every read is defaulted: settings blobs written by older builds of the
    // app are missing the device-local keys entirely.
    return Settings(
      currency: json['currency'] ?? 'USD',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      isDarkMode: json['isDarkMode'] ?? false,
      themeMode: json['themeMode'] ?? 'system',
      netWorthScope: json['netWorthScope'] ?? 'all',
      selectedAccountId: json['selectedAccountId'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      locale: json['locale'] ?? 'en',
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      hideAmounts: json['hideAmounts'] ?? false,
      decimalPlaces: (json['decimalPlaces'] as num?)?.toInt() ?? 2,
      compactNumbers: json['compactNumbers'] ?? false,
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      firstDayOfWeek:
          (json['firstDayOfWeek'] as num?)?.toInt() ?? DateTime.monday,
      billReminders: json['billReminders'] ?? true,
      budgetAlerts: json['budgetAlerts'] ?? true,
      dailySummary: json['dailySummary'] ?? false,
      weeklyReport: json['weeklyReport'] ?? true,
      largeTransactionAlerts: json['largeTransactionAlerts'] ?? false,
      largeTransactionThreshold:
          (json['largeTransactionThreshold'] as num?)?.toDouble() ?? 1000,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: (json['quietHoursStart'] as num?)?.toInt() ?? 22 * 60,
      quietHoursEnd: (json['quietHoursEnd'] as num?)?.toInt() ?? 7 * 60,
      appLockEnabled: json['appLockEnabled'] ?? false,
      autoLockMinutes: (json['autoLockMinutes'] as num?)?.toInt() ?? 0,
      maskOnAppSwitch: json['maskOnAppSwitch'] ?? false,
      analyticsEnabled: json['analyticsEnabled'] ?? true,
      crashReportsEnabled: json['crashReportsEnabled'] ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Settings.fromJsonString(String str) =>
      Settings.fromJson(jsonDecode(str));

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
          locale == other.locale &&
          textScale == other.textScale &&
          hideAmounts == other.hideAmounts &&
          decimalPlaces == other.decimalPlaces &&
          compactNumbers == other.compactNumbers &&
          dateFormat == other.dateFormat &&
          firstDayOfWeek == other.firstDayOfWeek &&
          billReminders == other.billReminders &&
          budgetAlerts == other.budgetAlerts &&
          dailySummary == other.dailySummary &&
          weeklyReport == other.weeklyReport &&
          largeTransactionAlerts == other.largeTransactionAlerts &&
          largeTransactionThreshold == other.largeTransactionThreshold &&
          quietHoursEnabled == other.quietHoursEnabled &&
          quietHoursStart == other.quietHoursStart &&
          quietHoursEnd == other.quietHoursEnd &&
          appLockEnabled == other.appLockEnabled &&
          autoLockMinutes == other.autoLockMinutes &&
          maskOnAppSwitch == other.maskOnAppSwitch &&
          analyticsEnabled == other.analyticsEnabled &&
          crashReportsEnabled == other.crashReportsEnabled;

  @override
  int get hashCode => Object.hashAll([
        currency,
        monthlyIncome,
        isDarkMode,
        themeMode,
        netWorthScope,
        selectedAccountId,
        notificationsEnabled,
        locale,
        textScale,
        hideAmounts,
        decimalPlaces,
        compactNumbers,
        dateFormat,
        firstDayOfWeek,
        billReminders,
        budgetAlerts,
        dailySummary,
        weeklyReport,
        largeTransactionAlerts,
        largeTransactionThreshold,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
        appLockEnabled,
        autoLockMinutes,
        maskOnAppSwitch,
        analyticsEnabled,
        crashReportsEnabled,
      ]);
}
