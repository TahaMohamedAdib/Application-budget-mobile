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
}
