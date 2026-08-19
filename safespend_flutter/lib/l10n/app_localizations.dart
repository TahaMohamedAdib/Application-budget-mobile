import 'package:flutter/material.dart';
import 'translations.dart';

class S {
  final String _locale;

  S._(String locale) : _locale = normalizeLocaleCode(locale);

  static const fallbackLocale = 'en';

  static S of(BuildContext context) =>
      S._(Localizations.localeOf(context).languageCode);

  static S forLocale(String locale) => S._(locale);

  static String normalizeLocaleCode(String? locale) {
    if (locale == null || locale.trim().isEmpty) return fallbackLocale;
    final normalized =
        locale.replaceAll('-', '_').split('_').first.toLowerCase();
    return languageNames.containsKey(normalized) ? normalized : fallbackLocale;
  }

  static String displayNameForLocale(String? locale) =>
      localeDisplayNames[normalizeLocaleCode(locale)] ??
      localeDisplayNames[fallbackLocale]!;

  static String flagForLocale(String? locale) =>
      localeFlags[normalizeLocaleCode(locale)] ?? '\u{1F310}';

  String _t(String key) =>
      translations[_locale]?[key] ?? translations[fallbackLocale]?[key] ?? key;

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('es'),
    Locale('de'),
    Locale('pt'),
    Locale('it'),
    Locale('tr'),
    Locale('nl'),
    Locale('ru'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('hi'),
    Locale('id'),
    Locale('pl'),
  ];

  static const languageNames = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
    'pt': 'Português',
    'it': 'Italiano',
    'tr': 'Türkçe',
    'nl': 'Nederlands',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'pl': 'Polski',
  };

  static const languageFlags = {
    'en': '🇬🇧',
    'fr': '🇫🇷',
    'ar': '🇲🇦',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'pt': '🇵🇹',
    'it': '🇮🇹',
    'tr': '🇹🇷',
    'nl': '🇳🇱',
    'ru': '🇷🇺',
    'zh': '🇨🇳',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'hi': '🇮🇳',
    'id': '🇮🇩',
    'pl': '🇵🇱',
  };

  static const localeDisplayNames = {
    'en': 'English',
    'fr': 'Fran\u00e7ais',
    'ar': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    'es': 'Espa\u00f1ol',
    'de': 'Deutsch',
    'pt': 'Portugu\u00eas',
    'it': 'Italiano',
    'tr': 'T\u00fcrk\u00e7e',
    'nl': 'Nederlands',
    'ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    'zh': '\u4e2d\u6587',
    'ja': '\u65e5\u672c\u8a9e',
    'ko': '\ud55c\uad6d\uc5b4',
    'hi': '\u0939\u093f\u0928\u094d\u0926\u0940',
    'id': 'Bahasa Indonesia',
    'pl': 'Polski',
  };

  static const localeFlags = {
    'en': '\u{1F1EC}\u{1F1E7}',
    'fr': '\u{1F1EB}\u{1F1F7}',
    'ar': '\u{1F1F2}\u{1F1E6}',
    'es': '\u{1F1EA}\u{1F1F8}',
    'de': '\u{1F1E9}\u{1F1EA}',
    'pt': '\u{1F1F5}\u{1F1F9}',
    'it': '\u{1F1EE}\u{1F1F9}',
    'tr': '\u{1F1F9}\u{1F1F7}',
    'nl': '\u{1F1F3}\u{1F1F1}',
    'ru': '\u{1F1F7}\u{1F1FA}',
    'zh': '\u{1F1E8}\u{1F1F3}',
    'ja': '\u{1F1EF}\u{1F1F5}',
    'ko': '\u{1F1F0}\u{1F1F7}',
    'hi': '\u{1F1EE}\u{1F1F3}',
    'id': '\u{1F1EE}\u{1F1E9}',
    'pl': '\u{1F1F5}\u{1F1F1}',
  };

  // Common
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get close => _t('close');
  String get done => _t('done');
  String get update => _t('update');
  String get confirm => _t('confirm');
  String get add => _t('add');
  String get remove => _t('remove');
  String get search => _t('search');
  String get loading => _t('loading');
  String get error => _t('error');
  String get success => _t('success');
  String get ok => _t('ok');
  String get yes => _t('yes');
  String get no => _t('no');
  String get retry => _t('retry');
  String get next => _t('next');
  String get back => _t('back');
  String get create => _t('create');
  String get change => _t('change');
  String get perMonth => _t('perMonth');
  String get of_ => _t('of');
  String get month => _t('month');
  String get months => _t('months');
  String get day => _t('day');
  String get all => _t('all');

  // Navigation
  String get today => _t('today');
  String get plan => _t('plan');
  String get wealth => _t('wealth');
  String get coach => _t('coach');

  // Settings
  String get settings => _t('settings');
  String get appearance => _t('appearance');
  String get light => _t('light');
  String get dark => _t('dark');
  String get system => _t('system');
  String get currency => _t('currency');
  String get selectCurrency => _t('selectCurrency');
  String get searchCurrency => _t('searchCurrency');
  String get noCurrenciesFound => _t('noCurrenciesFound');
  String get language => _t('language');
  String get selectLanguage => _t('selectLanguage');
  String get account => _t('account');
  String get notifications => _t('notifications');
  String get pushNotifications => _t('pushNotifications');
  String get remindersForBills => _t('remindersForBills');
  String get privacy => _t('privacy');
  String get privacyDesc => _t('privacyDesc');
  String get helpAndSupport => _t('helpAndSupport');
  String get logOut => _t('logOut');
  String get logOutConfirm => _t('logOutConfirm');
  String get logOutDesc => _t('logOutDesc');
  String get version => _t('version');

  // Account
  String get profileInformation => _t('profileInformation');
  String get displayName => _t('displayName');
  String get howYouAppear => _t('howYouAppear');
  String get enterYourName => _t('enterYourName');
  String get emailAddress => _t('emailAddress');
  String get usedForSignIn => _t('usedForSignIn');
  String get security => _t('security');
  String get password => _t('password');
  String get changePassword => _t('changePassword');
  String get currentPassword => _t('currentPassword');
  String get newPassword => _t('newPassword');
  String get confirmNewPassword => _t('confirmNewPassword');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');
  String get passwordTooShort => _t('passwordTooShort');
  String get enterCurrentPwd => _t('enterCurrentPwd');
  String get enterNewPwd => _t('enterNewPwd');
  String get nameUpdated => _t('nameUpdated');
  String get passwordChanged => _t('passwordChanged');
  String get updatePassword => _t('updatePassword');
  String get localMode => _t('localMode');
  String get manageProfile => _t('manageProfile');
  String get user => _t('user');

  // Wealth
  String get netWorth => _t('netWorth');
  String get cashOnHand => _t('cashOnHand');
  String get investments => _t('investments');
  String get debt => _t('debt');
  String get personalDebts => _t('personalDebts');
  String get savingsGoals => _t('savingsGoals');
  String get savingsGoal => _t('savingsGoal');
  String get debtPayoff => _t('debtPayoff');
  String get addSinkingFund => _t('addSinkingFund');
  String get stocksFundsEtc => _t('stocksFundsEtc');
  String get loansAndDebts => _t('loansAndDebts');
  String get moneyPeopleOweMe => _t('moneyPeopleOweMe');
  String get moneyForGoals => _t('moneyForGoals');
  String get rotatingSavings => _t('rotatingSavings');
  String get selectAccount => _t('selectAccount');
  String get allAccounts => _t('allAccounts');
  String get accountsCombined => _t('accountsCombined');
  String get breakdown => _t('breakdown');

  // Daret
  String get daret => _t('daret');
  String get activeDarets => _t('activeDarets');
  String get remaining => _t('remaining');
  String get active => _t('active');
  String get completed => _t('completed');
  String get noDaretsYet => _t('noDaretsYet');
  String get tapToCreateDaret => _t('tapToCreateDaret');
  String get newDaret => _t('newDaret');
  String get editDaret => _t('editDaret');
  String get createDaret => _t('createDaret');
  String get saveChanges => _t('saveChanges');
  String get name => _t('name');
  String get contributionPerShare => _t('contributionPerShare');
  String get totalShares => _t('totalShares');
  String get peopleInGroup => _t('peopleInGroup');
  String get yourShares => _t('yourShares');
  String get howManySlots => _t('howManySlots');
  String get payoutMonths => _t('payoutMonths');
  String get selectPayoutMonth => _t('selectPayoutMonth');
  String get paymentDayOfMonth => _t('paymentDayOfMonth');
  String get startDate => _t('startDate');
  String get sourceAccount => _t('sourceAccount');
  String get monthlyDeduction => _t('monthlyDeduction');
  String get destinationAccount => _t('destinationAccount');
  String get payoutDeposit => _t('payoutDeposit');
  String get summary => _t('summary');
  String get monthlyPayment => _t('monthlyPayment');
  String get singlePayout => _t('singlePayout');
  String get totalCyclePayout => _t('totalCyclePayout');
  String get remainingLiability => _t('remainingLiability');
  String get totalPaidSoFar => _t('totalPaidSoFar');
  String get totalReceivedSoFar => _t('totalReceivedSoFar');
  String get payoutTimeline => _t('payoutTimeline');
  String get payoutMonth => _t('payoutMonth');
  String get currentMonthLabel => _t('currentMonthLabel');
  String get allPayoutsReceived => _t('allPayoutsReceived');
  String get deleteDaret => _t('deleteDaret');
  String get deleteDaretConfirm => _t('deleteDaretConfirm');
  String get savingsCircle => _t('savingsCircle');
  String get activeUppercase => _t('activeUppercase');
  String get completedUppercase => _t('completedUppercase');
  String get pleaseEnterContribution => _t('pleaseEnterContribution');
  String get totalSharesMustBePositive => _t('totalSharesMustBePositive');
  String get payoutTo => _t('payoutTo');
  String get payoutDayOfEachMonth => _t('payoutDayOfEachMonth');
  String get monthOf => _t('monthOf');
  String get contributionHint => _t('contributionHint');
  String get contributionAmountHint => _t('contributionAmountHint');
  String get totalSharesHint => _t('totalSharesHint');
  String get yourSlotsLabel => _t('yourSlotsLabel');
  String get saveChangesLabel => _t('saveChangesLabel');
  String get createDaretLabel => _t('createDaretLabel');
  String get people => _t('people');
  String get share => _t('share');
  String get shares => _t('shares');

  // Home
  String get totalBalance => _t('totalBalance');
  String get safeToSpend => _t('safeToSpend');
  String get income => _t('income');
  String get expenses => _t('expenses');
  String get recentTransactions => _t('recentTransactions');
  String get seeAll => _t('seeAll');
  String get noTransactions => _t('noTransactions');
  String get addTransaction => _t('addTransaction');
  String get thisWeek => _t('thisWeek');
  String get thisMonth => _t('thisMonth');

  // Spending
  String get spending => _t('spending');
  String get weekly => _t('weekly');
  String get monthly => _t('monthly');
  String get topCategories => _t('topCategories');
  String get noSpendingData => _t('noSpendingData');

  // Plan
  String get fixedExpenses => _t('fixedExpenses');
  String get variableExpenses => _t('variableExpenses');
  String get sinkingFunds => _t('sinkingFunds');
  String get monthlyIncome => _t('monthlyIncome');
  String get bills => _t('bills');
  String get subscriptions => _t('subscriptions');
  String get noBills => _t('noBills');
  String get noSubscriptions => _t('noSubscriptions');

  // Goals
  String get goals => _t('goals');
  String get addGoal => _t('addGoal');
  String get editGoal => _t('editGoal');
  String get deleteGoal => _t('deleteGoal');
  String get contribute => _t('contribute');
  String get targetAmount => _t('targetAmount');
  String get currentProgress => _t('currentProgress');
  String get targetDate => _t('targetDate');
  String get description => _t('description');

  // Portfolio
  String get portfolio => _t('portfolio');
  String get holdings => _t('holdings');
  String get addHolding => _t('addHolding');
  String get totalValue => _t('totalValue');
  String get totalCost => _t('totalCost');
  String get gainLoss => _t('gainLoss');
  String get pricePerShare => _t('pricePerShare');
  String get currentPrice => _t('currentPrice');

  // Debt
  String get debts => _t('debts');
  String get addDebt => _t('addDebt');
  String get totalDebt => _t('totalDebt');
  String get paymentDay => _t('paymentDay');
  String get remainingBalance => _t('remainingBalance');
  String get paidOff => _t('paidOff');

  // Accounts
  String get accounts => _t('accounts');
  String get addAccount => _t('addAccount');
  String get bankAccount => _t('bankAccount');
  String get savingsAccount => _t('savingsAccount');
  String get investmentAccount => _t('investmentAccount');
  String get debtAccount => _t('debtAccount');
  String get balance => _t('balance');
  String get bankName => _t('bankName');
  String get accountName => _t('accountName');
  String get accountType => _t('accountType');

  // Transactions
  String get transactions => _t('transactions');
  String get expense => _t('expense');
  String get incomeLabel => _t('incomeLabel');
  String get transfer => _t('transfer');
  String get withdrawal => _t('withdrawal');
  String get amount => _t('amount');
  String get date => _t('date');
  String get category => _t('category');
  String get note => _t('note');
  String get fromAccount => _t('fromAccount');
  String get toAccount => _t('toAccount');
  String get recurring => _t('recurring');
  String get subscription => _t('subscription');
  String get bill => _t('bill');
  String get addIncome => _t('addIncome');
  String get addExpense => _t('addExpense');
  String get transferMoney => _t('transferMoney');
  String get withdraw => _t('withdraw');
  String get recordMoneyComingIn => _t('recordMoneyComingIn');
  String get moveMoneyBetweenAccounts => _t('moveMoneyBetweenAccounts');
  String get withdrawCash => _t('withdrawCash');
  String get recordPurchaseOrPayment => _t('recordPurchaseOrPayment');
  String get goalContribution => _t('goalContribution');
  String get debtPaymentLabel => _t('debtPaymentLabel');

  // Auth
  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get email => _t('email');
  String get forgotPassword => _t('forgotPassword');
  String get continueWithout => _t('continueWithout');
  String get createAccount => _t('createAccount');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get dontHaveAccount => _t('dontHaveAccount');

  // Onboarding
  String get welcome => _t('welcome');
  String get getStarted => _t('getStarted');
  String get letsGo => _t('letsGo');
  String get skip => _t('skip');

  // Coach
  String get financialCoach => _t('financialCoach');
  String get askAnything => _t('askAnything');
  String get suggestions => _t('suggestions');

  // Help
  String get helpQ1 => _t('helpQ1');
  String get helpA1 => _t('helpA1');
  String get helpQ2 => _t('helpQ2');
  String get helpA2 => _t('helpA2');
  String get helpQ3 => _t('helpQ3');
  String get helpA3 => _t('helpA3');
  String get gotIt => _t('gotIt');

  // Additional translations
  String get allTime => _t('allTime');
  String get fromWithdrawals => _t('fromWithdrawals');
  String get balanceEvolution => _t('balanceEvolution');
  String get upcomingSubscriptions => _t('upcomingSubscriptions');
  String get noSubscriptionsYet => _t('noSubscriptionsYet');
  String get type => _t('type');
  String get sort => _t('sort');
  String get sortNewest => _t('sortNewest');
  String get sortOldest => _t('sortOldest');
  String get sortHighest => _t('sortHighest');
  String get sortLowest => _t('sortLowest');
  String get noTransactionsFound => _t('noTransactionsFound');
  String get tryAdjustingFilters => _t('tryAdjustingFilters');
  String get tapToAddFirstTransaction => _t('tapToAddFirstTransaction');
  String get notEnoughData => _t('notEnoughData');
  String get transaction => _t('transaction');
  String get subtype => _t('subtype');
  String get receipt => _t('receipt');
  String get deleteTransaction => _t('deleteTransaction');
  String get deleteConfirm => _t('deleteConfirm');
  String get allSubscriptions => _t('allSubscriptions');
  String get checkingCurrent => _t('checkingCurrent');
  String get dueDateOptional => _t('dueDateOptional');
  String get sortBy => _t('sortBy');
  String get noChartData => _t('noChartData');
  String get sell => _t('sell');
  String get setBudget => _t('setBudget');
  String get spentThisMonth => _t('spentThisMonth');
  String get removeLimit => _t('removeLimit');
  String get noExpensesYet => _t('noExpensesYet');
  String get uploadFromGallery => _t('uploadFromGallery');
  String get orChooseIcon => _t('orChooseIcon');
  String get tapToOpen => _t('tapToOpen');
  String get editTransaction => _t('editTransaction');
  String get addBill => _t('addBill');
  String get editBill => _t('editBill');
  String get frequency => _t('frequency');
  String get nextDueDate => _t('nextDueDate');
  String get billAdded => _t('billAdded');
  String get pleaseEnterName => _t('pleaseEnterName');
  String get pleaseEnterAmount => _t('pleaseEnterAmount');
  String get billName => _t('billName');
  String get billAmount => _t('billAmount');
  String get payFrom => _t('payFrom');
  String get daily => _t('daily');
  String get yearly => _t('yearly');
  String get addCategory => _t('addCategory');
  String get editCategory => _t('editCategory');
  String get categoryName => _t('categoryName');
  String get spendingLimit => _t('spendingLimit');
  String get setSpendingLimit => _t('setSpendingLimit');
  String get enterValidNumber => _t('enterValidNumber');
  String get logo => _t('logo');
  String get enterName => _t('enterName');
  String get enterAmount => _t('enterAmount');
  String get addDebtTitle => _t('addDebtTitle');
  String get editDebtTitle => _t('editDebtTitle');
  String get totalAmount => _t('totalAmount');
  String get dueDate => _t('dueDate');
  String get originalAmount => _t('originalAmount');
  String get soldFor => _t('soldFor');
  String get sellPricePerShare => _t('sellPricePerShare');
  String get numberOfSharesToSell => _t('numberOfSharesToSell');
  String get youOnlyHold => _t('youOnlyHold');
  String get enterSharesToSell => _t('enterSharesToSell');
  String get enterSellPrice => _t('enterSellPrice');
  String get sellShares => _t('sellShares');
  String get confirmSell => _t('confirmSell');
  String get sharesSold => _t('sharesSold');
  String get howManyShares => _t('howManyShares');
  String get profit => _t('profit');
  String get loss => _t('loss');
  String get marketClosed => _t('marketClosed');
  String get budgets => _t('budgets');
  String get manageBudgets => _t('manageBudgets');
  String get noBudgetCategories => _t('noBudgetCategories');
  String get createCategoriesDesc => _t('createCategoriesDesc');
  String get createFirstCategory => _t('createFirstCategory');
  String get overBudgetBy => _t('overBudgetBy');
  String get monthlyBudget => _t('monthlyBudget');
  String get noLimitSet => _t('noLimitSet');
  String get over => _t('over');
  String get categoryAdded => _t('categoryAdded');
  String get cannotBeUndone => _t('cannotBeUndone');
  String get spentOfThisMonth => _t('spentOfThisMonth');
  String get spentThisMonthOnly => _t('spentThisMonthOnly');
  String get expensesAddedHere => _t('expensesAddedHere');
  String get livePrices => _t('livePrices');
  String get assets => _t('assets');
  String get chart => _t('chart');
  String get oneWeek => _t('oneWeek');
  String get oneMonth => _t('oneMonth');
  String get threeMonths => _t('threeMonths');
  String get oneYear => _t('oneYear');
  String get removeFromPortfolio => _t('removeFromPortfolio');
  String get removed => _t('removed');
  String get added => _t('added');
  String get updated => _t('updated');
  String get soldShares => _t('soldShares');
  String get compareHoldings => _t('compareHoldings');
  String get fromPortfolio => _t('fromPortfolio');
  String get pinchToZoom => _t('pinchToZoom');
  String get yesterday => _t('yesterday');
  String get debtPayment => _t('debtPayment');
  String get yourDebts => _t('yourDebts');
  String get noDebts => _t('noDebts');
  String get youHaveNoActiveDebts => _t('youHaveNoActiveDebts');
  String get paid => _t('paid');
  String get complete => _t('complete');
  String get pay => _t('pay');
  String get received => _t('received');
  String get paymentHistory => _t('paymentHistory');
  String get recordPayment => _t('recordPayment');
  String get amountPaid => _t('amountPaid');
  String get paidFromOptional => _t('paidFromOptional');
  String get noAccountDeduction => _t('noAccountDeduction');
  String get enterValidAmount => _t('enterValidAmount');
  String get isFullyPaidOff => _t('isFullyPaidOff');
  String get paidOn => _t('paidOn');
  String get paymentReceived => _t('paymentReceived');
  String get amountReceivedWillBeAdded => _t('amountReceivedWillBeAdded');
  String get amountReceived => _t('amountReceived');
  String get addToAccount => _t('addToAccount');
  String get confirmReceipt => _t('confirmReceipt');
  String get receivedFrom => _t('receivedFrom');
  String get editDebt => _t('editDebt');
  String get icon => _t('icon');
  String get debtName => _t('debtName');
  String get notSet => _t('notSet');
  String get monthlyPaymentLabel => _t('monthlyPaymentLabel');
  String get monthlyAmount => _t('monthlyAmount');
  String get debtAdded => _t('debtAdded');
  String get external => _t('external');
  String get welcomeBack => _t('welcomeBack');
  String get confirmEmail => _t('confirmEmail');
  String get checkInbox => _t('checkInbox');
  String get resendEmail => _t('resendEmail');
  String get confirmationEmailResent => _t('confirmationEmailResent');
  String get failedToResend => _t('failedToResend');
  String get activePositions => _t('activePositions');
  String get investedAmount => _t('investedAmount');
  String get myPortfolio => _t('myPortfolio');
  String get noHoldings => _t('noHoldings');
  String get addHoldingDesc => _t('addHoldingDesc');
  String get deleteHolding => _t('deleteHolding');
  String get editHolding => _t('editHolding');
  String get market => _t('market');
  String get searchByTickerOrName => _t('searchByTickerOrName');
  // Accounts
  String get noAccountsYet => _t('noAccountsYet');
  String get tapPlusToAddFirstAccount => _t('tapPlusToAddFirstAccount');
  String get allAssociatedTransactionsWillBeRemoved =>
      _t('allAssociatedTransactionsWillBeRemoved');
  String get excluded => _t('excluded');
  String get hintCheckingAccount => _t('hintCheckingAccount');
  String get hintChaseBank => _t('hintChaseBank');
  String get color => _t('color');
  String get automaticallyPayDebtMonthly => _t('automaticallyPayDebtMonthly');
  String get paymentAmount => _t('paymentAmount');
  String get payFromAccount => _t('payFromAccount');
  String get includeInNetWorth => _t('includeInNetWorth');
  String get countThisAccountInNetWorth => _t('countThisAccountInNetWorth');
  String get pleaseEnterAccountName => _t('pleaseEnterAccountName');
  String get deleteDebt => _t('deleteDebt');
  // Plan
  String get monthlyPlan => _t('monthlyPlan');
  String get totalPlanned => _t('totalPlanned');
  String get budgeting => _t('budgeting');
  String get addBillsDesc => _t('addBillsDesc');
  String get totalBudget => _t('totalBudget');
  // Coach
  String get newConversation => _t('newConversation');
  String get newChat => _t('newChat');
  String get projects => _t('projects');
  String get newProject => _t('newProject');
  String get noConversationsYet => _t('noConversationsYet');
  String get chats => _t('chats');
  String get addConversationsFromMenu => _t('addConversationsFromMenu');
  String get message => _t('message');
  String get renameProject => _t('renameProject');
  String get deleteProject => _t('deleteProject');
  String get projectName => _t('projectName');
  String get rename => _t('rename');
  String get archive => _t('archive');
  String get conversationName => _t('conversationName');
  String get deleteConversation => _t('deleteConversation');
  String get addToProject => _t('addToProject');
  String get monthlyOverview => _t('monthlyOverview');
  String get spendingAnalysis => _t('spendingAnalysis');
  String get analyzeReceipt => _t('analyzeReceipt');
  String get savingsTips => _t('savingsTips');
  String get goalProgress => _t('goalProgress');
  String get budgetPlan => _t('budgetPlan');
  String get betaAccessOnly => _t('betaAccessOnly');
  String get aiCoachComingSoon => _t('aiCoachComingSoon');
  String get attach => _t('attach');
  String get photo => _t('photo');
  String get camera => _t('camera');
  String get document => _t('document');

  // ── Settings ──────────────────────────────────────────────────────────────
  String get preferences => _t('preferences');
  String get privacyAndData => _t('privacyAndData');
  String get support => _t('support');
  String get on => _t('on');
  String get off => _t('off');
  String get locked => _t('locked');
  String get preview => _t('preview');

  // Appearance
  String get appearanceDetail => _t('appearanceDetail');
  String get appearanceSubtitle => _t('appearanceSubtitle');
  String get theme => _t('theme');
  String get themeFooter => _t('themeFooter');
  String get textSize => _t('textSize');
  String get textSizeFooter => _t('textSizeFooter');
  String get textSizeApply => _t('textSizeApply');
  String get textSizeApplied => _t('textSizeApplied');
  String get textSizeSmall => _t('textSizeSmall');
  String get textSizeCompact => _t('textSizeCompact');
  String get textSizeDefault => _t('textSizeDefault');
  String get textSizeLarge => _t('textSizeLarge');
  String get textSizeLarger => _t('textSizeLarger');
  String get textSizePreviewTitle => _t('textSizePreviewTitle');
  String get textSizePreviewSubtitle => _t('textSizePreviewSubtitle');
  String get display => _t('display');
  String get hideAmounts => _t('hideAmounts');
  String get hideAmountsDetail => _t('hideAmountsDetail');
  String get hideAmountsFooter => _t('hideAmountsFooter');

  // Language
  String get languageDetail => _t('languageDetail');
  String get languageSubtitle => _t('languageSubtitle');
  String get languageFooter => _t('languageFooter');

  // Currency & format
  String get currencyAndFormat => _t('currencyAndFormat');
  String get currencyAndFormatDetail => _t('currencyAndFormatDetail');
  String get currencyAndFormatSubtitle => _t('currencyAndFormatSubtitle');
  String get numberFormat => _t('numberFormat');
  String get numberFormatFooter => _t('numberFormatFooter');
  String get decimalsNone => _t('decimalsNone');
  String get decimalsTwo => _t('decimalsTwo');
  String get compactNumbers => _t('compactNumbers');
  String get compactNumbersDetail => _t('compactNumbersDetail');
  String get dateFormat => _t('dateFormat');
  String get firstDayOfWeek => _t('firstDayOfWeek');
  String get firstDayOfWeekFooter => _t('firstDayOfWeekFooter');
  String get saturday => _t('saturday');
  String get sunday => _t('sunday');
  String get monday => _t('monday');

  // Notifications
  String get notificationsDetail => _t('notificationsDetail');
  String get notificationsSubtitle => _t('notificationsSubtitle');
  String get pushNotificationsFooter => _t('pushNotificationsFooter');
  String get alerts => _t('alerts');
  String get billReminders => _t('billReminders');
  String get billRemindersDetail => _t('billRemindersDetail');
  String get budgetAlerts => _t('budgetAlerts');
  String get budgetAlertsDetail => _t('budgetAlertsDetail');
  String get largeTransactionAlerts => _t('largeTransactionAlerts');
  String get largeTransactionAlertsDetail => _t('largeTransactionAlertsDetail');
  String get alertThreshold => _t('alertThreshold');
  String get summaries => _t('summaries');
  String get dailySummary => _t('dailySummary');
  String get dailySummaryDetail => _t('dailySummaryDetail');
  String get weeklyReport => _t('weeklyReport');
  String get weeklyReportDetail => _t('weeklyReportDetail');
  String get quietHours => _t('quietHours');
  String get quietHoursFooter => _t('quietHoursFooter');
  String get from => _t('from');
  String get to => _t('to');

  // Security & privacy
  String get securityAndPrivacy => _t('securityAndPrivacy');
  String get securityAndPrivacyDetail => _t('securityAndPrivacyDetail');
  String get securityAndPrivacySubtitle => _t('securityAndPrivacySubtitle');
  String get appLock => _t('appLock');
  String get appLockDetail => _t('appLockDetail');
  String get appLockFooter => _t('appLockFooter');
  String get changePin => _t('changePin');
  String get autoLock => _t('autoLock');
  String get immediately => _t('immediately');
  String get afterOneMinute => _t('afterOneMinute');
  String afterNMinutes(int n) => _t('afterNMinutes').replaceAll('{n}', '$n');
  String get maskOnAppSwitch => _t('maskOnAppSwitch');
  String get maskOnAppSwitchDetail => _t('maskOnAppSwitchDetail');
  String get maskOnAppSwitchFooter => _t('maskOnAppSwitchFooter');
  String get changePasswordDetail => _t('changePasswordDetail');
  String get diagnostics => _t('diagnostics');
  String get diagnosticsFooter => _t('diagnosticsFooter');
  String get usageAnalytics => _t('usageAnalytics');
  String get usageAnalyticsDetail => _t('usageAnalyticsDetail');
  String get crashReports => _t('crashReports');
  String get crashReportsDetail => _t('crashReportsDetail');
  String get privacyPolicy => _t('privacyPolicy');
  String get pinUpdated => _t('pinUpdated');

  // PIN entry
  String get enterPin => _t('enterPin');
  String get setPin => _t('setPin');
  String get confirmPin => _t('confirmPin');
  String get pinHint => _t('pinHint');
  String get pinIncorrect => _t('pinIncorrect');
  String get pinMismatch => _t('pinMismatch');

  // Data & storage
  String get dataAndStorage => _t('dataAndStorage');
  String get dataAndStorageDetail => _t('dataAndStorageDetail');
  String get dataAndStorageSubtitle => _t('dataAndStorageSubtitle');
  String get sync => _t('sync');
  String get syncStatus => _t('syncStatus');
  String get syncedToCloud => _t('syncedToCloud');
  String get syncFooter => _t('syncFooter');
  String get syncLocalModeFooter => _t('syncLocalModeFooter');
  String get signedInAs => _t('signedInAs');
  String get exportData => _t('exportData');
  String get exportFooter => _t('exportFooter');
  String get exportAsJson => _t('exportAsJson');
  String get exportAsJsonDetail => _t('exportAsJsonDetail');
  String get copyToClipboard => _t('copyToClipboard');
  String get copyToClipboardDetail => _t('copyToClipboardDetail');
  String get exportSaved => _t('exportSaved');
  String get exportCancelled => _t('exportCancelled');
  String get exportUseClipboard => _t('exportUseClipboard');
  String get copiedToClipboard => _t('copiedToClipboard');
  String get storedOnThisDevice => _t('storedOnThisDevice');
  String get storageOverviewNote => _t('storageOverviewNote');
  String get dangerZone => _t('dangerZone');
  String get dangerZoneFooter => _t('dangerZoneFooter');
  String get clearLocalData => _t('clearLocalData');
  String get clearLocalDataDetail => _t('clearLocalDataDetail');
  String get clearLocalDataConfirm => _t('clearLocalDataConfirm');

  // Help & support
  String get helpAndSupportDetail => _t('helpAndSupportDetail');
  String get helpAndSupportSubtitle => _t('helpAndSupportSubtitle');
  String get frequentlyAsked => _t('frequentlyAsked');
  String get contact => _t('contact');
  String get contactFooter => _t('contactFooter');
  String get emailSupport => _t('emailSupport');
  String get emailCopied => _t('emailCopied');
  String get helpQ4 => _t('helpQ4');
  String get helpA4 => _t('helpA4');
  String get helpQ5 => _t('helpQ5');
  String get helpA5 => _t('helpA5');

  // About
  String get about => _t('about');
  String get aboutDetail => _t('aboutDetail');
  String get versionLabel => _t('versionLabel');
  String get openSourceLicenses => _t('openSourceLicenses');
  String get legal => _t('legal');
  String get termsOfService => _t('termsOfService');
  String get termsDesc => _t('termsDesc');
  String get copyDiagnostics => _t('copyDiagnostics');
  String get copyDiagnosticsDetail => _t('copyDiagnosticsDetail');
  String get madeWithCare => _t('madeWithCare');

  // ── Onboarding ──
  String get obWelcomeTo => _t('obWelcomeTo');
  String get obTagline => _t('obTagline');
  String get obPillPrivate => _t('obPillPrivate');
  String get obPillSmart => _t('obPillSmart');
  String get obPillFast => _t('obPillFast');
  String get obWelcomeFootnote => _t('obWelcomeFootnote');

  String get obLanguageTitle => _t('obLanguageTitle');
  String get obLanguageSubtitle => _t('obLanguageSubtitle');

  String get obHookTitle => _t('obHookTitle');
  String get obHookSubtitle => _t('obHookSubtitle');
  String get obHookPoint1 => _t('obHookPoint1');
  String get obHookPoint1Detail => _t('obHookPoint1Detail');
  String get obHookPoint2 => _t('obHookPoint2');
  String get obHookPoint2Detail => _t('obHookPoint2Detail');
  String get obHookPoint3 => _t('obHookPoint3');
  String get obHookPoint3Detail => _t('obHookPoint3Detail');
  String get obHookCta => _t('obHookCta');

  String get obAhaTitle => _t('obAhaTitle');
  String get obAhaSubtitle => _t('obAhaSubtitle');
  String get obAhaPoint1 => _t('obAhaPoint1');
  String get obAhaPoint1Detail => _t('obAhaPoint1Detail');
  String get obAhaPoint2 => _t('obAhaPoint2');
  String get obAhaPoint2Detail => _t('obAhaPoint2Detail');
  String get obAhaPoint3 => _t('obAhaPoint3');
  String get obAhaPoint3Detail => _t('obAhaPoint3Detail');
  String get obAhaPoint4 => _t('obAhaPoint4');
  String get obAhaPoint4Detail => _t('obAhaPoint4Detail');
  String get obAhaCta => _t('obAhaCta');

  String get obPreviewTitle => _t('obPreviewTitle');
  String get obPreviewSubtitle => _t('obPreviewSubtitle');
  String get obPreviewTodayDetail => _t('obPreviewTodayDetail');
  String get obPreviewPlanDetail => _t('obPreviewPlanDetail');
  String get obPreviewWealthDetail => _t('obPreviewWealthDetail');
  String get obPreviewAccountsDetail => _t('obPreviewAccountsDetail');
  String get obPreviewCoachDetail => _t('obPreviewCoachDetail');
  String get obPreviewCta => _t('obPreviewCta');

  String get obSetupSkip => _t('obSetupSkip');

  String get obCurrencyTitle => _t('obCurrencyTitle');
  String get obCurrencySubtitle => _t('obCurrencySubtitle');
  String get obCurrencySearch => _t('obCurrencySearch');
  String get obCurrencyCommon => _t('obCurrencyCommon');
  String get obCurrencyNoResults => _t('obCurrencyNoResults');

  String get obAccountTitle => _t('obAccountTitle');
  String get obAccountSubtitle => _t('obAccountSubtitle');
  String get obAccountNameLabel => _t('obAccountNameLabel');
  String get obAccountNameHint => _t('obAccountNameHint');
  String get obBankLabel => _t('obBankLabel');
  String get obBankHint => _t('obBankHint');
  String get obLogoAdd => _t('obLogoAdd');
  String get obLogoHint => _t('obLogoHint');

  String get obBalanceTitle => _t('obBalanceTitle');
  String get obBalanceSubtitle => _t('obBalanceSubtitle');
  String get obBalanceLabel => _t('obBalanceLabel');

  String get obIncomeTitle => _t('obIncomeTitle');
  String get obIncomeSubtitle => _t('obIncomeSubtitle');
  String get obWageLabel => _t('obWageLabel');
  String get obWageHint => _t('obWageHint');
  String get obFrequencyLabel => _t('obFrequencyLabel');
  String get obPayWeekly => _t('obPayWeekly');
  String get obPayBiweekly => _t('obPayBiweekly');
  String get obPayMonthly => _t('obPayMonthly');
  String get obPayDayLabel => _t('obPayDayLabel');
  String obPayDayOfMonth(int day) =>
      _t('obPayDayOfMonth').replaceAll('{day}', '$day');
  String get obPayDayLastDay => _t('obPayDayLastDay');
  String obPayEveryWeekday(String day) =>
      _t('obPayEveryWeekday').replaceAll('{day}', day);
  String obMonthlyEquivalent(String amount) =>
      _t('obMonthlyEquivalent').replaceAll('{amount}', amount);
  String obNextPayday(String day) =>
      _t('obNextPayday').replaceAll('{day}', day);
  String get obIncomeSkip => _t('obIncomeSkip');
  String get obIncomeSkipNote => _t('obIncomeSkipNote');

  String get obSummaryTitle => _t('obSummaryTitle');
  String get obSummarySubtitle => _t('obSummarySubtitle');
  String get obSummaryAccount => _t('obSummaryAccount');
  String get obSummaryBalance => _t('obSummaryBalance');
  String get obSummaryIncome => _t('obSummaryIncome');
  String get obSummaryIncomeNone => _t('obSummaryIncomeNone');
  String get obSummaryEdit => _t('obSummaryEdit');
  String get obFinish => _t('obFinish');

  String get obErrorNameRequired => _t('obErrorNameRequired');
  String get obErrorBalanceRequired => _t('obErrorBalanceRequired');
  String get obErrorNotANumber => _t('obErrorNotANumber');
  String get obErrorNegativeBalance => _t('obErrorNegativeBalance');
  String get obErrorWagePositive => _t('obErrorWagePositive');
  String get incomeSettings => _t('incomeSettings');
  String get incomeSettingsDetail => _t('incomeSettingsDetail');
  String get incomeSettingsSubtitle => _t('incomeSettingsSubtitle');
  String get incomePaidInto => _t('incomePaidInto');
  String get incomeNoSalary => _t('incomeNoSalary');
  String get incomeNoSalaryDetail => _t('incomeNoSalaryDetail');
  String get incomeAddSalary => _t('incomeAddSalary');
  String get incomeRemove => _t('incomeRemove');
  String get incomeRemoveConfirm => _t('incomeRemoveConfirm');
  String get incomeRemoveMessage => _t('incomeRemoveMessage');
  String get incomeSaved => _t('incomeSaved');
  String get incomeRemoved => _t('incomeRemoved');
  String get incomeTotalMonthly => _t('incomeTotalMonthly');
  String get incomeAccountHint => _t('incomeAccountHint');
}
