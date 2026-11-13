import 'dart:convert';
import 'dart:io';

import 'package:safespend_flutter/l10n/translations_core.dart';
import 'package:safespend_flutter/l10n/translations_extra.dart';
import 'package:safespend_flutter/l10n/translations_onboarding.dart';
import 'package:safespend_flutter/l10n/translations_settings.dart';
import 'package:safespend_flutter/l10n/translations_settings_extra.dart';

/// English source copy for feature strings that were previously embedded in
/// widgets. The generator machine-translates this copy and any historical
/// catalog gaps, while preserving the existing hand-edited translations.
const featureEnglish = <String, String>{
  'actionCouldNotBeCompleted': 'That action could not be completed.',
  'activeSubscriptionsSwipe': '{count} active · swipe left to delete',
  'addedAmountToGoal': 'Added {amount} to {name}',
  'addPersonalDebt': 'Add personal debt',
  'addRecurringExpensesFromPlus': 'Add recurring expenses from the + button',
  'addSavings': 'Add Savings',
  'addSavingsGoal': 'Add savings goal',
  'addToSavings': 'Add to Savings',
  'allClear': 'All clear!',
  'alreadyPaidOptional': 'Already Paid (Optional)',
  'alreadyReceivedOptional': 'Already Received (Optional)',
  'alreadySaved': 'Already Saved',
  'amountLent': 'Amount Lent',
  'amountReceivedShort': '{amount} received',
  'amountExceedsMaximum': 'Amount is too large',
  'askVVolletAi': 'Ask VVollet AI',
  'attachReceiptPhoto': 'Attach receipt photo',
  'atLeastEightCharacters': 'At least 8 characters',
  'autoSave': 'Auto-Save',
  'bankFees': 'Bank Fees',
  'billNameHint': 'e.g., Rent, Netflix, Electric',
  'budgetPlanPrompt': 'Create a plan for me',
  'buildTowardWhatMatters': 'Build toward what matters',
  'cancelled': 'Cancelled',
  'cash': 'Cash',
  'cashExpense': 'Cash expense',
  'cashIncome': 'Cash income',
  'cashSources': 'From withdrawals, income & transactions',
  'cashTransactions': 'Cash Transactions',
  'cashWithdrawal': 'Cash withdrawal',
  'categoryNameHint': 'e.g., Clothing',
  'chatConnectionError':
      'Something went wrong. Please check your connection and try again.',
  'coachWelcomeBody':
      'Ask about your spending, budget, savings, or financial goals.',
  'coachWelcomeTitle': 'What can I help you plan?',
  'confirmPassword': 'Confirm Password',
  'conversations': 'Conversations',
  'conversationsCount': '{count} conversations',
  'createGoal': 'Create Goal',
  'createGoalToBeginSaving': 'Create a goal to begin saving',
  'daysAgo': '{count}d ago',
  'debtNameHint': 'e.g., Car Loan, Mortgage',
  'deleteConversationDescription': 'This will permanently delete "{name}".',
  'deleteEntry': 'Delete entry?',
  'deleteProjectDescription':
      'This will delete "{name}". {count} conversations will be unlinked but not deleted.',
  'deleteSubscription': 'Delete Subscription?',
  'defaultCategory_rent': 'Rent/House',
  'defaultCategory_utilities': 'Utilities',
  'defaultCategory_phone': 'Phone/Internet',
  'defaultCategory_subscriptions': 'Subscriptions',
  'defaultCategory_insurance': 'Insurance',
  'defaultCategory_loans': 'Loans',
  'defaultCategory_debt_payment': 'Debt Payment',
  'defaultCategory_subscriptions_budget': 'Subscriptions',
  'defaultCategory_groceries': 'Groceries',
  'defaultCategory_fuel': 'Fuel/Transport',
  'defaultCategory_eating-out': 'Dining Out',
  'defaultCategory_shopping': 'Shopping',
  'defaultCategory_health': 'Health & Fitness',
  'defaultCategory_entertainment': 'Entertainment',
  'defaultCategory_personal': 'Personal Care',
  'defaultCategory_education': 'Education',
  'defaultCategory_travel': 'Travel',
  'defaultCategory_gifts': 'Gifts & Donations',
  'defaultCategory_pets': 'Pets',
  'defaultCategory_other': 'Other',
  'depositTo': 'Deposit to',
  'descriptionOptional': 'Description (optional)',
  'dueOn': 'Due {date}',
  'editEntry': 'Edit Entry',
  'editSubscription': 'Edit Subscription',
  'emailRequired': 'Email is required',
  'enterValidFees': 'Enter valid fees',
  'enterPersonName': 'Enter the person\'s name',
  'enterValidEmail': 'Enter a valid email',
  'failed': 'Failed',
  'goalCreated': 'Goal created',
  'goalName': 'Goal Name',
  'goalNameHint': 'e.g., New Car, Vacation',
  'goalUpdated': 'Goal updated',
  'holdingsCount': '{count} holdings',
  'hoursAgo': '{count}h ago',
  'image': 'Image',
  'includeNumber': 'Include a number',
  'includeSpecialCharacter': 'Include a special character',
  'includeUppercaseLetter': 'Include an uppercase letter',
  'itemsCount': '{count} items',
  'itemAddedSuccessfully': '{item} added successfully',
  'justNow': 'Just now',
  'minutesAgo': '{count}m ago',
  'monthlyAutoSave': 'Monthly Auto-Save',
  'monthlyOverviewPrompt': 'How am I doing this month?',
  'namedItemDeleted': '"{name}" deleted',
  'namedItemUpdated': '"{name}" updated',
  'newSavingsGoal': 'New Savings Goal',
  'nobodyOwesYou': 'Nobody currently owes you money.',
  'noCashTransactions': 'No cash transactions yet',
  'noDataAvailable': 'No data available',
  'noPersonalDebtsRecorded': 'No personal debts recorded',
  'noResponseReceived': 'No response received.',
  'noSavingsGoals': 'No savings goals yet',
  'noUpcomingSubscriptions': 'No upcoming subscriptions',
  'older': 'Older',
  'passwordRequired': 'Password is required',
  'peopleWhoOweYou': 'People Who Owe You',
  'percentOfTotalTargets': '{percent}% of total targets',
  'percentReceived': '{percent}% received',
  'percentRepaid': '{percent}% repaid',
  'personalDebtAdded': 'Added: {name} owes you {amount}',
  'personName': 'Person Name',
  'personNameHint': 'e.g., Ahmed, Mom, Khalid',
  'personPaidInFull': '{name} has paid in full!',
  'planContributionsAndPayouts': 'Plan contributions and payouts',
  'pleaseEnterCategoryName': 'Please enter a category name',
  'pleaseEnterDebtName': 'Please enter a debt name',
  'pleaseEnterGoalName': 'Please enter a goal name',
  'pleaseEnterValidTargetAmount': 'Please enter a valid target amount',
  'pleaseEnterValidTotalAmount': 'Please enter a valid total amount',
  'previousSevenDays': 'Previous 7 Days',
  'reason': 'Reason',
  'reasonHint': 'e.g., Rent, Groceries, Trip',
  'saved': 'Saved',
  'savedFrom': 'Saved From',
  'savingForHint': 'What are you saving for?',
  'salaryDayNumber': 'Salary day {day}',
  'netSavings': 'Net Savings',
  'savingsTipsPrompt': 'Help me save more money',
  'send': 'Send',
  'setDueDateOptional': 'Set Due Date (optional)',
  'sinkingFundCarRepairs': 'Car/Repairs',
  'sinkingFundGifts': 'Gifts',
  'sinkingFundEmergencyFund': 'Emergency Fund',
  'sinkingFundVacation': 'Vacation',
  'paymentDayNumber': 'Payment day {day}',
  'noLimitSetTapToSet': 'No limit set · Tap to set',
  'monthlyContributionAmount': 'Monthly contribution: {amount}',
  'amountPerMonth': '{amount}/mo',
  'savedAmount': '{amount} saved',
  'goalTargetAmount': '{amount} goal',
  'makePayment': 'Make Payment',
  'payDebt': 'Pay Debt',
  'contributeToGoal': 'Contribute to Goal',
  'savedSoFar': 'Saved so far',
  'paidAmountToGoal': '{amount} paid to {name}',
  'contributedAmountToGoal': '{amount} contributed to {name}',
  'someoneOwesMe': 'Someone Owes Me',
  'spendingAnalysisPrompt': 'Where does my money go?',
  'stillOwedAmount': 'Still owed: {amount}',
  'stillOwedToYou': 'Still owed to you',
  'subscriptionName': 'Subscription Name',
  'subscriptionUpdated': 'Subscription updated',
  'tapPlusToCreateFirstGoal': 'Tap + to create your first goal',
  'target': 'Target',
  'thinking': 'Thinking',
  'totalCash': 'Total Cash',
  'totalCount': '{count} total',
  'totalLent': 'Total lent',
  'totalSaved': 'Total Saved',
  'trackBalancesAndRepayments': 'Track balances and repayments',
  'transferFromCash': 'Transfer from cash',
  'transfers': 'Transfers',
  'transferToCash': 'Transfer to cash',
  'unknown': 'Unknown',
  'withdrawalFromBank': 'Withdrawal from bank',
  'withdrawals': 'Withdrawals',
  'withdrawToAddCash': 'Make a withdrawal to add cash on hand',
  'withdrawFrom': 'Withdraw from',
  'ownAccount': 'Own account',
  'sendToPerson': 'Send to person',
  'recipientName': 'Recipient name',
  'recipientNameHint': 'e.g., Ahmed, Mom, Landlord',
  'withdrawalCashInfo': 'The withdrawn amount is added to your cash on hand.',
  'nextIncomeDate': 'Next income date',
  'oneTime': 'One-time',
  'titleOptional': 'Title (optional)',
  'transactionTitleHint': 'e.g., Groceries, Salary, Rent',
  'transactionDescriptionHint': 'Add a note about this transaction',
  'receiptAttached': 'Receipt attached',
  'pleaseSelectAccount': 'Please select an account',
  'pleaseSelectBudgetCategory': 'Please select a budget category',
  'pleaseSelectDestinationAccount': 'Please select a destination account',
  'pleaseEnterRecipientName': 'Please enter the recipient name',
  'sentToRecipient': 'Sent to {name}',
  'transactionUpdated': 'Transaction updated',
  'recurringIncomeAdded': 'Recurring income added',
  'subscriptionAdded': 'Subscription added',
  'setBudgetForCategory': 'Set Budget for {category}',
  'yourGoals': 'Your Goals',
  'spentThisMonthOnly': 'Spent this month: {spent}',
  'amountAvailable': '{amount} available',
  'assetTypeCrypto': 'CRYPTO',
  'assetTypeEtf': 'ETF',
  'assetTypeForex': 'FOREX',
  'assetTypeFund': 'FUND',
  'assetTypeStock': 'STOCK',
  'availableTrackedFrom': '{amount} available · tracked from {date}',
  'averageBuyPricePerUnit': 'Average Buy Price per Unit',
  'averageCost': 'Average Cost',
  'compare': 'Compare',
  'costBasis': 'Cost basis',
  'enteredBuyAmount': 'the entered buy amount',
  'enterValidShares': 'Enter a valid number of shares',
  'existingHoldingAdded': '{symbol} added as an existing holding',
  'fetching': 'Fetching...',
  'fetchLivePriceFor': 'Fetch Live Price for "{symbol}"',
  'historicalPurchaseImportInfo':
      'This purchase happened before {account} started being tracked on {date}, so the holding will be imported without changing that balance.',
  'holdingAddedAndFunded': '{symbol} added and funded from {account}',
  'holdingImportedWithoutBalanceChange':
      'This holding was imported without changing a source account balance.',
  'holdingNotesHint': 'e.g., Long-term hold, Roth IRA',
  'holdingQuantity': '{quantity} {unit}',
  'holdingQuantityLabel': 'Quantity (shares / units)',
  'holdingRemoved': '{symbol} removed',
  'holdingSaleCompleted':
      'Sold {shares} × {symbol} for {amount} → {destination}',
  'holdingShares': '{shares} shares',
  'holdingSharesPurchasedOn': '{shares} shares · {date}',
  'holdingSourceAlreadyAdjusted':
      'This holding already adjusted its source account when it was first added. Editing it here will not move money again.',
  'holdingTitleHint': 'e.g., Apple Stock, Bitcoin Investment',
  'holdingUpdated': '{symbol} updated',
  'livePriceAmount': 'Live price: {amount}',
  'livePriceTapToUse': 'Live price: {amount} · tap to use',
  'noSourceAccountHoldingInfo':
      'No source account selected. This holding will be added without changing any tracked account balance.',
  'notesOptional': 'Notes (optional)',
  'pleaseEnterSymbol': 'Please enter a symbol',
  'portfolioSearchHint': 'e.g., Apple, AAPL, ATW.CS, BTC-USD',
  'portfolioSymbolNotFound':
      'Could not find "{symbol}". Try searching by name above, or use formats: AAPL, ATW.CS, AIR.PA, BTC-USD, EURUSD=X',
  'proceedsGoTo': 'Proceeds go to',
  'purchaseDate': 'Purchase Date',
  'purchaseDeductionInfo':
      'This purchase will deduct {amount} from {account} because the purchase date is on or after {date}.',
  'removeHoldingConfirmation': 'Remove {symbol} from your portfolio?',
  'searchCountry': 'Search country...',
  'selectMarket': 'Select Market',
  'sellForAmount': 'Sell for {amount}',
  'sellSymbol': 'Sell {symbol}',
  'sharesAvailableLivePrice': '{shares} shares available · {amount} live',
  'sharesTimesPrice': 'Shares × Price',
  'sourceAccountHelper':
      'Optional. Pick the account that funded this buy. Older purchases are imported without changing balances.',
  'totalLabel': 'Total',
  'totalPortfolio': 'Total Portfolio',
  'totalProceeds': 'Total proceeds',
  'units': 'units',
  'useLivePrice': 'Use live price',
  'marketCountryGlobalUs': 'Global / US',
  'marketCountryMorocco': 'Morocco',
  'marketCountryEgypt': 'Egypt',
  'marketCountrySouthAfrica': 'South Africa',
  'marketCountryNigeria': 'Nigeria',
  'marketCountryKenya': 'Kenya',
  'marketCountrySaudiArabia': 'Saudi Arabia',
  'marketCountryUae': 'UAE',
  'marketCountryQatar': 'Qatar',
  'marketCountryKuwait': 'Kuwait',
  'marketCountryBahrain': 'Bahrain',
  'marketCountryIsrael': 'Israel',
  'marketCountryTurkey': 'Turkey',
  'marketCountryFrance': 'France',
  'marketCountryGermany': 'Germany',
  'marketCountryUnitedKingdom': 'United Kingdom',
  'marketCountrySpain': 'Spain',
  'marketCountryItaly': 'Italy',
  'marketCountryNetherlands': 'Netherlands',
  'marketCountryBelgium': 'Belgium',
  'marketCountryPortugal': 'Portugal',
  'marketCountrySwitzerland': 'Switzerland',
  'marketCountrySweden': 'Sweden',
  'marketCountryNorway': 'Norway',
  'marketCountryDenmark': 'Denmark',
  'marketCountryFinland': 'Finland',
  'marketCountryAustria': 'Austria',
  'marketCountryPoland': 'Poland',
  'marketCountryCzechRepublic': 'Czech Republic',
  'marketCountryHungary': 'Hungary',
  'marketCountryRussia': 'Russia',
  'marketCountryGreece': 'Greece',
  'marketCountryCanada': 'Canada',
  'marketCountryBrazil': 'Brazil',
  'marketCountryMexico': 'Mexico',
  'marketCountryArgentina': 'Argentina',
  'marketCountryChile': 'Chile',
  'marketCountryColombia': 'Colombia',
  'marketCountryPeru': 'Peru',
  'marketCountryJapan': 'Japan',
  'marketCountryChinaShanghai': 'China (Shanghai)',
  'marketCountryChinaShenzhen': 'China (Shenzhen)',
  'marketCountryHongKong': 'Hong Kong',
  'marketCountrySouthKorea': 'South Korea',
  'marketCountryIndiaNse': 'India (NSE)',
  'marketCountryIndiaBse': 'India (BSE)',
  'marketCountryAustralia': 'Australia',
  'marketCountryNewZealand': 'New Zealand',
  'marketCountrySingapore': 'Singapore',
  'marketCountryMalaysia': 'Malaysia',
  'marketCountryThailand': 'Thailand',
  'marketCountryIndonesia': 'Indonesia',
  'marketCountryPhilippines': 'Philippines',
  'marketCountryVietnam': 'Vietnam',
  'marketCountryTaiwan': 'Taiwan',
  'marketCountryPakistan': 'Pakistan',
};

const _targetLanguage = <String, String>{
  'fr': 'fr',
  'ar': 'ar',
  'es': 'es',
  'de': 'de',
  'pt': 'pt',
  'it': 'it',
  'tr': 'tr',
  'nl': 'nl',
  'ru': 'ru',
  'zh': 'zh-Hans',
  'ja': 'ja',
  'ko': 'ko',
  'hi': 'hi',
  'id': 'id',
  'pl': 'pl',
};

Map<String, Map<String, String>> _baseTranslations() {
  final result = <String, Map<String, String>>{};
  for (final source in [
    translationsCore,
    translationsExtra,
    translationsSettings,
    translationsSettingsExtra,
    translationsOnboarding,
  ]) {
    source.forEach((locale, strings) {
      (result[locale] ??= <String, String>{}).addAll(strings);
    });
  }
  return result;
}

Future<void> main(List<String> arguments) async {
  final base = _baseTranslations();
  final completeEnglish = <String, String>{
    ...base['en']!,
    ...featureEnglish,
  };
  final manifest = <String, Map<String, String>>{'en': featureEnglish};
  for (final locale in _targetLanguage.keys) {
    final existing = base[locale] ?? const <String, String>{};
    manifest[locale] = <String, String>{
      for (final entry in completeEnglish.entries)
        if (!existing.containsKey(entry.key)) entry.key: entry.value,
    };
  }
  await File('tool/translation_manifest.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  if (arguments.contains('--manifest-only')) {
    stdout.writeln('Wrote tool/translation_manifest.json');
    return;
  }

  final generated = <String, Map<String, String>>{'en': featureEnglish};
  final translator = await _BingTranslator.connect();

  for (final locale in _targetLanguage.keys) {
    final missing = manifest[locale]!;
    stdout.writeln('Translating ${missing.length} strings to $locale...');
    generated[locale] = await translator.translateMap(
      missing,
      _targetLanguage[locale]!,
    );
  }

  final output = StringBuffer()
    ..writeln('// Generated by tool/generate_feature_translations.dart.')
    ..writeln('// Existing human-edited strings are never overwritten.')
    ..writeln('const translationsFeatures = <String, Map<String, String>>{');
  for (final locale in ['en', ..._targetLanguage.keys]) {
    output.writeln('  ${jsonEncode(locale)}: {');
    final entries = generated[locale]!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      output
          .writeln('    ${jsonEncode(entry.key)}: ${jsonEncode(entry.value)},');
    }
    output.writeln('  },');
  }
  output.writeln('};');

  await File('lib/l10n/translations_features.dart')
      .writeAsString(output.toString());
  stdout.writeln('Wrote lib/l10n/translations_features.dart');
}

class _BingTranslator {
  _BingTranslator(
      this._client, this._ig, this._iid, this._key, this._token, this._cookies);

  final HttpClient _client;
  final String _ig;
  final String _iid;
  final String _key;
  final String _token;
  final List<Cookie> _cookies;
  var _requestNumber = 1;

  static Future<_BingTranslator> connect() async {
    final client = HttpClient();
    client.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/152 Safari/537.36';
    final request = await client
        .getUrl(Uri.parse('https://www.bing.com/translator?setlang=en'));
    final response = await request.close();
    final page = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw HttpException('Bing bootstrap returned ${response.statusCode}');
    }

    String match(RegExp expression, String label, {int group = 1}) {
      final result = expression.firstMatch(page);
      if (result == null) throw StateError('Could not find Bing $label');
      return result.group(group)!;
    }

    final abuse = RegExp(
      r'params_AbusePreventionHelper\s*=\s*\[([0-9]+),"([^"]+)",([0-9]+)\]',
    ).firstMatch(page);
    if (abuse == null) throw StateError('Could not find Bing request token');

    return _BingTranslator(
      client,
      match(RegExp(r'IG:"([^"]+)"'), 'IG'),
      match(RegExp(r'data-iid="([^"]+)"'), 'IID'),
      abuse.group(1)!,
      abuse.group(2)!,
      response.cookies,
    );
  }

  Future<Map<String, String>> translateMap(
    Map<String, String> source,
    String target,
  ) async {
    final entries = source.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final result = <String, String>{};

    for (var start = 0; start < entries.length;) {
      var end = start;
      var length = 0;
      while (end < entries.length) {
        final protected = _protectPlaceholders(entries[end].value);
        final nextLength = length + protected.length + 24;
        if (end > start && nextLength > 3500) break;
        length = nextLength;
        end++;
      }

      final chunk = entries.sublist(start, end);
      final sourceText = <String>[
        for (var index = 0; index < chunk.length; index++)
          '[[SS_${index.toString().padLeft(4, '0')}]]\n${_protectPlaceholders(chunk[index].value)}',
      ].join('\n');
      final translated = await _translate(sourceText, target);
      final segments = RegExp(
        r'\[\[SS_(\d{4})\]\]\s*([\s\S]*?)(?=\s*\[\[SS_|$)',
      ).allMatches(translated).toList();
      if (segments.length != chunk.length) {
        throw StateError(
          'Expected ${chunk.length} segments for $target, got ${segments.length}',
        );
      }
      for (final segment in segments) {
        final index = int.parse(segment.group(1)!);
        result[chunk[index].key] =
            _restorePlaceholders(segment.group(2)!.trim());
      }
      start = end;
    }
    return result;
  }

  Future<String> _translate(String text, String target) async {
    final uri = Uri.parse(
      'https://www.bing.com/ttranslatev3?isVertical=1&IG=$_ig&IID=$_iid.${_requestNumber++}',
    );
    final request = await _client.postUrl(uri);
    request.cookies.addAll(_cookies);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    final body = <String, String>{
      'fromLang': 'en',
      'text': text,
      'to': target,
      'token': _token,
      'key': _key,
      'tryFetchingGenderDebiasedTranslations': 'true',
    }.entries.map((entry) {
      return '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}';
    }).join('&');
    final bodyBytes = utf8.encode(body);
    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);
    final response = await request.close();
    final payload = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw HttpException(
        'Bing translate returned ${response.statusCode}: $payload',
        uri: uri,
      );
    }
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final translations = decoded['translations'] as List<dynamic>;
    return (translations.first as Map<String, dynamic>)['text'] as String;
  }

  static String _protectPlaceholders(String value) => value.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (match) => '[[PH_${match.group(1)}]]',
      );

  static String _restorePlaceholders(String value) => value.replaceAllMapped(
        RegExp(r'\[\[PH_(\w+)\]\]'),
        (match) => '{${match.group(1)}}',
      );
}
