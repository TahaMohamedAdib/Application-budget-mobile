import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import 'accounts_screen.dart';
import 'cash_on_hand_screen.dart';
import 'debt_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import 'spending_screen.dart';
import 'transactions_screen.dart';
import 'all_subscriptions_screen.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/app_picker_field.dart';
import '../l10n/app_localizations.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _activeFilter = 'all';

  void resetToAll() {
    setState(() => _activeFilter = 'all');
  }

  bool _balanceVisible = true;
  String _selectedTimeframe = '1m';

  // Transactions inline filter state
  final _txSearchController = TextEditingController();
  String _txFilterType = 'all';
  String _txSortBy = 'newest';
  bool _txShowFilters = false;

  @override
  void dispose() {
    _txSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.localDataLoaded) {
          return _buildSkeletonHome(context, isDark);
        }

        final totalCash = provider.totalCash;
        final currencyFormat =
            CurrencyHelper.formatter(provider.settings.currency);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAccountPicker(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : AppTheme.lightBorder,
                              ),
                              boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeaderAccountIcon(provider),
                                const SizedBox(width: 8),
                                Text(
                                  _getSelectedAccountName(provider),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Iconify(AppIcons.caretUpDown,
                                    size: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _headerIcon(AppIcons.settings, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()));
                        }),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),
                ),

                // Filter pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterPill(s.all, 'all'),
                          const SizedBox(width: 10),
                          _buildFilterPill(s.accounts, 'accounts'),
                          const SizedBox(width: 10),
                          _buildFilterPill(s.transactions, 'transactions'),
                          const SizedBox(width: 10),
                          _buildFilterPill(s.savingsGoals, 'goals'),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 60.ms, curve: Curves.easeOut),
                ),

                // ── Account Balance Card ──
                if (_activeFilter == 'all' || _activeFilter == 'accounts')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.goldCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.totalBalance,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(
                              _balanceVisible
                                  ? currencyFormat
                                      .format(_getAccountBalance(provider))
                                  : '••••••',
                              style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.selectedAccountId == null
                                  ? s.accountsCombined
                                  : _getSelectedAccountName(provider),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 280.ms,
                            delay: 100.ms,
                            curve: Curves.easeOut)
                        .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                  ),

                // ── Balance Evolution Graph (All tab only) ──
                if (_activeFilter == 'all')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.goldCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header: title + balance left, time pills right ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.balanceEvolution,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormat.format(
                                            _getAccountBalance(provider)),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                      ['1d', '1w', '1m', '6m', '1y'].map((tf) {
                                    final isActive = _selectedTimeframe == tf;
                                    return GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedTimeframe = tf),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppTheme.goldPrimary
                                              : Colors.white.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tf.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? Colors.white
                                                : Colors.white60,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            RepaintBoundary(
                              child: SizedBox(
                                height: 200,
                                child: _buildBalanceChart(provider, isDark, s),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 280.ms,
                            delay: 140.ms,
                            curve: Curves.easeOut)
                        .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                  ),

                // ── Accounts Section (Accounts tab only) ──
                if (_activeFilter == 'accounts')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.accounts,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AccountsScreen())),
                                child: Text(s.seeAll,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.goldPrimary,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...provider.accounts.map((account) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildAccountRow(
                                  context: context,
                                  icon: _iconForAccountType(account.type),
                                  iconColor: _colorFromHex(account.color),
                                  label: account.name,
                                  sublabel: account.bankName ??
                                      account.type[0].toUpperCase() +
                                          account.type.substring(1),
                                  amount: account.balance,
                                  cf: currencyFormat,
                                  imagePath: account.imagePath,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AccountsScreen())),
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAccountRow(
                              context: context,
                              icon: AppIcons.money,
                              iconColor: AppTheme.warning,
                              label: s.cashOnHand,
                              sublabel: 'From withdrawals',
                              amount: totalCash,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CashOnHandScreen())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAccountRow(
                              context: context,
                              icon: AppIcons.trendUp,
                              iconColor: const Color(0xFF8B5CF6),
                              label: s.investments,
                              sublabel: '${provider.holdings.length} holdings',
                              amount: provider.totalInvestmentValue,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const PortfolioScreen())),
                            ),
                          ),
                          if (provider.totalDebtRemaining > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildAccountRow(
                                context: context,
                                icon: AppIcons.creditCard,
                                iconColor: AppTheme.error,
                                label: s.debt,
                                sublabel:
                                    '${provider.goals.where((g) => g.type == "debt").length} items',
                                amount: -provider.totalDebtRemaining,
                                cf: currencyFormat,
                                isNegative: true,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const DebtScreen())),
                              ),
                            ),
                          // Add Account button
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => AddAccountModal(
                                    onSave: (account) {
                                      provider.addAccount(account);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppTheme.goldPrimary.withOpacity(0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Iconify(AppIcons.add,
                                        color: AppTheme.goldPrimary, size: 28),
                                    const SizedBox(width: 14),
                                    Text(s.addAccount,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.goldPrimary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 300.ms,
                            delay: 180.ms,
                            curve: Curves.easeOut)
                        .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                  ),

                // ── Upcoming Subscriptions (All tab) ──
                if (_activeFilter == 'all')
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        final _now = DateTime.now();
                        final activeRules = provider.recurringRules
                            .where((r) =>
                                r.isActive &&
                                DateTime.parse(r.nextDate).isAfter(_now))
                            .toList()
                          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
                        final upcoming = activeRules.take(3).toList();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(s.upcomingSubscriptions,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AllSubscriptionsScreen())),
                                    child: Text(s.seeAll,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.goldPrimary,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: AppTheme.premiumCard(context),
                                child: upcoming.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Center(
                                            child: Text(s.noSubscriptionsYet,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall)),
                                      )
                                    : Column(
                                        children: upcoming
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final rule = entry.value;
                                          final isLast =
                                              entry.key == upcoming.length - 1;
                                          return Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 14),
                                                child: Row(
                                                  children: [
                                                    Builder(builder: (_) {
                                                      final cat = rule
                                                                  .templateTransaction
                                                                  .categoryId !=
                                                              null
                                                          ? provider.categories
                                                              .where((c) =>
                                                                  c.id ==
                                                                  rule.templateTransaction
                                                                      .categoryId)
                                                              .firstOrNull
                                                          : null;
                                                      final acct = provider
                                                          .accounts
                                                          .where((a) =>
                                                              a.id ==
                                                              rule.templateTransaction
                                                                  .accountId)
                                                          .firstOrNull;
                                                      final imgPath = (cat !=
                                                                  null &&
                                                              cat.icon
                                                                  .startsWith(
                                                                      'img:'))
                                                          ? cat.icon
                                                              .substring(4)
                                                          : acct?.imagePath;
                                                      return Container(
                                                        width: 44,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                            color: AppTheme
                                                                .goldPrimary
                                                                .withOpacity(
                                                                    0.12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14)),
                                                        child: imgPath != null
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            14),
                                                                child: imgPath
                                                                        .startsWith(
                                                                            'http')
                                                                    ? Image.network(
                                                                        imgPath,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder: (_, __, ___) => const Iconify(
                                                                            AppIcons
                                                                                .autoRenew,
                                                                            color: AppTheme
                                                                                .goldPrimary,
                                                                            size:
                                                                                20))
                                                                    : Image.file(
                                                                        File(imgPath),
                                                                        fit: BoxFit.cover,
                                                                        errorBuilder: (_, __, ___) => const Iconify(AppIcons.autoRenew, color: AppTheme.goldPrimary, size: 20)),
                                                              )
                                                            : cat != null
                                                                ? Iconify(
                                                                    _subCategoryIcon(cat
                                                                        .icon),
                                                                    color: AppTheme
                                                                        .goldPrimary,
                                                                    size: 20)
                                                                : const Iconify(
                                                                    AppIcons
                                                                        .autoRenew,
                                                                    color: AppTheme
                                                                        .goldPrimary,
                                                                    size: 20),
                                                      );
                                                    }),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              rule.templateTransaction
                                                                      .note ??
                                                                  'Subscription',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600)),
                                                          const SizedBox(
                                                              height: 2),
                                                          Builder(
                                                              builder: (ctx) {
                                                            final nd = DateTime
                                                                .parse(rule
                                                                    .nextDate);
                                                            final today =
                                                                DateTime.now();
                                                            final isToday = nd
                                                                        .year ==
                                                                    today
                                                                        .year &&
                                                                nd.month ==
                                                                    today
                                                                        .month &&
                                                                nd.day ==
                                                                    today.day;
                                                            return Text(
                                                              isToday
                                                                  ? 'Today · ${DateFormat('h:mm a').format(nd)}'
                                                                  : 'Due ${DateFormat('MMM d').format(nd)}',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                        currencyFormat.format(rule
                                                            .templateTransaction
                                                            .amount),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                  ],
                                                ),
                                              ),
                                              if (!isLast)
                                                Divider(
                                                    height: 1,
                                                    indent: 76,
                                                    color: Theme.of(context)
                                                        .dividerColor),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                duration: 300.ms,
                                delay: 200.ms,
                                curve: Curves.easeOut)
                            .slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
                      },
                    ),
                  ),

                // ── Search & Filters (Transactions tab only) ──
                if (_activeFilter == 'transactions')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _txSearchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: s.search + ' transactions...',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 14, right: 8),
                                      child: Iconify(AppIcons.search,
                                          size: 16,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                        minWidth: 38, minHeight: 38),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppTheme.darkSurface
                                        : AppTheme.lightSurface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _txShowFilters = !_txShowFilters),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Iconify(
                                    AppIcons.sliders,
                                    size: 24,
                                    color: _txShowFilters
                                        ? AppTheme.goldPrimary
                                        : Theme.of(context).iconTheme.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_txShowFilters) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTxDropdown(
                                    s.type,
                                    _txFilterType,
                                    {
                                      'all': s.all,
                                      'expense': s.expenses,
                                      'income': s.incomeLabel,
                                      'transfer': s.transfer,
                                      'withdrawal': s.withdrawal
                                    },
                                    (v) => setState(() => _txFilterType = v),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTxDropdown(
                                    s.sort,
                                    _txSortBy,
                                    {
                                      'newest': s.sortNewest,
                                      'oldest': s.sortOldest,
                                      'highest': s.sortHighest,
                                      'lowest': s.sortLowest
                                    },
                                    (v) => setState(() => _txSortBy = v),
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOut),
                  ),

                // ── Recent Transactions / All Transactions ──
                if (_activeFilter == 'all' || _activeFilter == 'transactions')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20,
                          _activeFilter == 'transactions' ? 16 : 28, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeFilter == 'transactions'
                                ? s.transactions
                                : s.recentTransactions,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (_activeFilter == 'all')
                            GestureDetector(
                              onTap: () => setState(
                                  () => _activeFilter = 'transactions'),
                              child: Text(s.seeAll,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.goldPrimary,
                                      fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(
                        duration: 300.ms, delay: 220.ms, curve: Curves.easeOut),
                  ),

                if (_activeFilter == 'all' || _activeFilter == 'transactions')
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: (() {
                      final txList = _activeFilter == 'transactions'
                          ? _getFilteredTransactions(provider)
                          : provider.transactions.reversed.take(3).toList();
                      return txList.isEmpty
                          ? SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: AppTheme.premiumCard(context),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppTheme.darkSurfaceElevated
                                            : AppTheme.lightBackground,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Iconify(AppIcons.receipt,
                                          size: 32,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.5)),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _activeFilter == 'transactions' &&
                                              (_txSearchController
                                                      .text.isNotEmpty ||
                                                  _txFilterType != 'all')
                                          ? s.noTransactionsFound
                                          : s.noTransactions,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _activeFilter == 'transactions' &&
                                              (_txSearchController
                                                      .text.isNotEmpty ||
                                                  _txFilterType != 'all')
                                          ? s.tryAdjustingFilters
                                          : s.tapToAddFirstTransaction,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(
                                  duration: 300.ms,
                                  delay: 240.ms,
                                  curve: Curves.easeOut),
                            )
                          : SliverToBoxAdapter(
                              child: _buildGroupedTransactions(
                                txList,
                                currencyFormat,
                                context,
                                isDark,
                                provider: provider,
                              ).animate().fadeIn(
                                  duration: 300.ms,
                                  delay: 240.ms,
                                  curve: Curves.easeOut),
                            );
                    })(),
                  ),

                // ── Goals Tab ──
                if (_activeFilter == 'goals')
                  SliverToBoxAdapter(
                    child: _buildGoalsTabContent(
                            context, provider, currencyFormat, isDark, s)
                        .animate()
                        .fadeIn(duration: 280.ms, curve: Curves.easeOut),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Goals tab full content ──
  Widget _buildGoalsTabContent(BuildContext context, AppProvider provider,
      NumberFormat cf, bool isDark, S s) {
    final goals = provider.goals
        .where(
            (g) => g.type == 'savings' || g.type == 'custom' || g.type == null)
        .toList();
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          if (goals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.premiumCard(context),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.savings_rounded,
                            color: AppTheme.goldPrimary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Saved',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(cf.format(totalSaved),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Target',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(cf.format(totalTarget),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  if (totalTarget > 0) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (totalSaved / totalTarget).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.goldPrimary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${((totalSaved / totalTarget) * 100).toStringAsFixed(1)}% of total goals',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s.savingsGoals} (${goals.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              GestureDetector(
                onTap: () => _showAddSavingsGoalForm(context, provider),
                child: Text(s.add,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.goldPrimary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state
          if (goals.isEmpty)
            GestureDetector(
              onTap: () => _showAddSavingsGoalForm(context, provider),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppTheme.goldPrimary.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.flag_outlined,
                        color: AppTheme.goldPrimary.withOpacity(0.5), size: 40),
                    const SizedBox(height: 12),
                    Text('No savings goals yet',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Tap + to create your first goal',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            // Goal cards list
            ...goals.asMap().entries.map((entry) {
              final goal = entry.value;
              final progress = goal.targetAmount > 0
                  ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.premiumCard(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildGoalMiniIcon(goal, isDark),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(goal.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: progress >= 1.0
                                              ? AppTheme.success
                                              : AppTheme.goldPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${cf.format(goal.currentAmount)} / ${cf.format(goal.targetAmount)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (goal.monthlyPayment != null &&
                                        goal.monthlyPayment! > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.info.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${cf.format(goal.monthlyPayment!)}/mo',
                                          style: const TextStyle(
                                            color: AppTheme.info,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? Colors.white12
                                        : Colors.black.withOpacity(0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 1.0
                                            ? AppTheme.success
                                            : AppTheme.goldPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildHomeGoalActionButton(
                              icon: Icons.add_rounded,
                              label: 'Add Savings',
                              backgroundColor: AppTheme.goldPrimary,
                              foregroundColor: Colors.white,
                              onTap: () => _showGoalContributionModal(
                                  context, provider, goal, cf),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHomeGoalActionButton(
                              icon: Icons.edit_rounded,
                              label: 'Modify',
                              backgroundColor:
                                  AppTheme.goldPrimary.withOpacity(0.12),
                              foregroundColor: AppTheme.goldPrimary,
                              borderColor:
                                  AppTheme.goldPrimary.withOpacity(0.25),
                              onTap: () => _showAddSavingsGoalForm(
                                  context, provider,
                                  existingGoal: goal),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: Text(s.deleteGoal),
                                      content: Text(
                                          '${s.delete} "${goal.name}"? ${s.cannotBeUndone}'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, false),
                                          child: Text(s.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, true),
                                          style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.error),
                                          child: Text(s.delete),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                              if (confirmed) {
                                provider.deleteGoal(goal.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: AppTheme.error,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddSavingsGoalForm(BuildContext context, AppProvider provider,
      {Goal? existingGoal}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final isEditing = existingGoal != null;
    final nameCtrl = TextEditingController(text: existingGoal?.name ?? '');
    final descCtrl =
        TextEditingController(text: existingGoal?.description ?? '');
    final targetCtrl = TextEditingController(
        text: existingGoal?.targetAmount.toStringAsFixed(2) ?? '');
    final savedCtrl = TextEditingController(
        text: existingGoal?.currentAmount.toStringAsFixed(2) ?? '0.00');
    final monthlyCtrl = TextEditingController(
        text: existingGoal?.monthlyPayment?.toStringAsFixed(2) ?? '');
    DateTime? dueDate = existingGoal?.targetDate != null
        ? DateTime.tryParse(existingGoal!.targetDate!)
        : null;
    bool hasMonthly = existingGoal?.monthlyPayment != null &&
        existingGoal!.monthlyPayment! > 0;
    int paymentDay = existingGoal?.paymentDay ?? 1;
    String? paymentSourceAccountId =
        existingGoal?.paymentSourceAccountId ?? AppProvider.cashOnHandId;
    String selectedEmoji = '🎯';
    if (existingGoal != null) {
      selectedEmoji = existingGoal.icon;
    }
    final emojiOptions = [
      '🎯',
      '🏠',
      '🚗',
      '✈️',
      '💍',
      '🎓',
      '💻',
      '📱',
      '🏖️',
      '💰'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isEditing
                                ? 'Edit Savings Goal'
                                : 'New Savings Goal',
                            style: Theme.of(ctx)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        Text('Icon',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: emojiOptions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final emoji = emojiOptions[i];
                              final isSelected = selectedEmoji == emoji;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedEmoji = emoji),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.goldPrimary.withOpacity(0.15)
                                        : (isDark
                                            ? AppTheme.darkSurfaceElevated
                                            : const Color(0xFFF5F5F5)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppTheme.goldPrimary,
                                            width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                      child: Text(emoji,
                                          style:
                                              const TextStyle(fontSize: 28))),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Goal Name',
                            hintText: 'e.g., New Car, Vacation',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            hintText: 'What are you saving for?',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: targetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Target Amount',
                            prefixText:
                                '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: savedCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Already Saved',
                            prefixText:
                                '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: dueDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setModalState(() => dueDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Theme.of(ctx).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 20,
                                    color: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dueDate != null
                                        ? DateFormat('MMMM d, yyyy')
                                            .format(dueDate!)
                                        : 'Set Due Date (optional)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: dueDate != null
                                          ? null
                                          : Theme.of(ctx)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                    ),
                                  ),
                                ),
                                if (dueDate != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setModalState(() => dueDate = null),
                                    child: Icon(Icons.close_rounded,
                                        size: 18,
                                        color: Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.color),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasMonthly
                                  ? AppTheme.info.withOpacity(0.4)
                                  : Theme.of(ctx).dividerColor,
                            ),
                            color: hasMonthly
                                ? AppTheme.info.withOpacity(0.04)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.autorenew_rounded,
                                    size: 18,
                                    color: hasMonthly
                                        ? AppTheme.info
                                        : Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Monthly Auto-Save',
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: hasMonthly,
                                    onChanged: (v) =>
                                        setModalState(() => hasMonthly = v),
                                    activeColor: AppTheme.info,
                                    activeTrackColor:
                                        AppTheme.info.withOpacity(0.3),
                                  ),
                                ],
                              ),
                              if (hasMonthly) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: monthlyCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Monthly Amount',
                                    prefixText:
                                        '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppPickerField<int>(
                                  label: 'Day of Month',
                                  value: paymentDay,
                                  prefixIcon: AppIcons.calendar,
                                  items: List.generate(
                                    28,
                                    (i) => AppPickerItem(
                                      value: i + 1,
                                      label: 'Day ${i + 1}',
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setModalState(() => paymentDay = v ?? 1),
                                ),
                                const SizedBox(height: 12),
                                AppPickerField<String>(
                                  label: 'From Account',
                                  value: paymentSourceAccountId,
                                  prefixIcon: AppIcons.wallet,
                                  items: [
                                    const AppPickerItem(
                                      value: AppProvider.cashOnHandId,
                                      label: 'Cash on Hand',
                                      leadingIcon: AppIcons.money,
                                      iconColor: AppTheme.goldPrimary,
                                    ),
                                    ...provider.accounts.map(
                                      (a) => AppPickerItem(
                                        value: a.id,
                                        label: a.name,
                                        subtitle: cf.format(a.balance),
                                        leadingIcon: AppIcons.bank,
                                        iconColor: const Color(0xFF3B82F6),
                                        imagePath: a.imagePath,
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setModalState(
                                      () => paymentSourceAccountId = v),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter a goal name')));
                                return;
                              }
                              final target =
                                  double.tryParse(targetCtrl.text) ?? 0;
                              if (target <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid target amount')));
                                return;
                              }
                              final saved =
                                  (double.tryParse(savedCtrl.text) ?? 0)
                                      .clamp(0, target)
                                      .toDouble();
                              final monthly = hasMonthly
                                  ? double.tryParse(monthlyCtrl.text)
                                  : null;
                              if (hasMonthly &&
                                  (monthly == null || monthly <= 0)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid monthly amount')));
                                return;
                              }

                              final goal = Goal(
                                id: existingGoal?.id ?? const Uuid().v4(),
                                type: 'savings',
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                targetAmount: target,
                                currentAmount: saved,
                                targetDate: dueDate?.toIso8601String(),
                                icon: selectedEmoji,
                                imagePath: existingGoal?.imagePath,
                                monthlyPayment: monthly,
                                paymentDay: hasMonthly ? paymentDay : null,
                                paymentSourceAccountId:
                                    hasMonthly ? paymentSourceAccountId : null,
                              );
                              if (isEditing) {
                                provider.updateGoal(goal);
                              } else {
                                provider.addGoal(goal);
                              }
                              _syncSavingsGoalRule(provider, goal);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Goal updated'
                                      : 'Goal created'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.goldPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                                isEditing ? 'Save Changes' : 'Create Goal',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      descCtrl.dispose();
      targetCtrl.dispose();
      savedCtrl.dispose();
      monthlyCtrl.dispose();
    });
  }

  Widget _buildHomeGoalActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor == null ? null : Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalContributionModal(
      BuildContext context, AppProvider provider, Goal goal, NumberFormat cf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountCtrl = TextEditingController();
    String? selectedAccountId = AppProvider.cashOnHandId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).dividerColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildGoalMiniIcon(goal, isDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Savings',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(goal.name,
                                  style: Theme.of(ctx).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText:
                            '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPickerField<String>(
                      label: 'From Account',
                      value: selectedAccountId,
                      prefixIcon: AppIcons.wallet,
                      items: [
                        const AppPickerItem(
                          value: AppProvider.cashOnHandId,
                          label: 'Cash on Hand',
                          subtitle: 'Cash',
                          leadingIcon: AppIcons.money,
                          iconColor: AppTheme.goldPrimary,
                        ),
                        ...provider.accounts.map(
                          (a) => AppPickerItem(
                            value: a.id,
                            label: a.name,
                            subtitle: cf.format(a.balance),
                            leadingIcon: AppIcons.bank,
                            iconColor: const Color(0xFF3B82F6),
                            imagePath: a.imagePath,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setModalState(() => selectedAccountId = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter a valid amount')));
                            return;
                          }
                          provider.contributeToGoalFromSource(goal.id, amount,
                              selectedAccountId ?? AppProvider.cashOnHandId);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added ${cf.format(amount)} to ${goal.name}'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Add Savings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(amountCtrl.dispose);
  }

  void _syncSavingsGoalRule(AppProvider provider, Goal goal) {
    final ruleId = 'savingsgoal_${goal.id}';
    final existingIdx =
        provider.recurringRules.indexWhere((r) => r.id == ruleId);

    if (goal.monthlyPayment == null ||
        goal.monthlyPayment! <= 0 ||
        goal.paymentSourceAccountId == null) {
      if (existingIdx != -1) {
        provider.deleteRecurringRule(ruleId);
      }
      return;
    }

    final now = DateTime.now();
    final day = goal.paymentDay ?? 1;
    var nextDate = DateTime(now.year, now.month, day);
    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(now.year, now.month + 1, day);
    }

    final rule = RecurringRule(
      id: ruleId,
      frequency: 'monthly',
      nextDate: nextDate.toIso8601String(),
      isActive: true,
      templateTransaction: Transaction(
        id: '${ruleId}_template',
        type: 'goal_contribution',
        amount: goal.monthlyPayment!,
        date: nextDate.toIso8601String(),
        note: 'Auto-save: ${goal.name}',
        accountId: goal.paymentSourceAccountId!,
        categoryId: goal.id,
        isRecurring: true,
        expenseSubType: 'subscription',
      ),
    );

    if (existingIdx != -1) {
      final existing = provider.recurringRules[existingIdx];
      provider.updateRecurringRule(rule.copyWith(nextDate: existing.nextDate));
    } else {
      provider.addRecurringRule(rule);
    }
  }

  Widget _buildGoalMiniIcon(Goal goal, bool isDark) {
    if (goal.imagePath != null && (goal.imagePath as String).isNotEmpty) {
      final path = goal.imagePath as String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: path.startsWith('http')
            ? Image.network(path,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _goalEmojiIcon(goal.icon, isDark))
            : Image.file(File(path),
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _goalEmojiIcon(goal.icon, isDark)),
      );
    }
    return _goalEmojiIcon(goal.icon, isDark);
  }

  Widget _goalEmojiIcon(String emoji, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.goldPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }

  // ── Balance Chart ──
  Widget _buildBalanceChart(AppProvider provider, bool isDark, S s) {
    final spots = _computeBalanceSpots(provider);
    if (spots.isEmpty || spots.length < 2) {
      return Center(
          child: Text(s.notEnoughData,
              style: const TextStyle(color: Colors.white54, fontSize: 13)));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 100.0 : range * 0.20;

    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final now = DateTime.now();
    late DateTime chartStart;
    switch (_selectedTimeframe) {
      case '1d':
        chartStart = now.subtract(const Duration(hours: 24));
        break;
      case '1w':
        chartStart = now.subtract(const Duration(days: 7));
        break;
      case '1m':
        chartStart = now.subtract(const Duration(days: 30));
        break;
      case '6m':
        chartStart = now.subtract(const Duration(days: 180));
        break;
      case '1y':
        chartStart = now.subtract(const Duration(days: 365));
        break;
      default:
        chartStart = now.subtract(const Duration(days: 30));
    }
    final numPoints = spots.length;
    final totalDuration = now.difference(chartStart);
    final intervalMs =
        numPoints > 1 ? totalDuration.inMilliseconds / (numPoints - 1) : 1.0;

    String formatYLabel(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    // X-style: green if trending up, red if trending down
    final isPositive = spots.last.y >= spots.first.y;
    final lineColor = isPositive
        ? const Color(0xFF4ADE80) // green
        : const Color(0xFFFF6B6B); // red

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (numPoints - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 100 : range / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.07),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: range == 0 ? 100 : range / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(formatYLabel(value),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white54)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _selectedTimeframe == '1d'
                  ? 6
                  : (_selectedTimeframe == '1w'
                      ? 2
                      : (_selectedTimeframe == '1m'
                          ? 7
                          : (_selectedTimeframe == '6m' ? 6 : 3))),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= numPoints) return const SizedBox.shrink();
                final pointTime = chartStart
                    .add(Duration(milliseconds: (intervalMs * idx).round()));
                String label;
                if (_selectedTimeframe == '1d') {
                  label = DateFormat('HH:mm').format(pointTime);
                } else if (_selectedTimeframe == '1w' ||
                    _selectedTimeframe == '1m') {
                  label = DateFormat('d MMM').format(pointTime);
                } else {
                  label = DateFormat('MMM').format(pointTime);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style:
                          const TextStyle(fontSize: 9, color: Colors.white54)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) =>
              spotIndexes.map((i) {
            return TouchedSpotIndicatorData(
              FlLine(
                  color: lineColor.withOpacity(0.6),
                  strokeWidth: 1.5,
                  dashArray: [4, 4]),
              FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 5,
                  color: lineColor,
                  strokeWidth: 2.5,
                  strokeColor: lineColor.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1C1C1E),
            tooltipRoundedRadius: 10,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      cf.format(s.y),
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.38,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: lineColor,
                strokeWidth: 2,
                strokeColor: Colors.white.withOpacity(0.8),
              ),
            ),
            shadow: Shadow(color: lineColor.withOpacity(0.35), blurRadius: 10),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 1.0],
                colors: [
                  lineColor.withOpacity(0.18),
                  lineColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _computeBalanceSpots(AppProvider provider) {
    final now = DateTime.now();
    late DateTime start;
    late int numPoints;

    switch (_selectedTimeframe) {
      case '1d':
        start = now.subtract(const Duration(hours: 24));
        numPoints = 24;
        break;
      case '1w':
        start = now.subtract(const Duration(days: 7));
        numPoints = 7;
        break;
      case '1m':
        start = now.subtract(const Duration(days: 30));
        numPoints = 30;
        break;
      case '6m':
        start = now.subtract(const Duration(days: 180));
        numPoints = 26;
        break;
      case '1y':
        start = now.subtract(const Duration(days: 365));
        numPoints = 12;
        break;
      default:
        start = now.subtract(const Duration(days: 30));
        numPoints = 30;
    }

    // Get relevant transactions for selected account
    final txns = provider.transactions.where((t) {
      if (provider.selectedAccountId != null &&
          t.accountId != provider.selectedAccountId) return false;
      final d = DateTime.parse(t.date);
      return d.isAfter(start.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Current balance
    double currentBalance = _getAccountBalance(provider);

    // Walk backwards: compute balance at start by reversing all transactions
    double balanceAtStart = currentBalance;
    for (final t in txns.reversed) {
      if (t.type == 'income') {
        balanceAtStart -= t.amount;
      } else if (t.type == 'expense' || t.type == 'withdrawal') {
        balanceAtStart += t.amount;
      } else if (t.type == 'transfer') {
        if (t.accountId == provider.selectedAccountId) {
          balanceAtStart += t.amount;
        } else if (t.toAccountId == provider.selectedAccountId) {
          balanceAtStart -= t.amount;
        }
      }
    }

    // Build spots by walking forward
    final totalDuration = now.difference(start);
    final intervalMs = totalDuration.inMilliseconds / (numPoints - 1);
    double runningBalance = balanceAtStart;
    int txnIdx = 0;
    final spots = <FlSpot>[];

    for (int i = 0; i < numPoints; i++) {
      final pointTime =
          start.add(Duration(milliseconds: (intervalMs * i).round()));
      // Apply all transactions up to this point
      while (txnIdx < txns.length &&
          DateTime.parse(txns[txnIdx].date)
              .isBefore(pointTime.add(const Duration(seconds: 1)))) {
        final t = txns[txnIdx];
        if (t.type == 'income') {
          runningBalance += t.amount;
        } else if (t.type == 'expense' || t.type == 'withdrawal') {
          runningBalance -= t.amount;
        } else if (t.type == 'transfer') {
          if (t.accountId == provider.selectedAccountId) {
            runningBalance -= t.amount;
          } else if (t.toAccountId == provider.selectedAccountId) {
            runningBalance += t.amount;
          }
        }
        txnIdx++;
      }
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }

    return spots;
  }

  Widget _headerIcon(String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Iconify(
          icon,
          size: 24,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  double _getAccountBalance(AppProvider provider) {
    if (provider.selectedAccountId == null) {
      return provider.accounts.fold(0.0, (sum, a) => sum + a.balance);
    }
    final account =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    return account.isNotEmpty ? account.first.balance : 0.0;
  }

  String _subCategoryIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return AppIcons.home;
      case 'flash':
        return AppIcons.lightning;
      case 'phone':
        return AppIcons.phone;
      case 'tv':
        return AppIcons.tv;
      case 'shield':
        return AppIcons.shield;
      case 'credit_card':
        return AppIcons.creditCard;
      case 'shopping_cart':
        return AppIcons.cart;
      case 'car':
        return AppIcons.car;
      case 'restaurant':
        return AppIcons.food;
      case 'shopping_bag':
        return AppIcons.shoppingBag;
      case 'favorite':
        return AppIcons.heart;
      case 'sports_esports':
        return AppIcons.gaming;
      case 'face':
        return AppIcons.personal;
      case 'school':
        return AppIcons.education;
      case 'flight':
        return AppIcons.travel;
      case 'card_giftcard':
        return AppIcons.gift;
      case 'pets':
        return AppIcons.pets;
      case 'fitness_center':
        return AppIcons.gym;
      case 'local_cafe':
        return AppIcons.coffee;
      case 'child_care':
        return AppIcons.baby;
      case 'build':
        return AppIcons.tools;
      default:
        return AppIcons.autoRenew;
    }
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.goldPrimary;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.goldPrimary;
    }
  }

  String _iconForAccountType(String type) {
    switch (type) {
      case 'bank':
        return AppIcons.bank;
      case 'savings':
        return AppIcons.savings;
      case 'investment':
        return AppIcons.trendUp;
      case 'debt':
        return AppIcons.creditCard;
      default:
        return AppIcons.wallet;
    }
  }

  Widget _buildAccountRow({
    required BuildContext context,
    required String icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required double amount,
    required NumberFormat cf,
    required VoidCallback onTap,
    bool isNegative = false,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard(context),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: imagePath.startsWith('http')
                            ? Image.network(imagePath,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Iconify(icon, color: iconColor, size: 28))
                            : Image.file(File(imagePath),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Iconify(icon, color: iconColor, size: 28)),
                      )
                    : Iconify(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _balanceVisible ? cf.format(amount) : '••••••',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isNegative
                      ? AppTheme.error
                      : Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isActive = _activeFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.goldPrimary
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: isDark && !isActive
              ? Border.all(color: Colors.white.withOpacity(0.07), width: 1)
              : null,
          boxShadow: isActive
              ? AppTheme.goldGlow
              : (isDark ? [] : AppTheme.cardShadowLight),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }

  String _getDateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return DateFormat('EEEE').format(date).toUpperCase();
    return DateFormat('MMM d').format(date).toUpperCase();
  }

  // ── Transactions inline filter helpers ──
  List<dynamic> _getFilteredTransactions(AppProvider provider) {
    var list = provider.transactions.toList();

    // Filter by type
    if (_txFilterType != 'all') {
      list = list.where((t) => t.type == _txFilterType).toList();
    }

    // Filter by search
    if (_txSearchController.text.isNotEmpty) {
      final q = _txSearchController.text.toLowerCase();
      list = list.where((t) {
        final note = (t.note ?? '').toLowerCase();
        final desc = (t.description ?? '').toLowerCase();
        final amount = t.amount.toString();
        return note.contains(q) || desc.contains(q) || amount.contains(q);
      }).toList();
    }

    // Sort
    list.sort((a, b) {
      switch (_txSortBy) {
        case 'newest':
          return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
        case 'oldest':
          return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
        case 'highest':
          return b.amount.compareTo(a.amount);
        case 'lowest':
          return a.amount.compareTo(b.amount);
        default:
          return 0;
      }
    });

    return list;
  }

  Widget _buildTxDropdown(
      String label,
      String value,
      Map<String, String> options,
      ValueChanged<String> onChanged,
      bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            items: options.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedTransactions(
    List<dynamic> transactions,
    NumberFormat cf,
    BuildContext context,
    bool isDark, {
    AppProvider? provider,
  }) {
    // Group by date
    final groups = <String, List<dynamic>>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(t.date));
      groups.putIfAbsent(key, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final items = entry.value;
        final date = DateTime.parse(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
              child: Text(
                _getDateGroupLabel(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            Container(
              decoration: AppTheme.premiumCard(context),
              child: Column(
                children: items.asMap().entries.map((e) {
                  final isLast = e.key == items.length - 1;
                  final t = e.value;
                  final tColor = _getTransactionColor(t.type);
                  final tDate = DateTime.parse(t.date);

                  // Look up category for icon
                  final cat = (provider != null && t.categoryId != null)
                      ? provider.categories
                          .where((c) => c.id == t.categoryId)
                          .firstOrNull
                      : null;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showTransactionDetail(
                            context, t, provider, cf, isDark),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? tColor.withOpacity(0.12)
                                      : tColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: cat != null
                                    ? _buildCategoryIcon(cat.icon, tColor)
                                    : Icon(_getTransactionIcon(t.type),
                                        color: tColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.note ??
                                          cat?.name ??
                                          _getTransactionTypeLabel(t.type),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t.description ??
                                          DateFormat('h:mm a').format(tDate),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _balanceVisible
                                        ? '${t.type == 'income' ? '+' : '-'}${cf.format(t.amount)}'
                                        : '••••',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (cat != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cat.name,
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: tColor),
                                      ),
                                    )
                                  else
                                    Text(
                                      DateFormat('h:mm a').format(tDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            indent: 74,
                            color: Theme.of(context).dividerColor),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getTransactionTypeLabel(String type) {
    final s = S.of(context);
    switch (type) {
      case 'expense':
        return s.expense;
      case 'income':
        return s.incomeLabel;
      case 'transfer':
        return s.transfer;
      case 'withdrawal':
        return s.withdrawal;
      case 'goal_contribution':
        return s.goalContribution;
      case 'debt_payment':
        return s.debtPaymentLabel;
      default:
        return s.transaction;
    }
  }

  void _showTransactionDetail(BuildContext context, dynamic t,
      AppProvider? provider, NumberFormat cf, bool isDark) {
    final cat = (provider != null && t.categoryId != null)
        ? provider!.categories.where((c) => c.id == t.categoryId).firstOrNull
        : null;
    final account =
        provider?.accounts.where((a) => a.id == t.accountId).firstOrNull;
    final tColor = _getTransactionColor(t.type);
    final date = DateTime.parse(t.date);
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon + title + amount
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                          color: tColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16)),
                      child: cat != null
                          ? _buildCategoryIcon(cat.icon, tColor)
                          : Icon(_getTransactionIcon(t.type),
                              color: tColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.note ??
                                cat?.name ??
                                _getTransactionTypeLabel(t.type),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a').format(date),
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    Theme.of(ctx).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${t.type == 'income' ? '+' : '-'}${cf.format(t.amount)}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: tColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Info rows
                if (t.description != null && t.description!.isNotEmpty)
                  _detailInfoRow(
                      ctx, Icons.notes_rounded, s.description, t.description!),
                if (account != null)
                  _detailInfoRow(ctx, Icons.account_balance_rounded, s.account,
                      account.name),
                if (cat != null)
                  _detailInfoRow(
                      ctx, Icons.category_rounded, s.category, cat.name),
                if (t.type != null)
                  _detailInfoRow(ctx, Icons.label_rounded, s.type,
                      _getTransactionTypeLabel(t.type)),
                if (t.expenseSubType != null)
                  _detailInfoRow(
                      ctx,
                      Icons.repeat_rounded,
                      s.subtype,
                      t.expenseSubType![0].toUpperCase() +
                          t.expenseSubType!.substring(1)),
                if (t.isRecurring)
                  _detailInfoRow(ctx, Icons.repeat_rounded, s.recurring, s.yes),

                // Receipt image
                if (t.imagePath != null) ...[
                  const SizedBox(height: 8),
                  Text(s.receipt,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: t.imagePath!.startsWith('http')
                        ? Image.network(t.imagePath!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                color: Colors.grey.withOpacity(0.1),
                                child: const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        size: 40))))
                        : Image.file(File(t.imagePath!),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                color: Colors.grey.withOpacity(0.1),
                                child: const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        size: 40)))),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
                // Action buttons: Edit + Delete
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (provider != null) {
                              final confirmed = true;
                              Navigator.pop(ctx);
                              showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: Text(s.deleteTransaction),
                                  content: Text(s.deleteConfirm.replaceAll(
                                      '{name}',
                                      t.note ??
                                          _getTransactionTypeLabel(t.type))),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, false),
                                        child: Text(s.cancel)),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dCtx, true);
                                        provider!.deleteTransaction(t.id);
                                      },
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.error),
                                      child: Text(s.delete),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(
                                color: AppTheme.error.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  AddTransactionModal(initialTransaction: t),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(s.edit + ' ' + 'Transaction',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight
                                      .w700)), // TODO: improve localization
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text('$label  ', style: Theme.of(context).textTheme.bodySmall),
          Flexible(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String iconStr, Color color) {
    if (iconStr.startsWith('img:')) {
      final path = iconStr.substring(4);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.category_rounded, color: color, size: 18),
        ),
      );
    }
    return Icon(_categoryIconData(iconStr), color: color, size: 18);
  }

  IconData _categoryIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'phone':
        return Icons.phone_android_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'autorenew':
        return Icons.autorenew_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'child_care':
        return Icons.child_care_rounded;
      case 'build':
        return Icons.build_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      case 'goal_contribution':
        return Icons.savings_rounded;
      case 'debt_payment':
        return Icons.credit_card_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'expense':
        return AppTheme.error;
      case 'income':
        return AppTheme.success;
      case 'transfer':
        return AppTheme.info;
      case 'withdrawal':
        return AppTheme.warning;
      case 'goal_contribution':
        return AppTheme.goldPrimary;
      case 'debt_payment':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.lightTextTertiary;
    }
  }

  String _getSelectedAccountName(AppProvider provider) {
    if (provider.selectedAccountId == null) return 'All Accounts';
    final account =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    return account.isNotEmpty ? account.first.name : 'All Accounts';
  }

  Widget _buildHeaderAccountIcon(AppProvider provider) {
    if (provider.selectedAccountId != null) {
      final match =
          provider.accounts.where((a) => a.id == provider.selectedAccountId);
      if (match.isNotEmpty && match.first.imagePath != null) {
        final path = match.first.imagePath!;
        return SizedBox(
          width: 18,
          height: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: path.startsWith('http')
                ? Image.network(path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getAccountIcon(provider),
                        size: 16,
                        color: AppTheme.goldPrimary))
                : Image.file(File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getAccountIcon(provider),
                        size: 16,
                        color: AppTheme.goldPrimary)),
          ),
        );
      }
    }
    return Icon(
      provider.selectedAccountId == null
          ? Icons.account_balance_wallet_rounded
          : _getAccountIcon(provider),
      size: 16,
      color: AppTheme.goldPrimary,
    );
  }

  IconData _getAccountIcon(AppProvider provider) {
    if (provider.selectedAccountId == null)
      return Icons.account_balance_wallet_rounded;
    final account =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    if (account.isEmpty) return Icons.account_balance_wallet_rounded;
    switch (account.first.type) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'debt':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _showAccountPicker(BuildContext context, AppProvider provider) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(ctx).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(s.selectAccount,
                    style: Theme.of(ctx)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              _buildAccountOption(ctx, null, s.allAccounts,
                  Icons.account_balance_wallet_rounded, null, provider),
              if (provider.accounts.isNotEmpty)
                Divider(
                    height: 1, indent: 72, color: Theme.of(ctx).dividerColor),
              ...provider.accounts.asMap().entries.map((entry) {
                final account = entry.value;
                final isLast = entry.key == provider.accounts.length - 1;
                IconData icon;
                switch (account.type) {
                  case 'bank':
                    icon = Icons.account_balance_rounded;
                    break;
                  case 'savings':
                    icon = Icons.savings_rounded;
                    break;
                  case 'investment':
                    icon = Icons.trending_up_rounded;
                    break;
                  case 'debt':
                    icon = Icons.credit_card_rounded;
                    break;
                  default:
                    icon = Icons.account_balance_wallet_rounded;
                }
                return Column(
                  children: [
                    _buildAccountOption(ctx, account.id, account.name, icon,
                        account.balance, provider,
                        imagePath: account.imagePath),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 72,
                          color: Theme.of(ctx).dividerColor),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSubscriptions(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final allRules = provider.recurringRules.where((r) => r.isActive).toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.55, 1.0],
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Text(s.allSubscriptions,
                        style: Theme.of(ctx)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${allRules.length} ' + s.active,
                        style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(ctx).dividerColor),
              Expanded(
                child: allRules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.autorenew_rounded,
                                size: 48,
                                color:
                                    Theme.of(ctx).textTheme.bodySmall?.color),
                            const SizedBox(height: 16),
                            Text(s.noSubscriptions,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: allRules.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 76,
                            color: Theme.of(ctx).dividerColor),
                        itemBuilder: (ctx, index) {
                          final rule = allRules[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurfaceElevated
                                        : AppTheme.lightBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.autorenew_rounded,
                                      color: AppTheme.goldPrimary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          rule.templateTransaction.note ??
                                              'Subscription',
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                          'Due ${DateFormat('MMM d').format(DateTime.parse(rule.nextDate))} · ${rule.frequency}',
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                                Text(cf.format(rule.templateTransaction.amount),
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOption(BuildContext ctx, String? accountId, String name,
      IconData icon, double? balance, AppProvider provider,
      {String? imagePath}) {
    final isSelected = provider.selectedAccountId == accountId;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final currencyFormat = CurrencyHelper.formatter(provider.settings.currency);
    final iconColor = isSelected
        ? AppTheme.goldPrimary
        : Theme.of(ctx).textTheme.bodySmall?.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        provider.setSelectedAccount(accountId);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldPrimary.withOpacity(0.12)
                    : (isDark
                        ? AppTheme.darkSurfaceElevated
                        : AppTheme.lightBackground),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imagePath.startsWith('http')
                          ? Image.network(imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(icon, size: 20, color: iconColor))
                          : Image.file(File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(icon, size: 20, color: iconColor)),
                    )
                  : Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.goldPrimary : null)),
                  if (balance != null)
                    Text(currencyFormat.format(balance),
                        style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.goldPrimary, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Loading Screen ──────────────────────────────────────────────
  Widget _buildSkeletonHome(BuildContext context, bool isDark) {
    final base = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final shimmer = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.10);

    Widget box(double w, double h, {double r = 10}) =>
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          builder: (_, v, __) => Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Color.lerp(base, shimmer, (v < 0.5 ? v : 1 - v) * 2),
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
            begin: 0.5, end: 1.0, duration: 800.ms, curve: Curves.easeInOut);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account picker
                Row(children: [
                  box(160, 40, r: 14),
                  const Spacer(),
                  box(40, 40, r: 12),
                  const SizedBox(width: 10),
                  box(40, 40, r: 12),
                ]),
                const SizedBox(height: 20),
                // Balance card
                Container(
                  width: double.infinity,
                  height: 210,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                    begin: 0.4,
                    end: 0.9,
                    duration: 800.ms,
                    curve: Curves.easeInOut),
                const SizedBox(height: 20),
                // Chart card
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                    begin: 0.3,
                    end: 0.8,
                    duration: 1000.ms,
                    delay: 100.ms,
                    curve: Curves.easeInOut),
                const SizedBox(height: 20),
                // Filter pills
                Row(children: [
                  box(70, 36, r: 20),
                  const SizedBox(width: 8),
                  box(90, 36, r: 20),
                  const SizedBox(width: 8),
                  box(110, 36, r: 20),
                  const SizedBox(width: 8),
                  box(80, 36, r: 20),
                ]),
                const SizedBox(height: 20),
                // Transaction rows
                ...List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      box(44, 44, r: 14),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            box(140, 14, r: 6),
                            const SizedBox(height: 6),
                            box(80, 10, r: 6),
                          ]),
                      const Spacer(),
                      box(60, 14, r: 6),
                    ]).animate().fadeIn(
                        duration: 600.ms,
                        delay: Duration(milliseconds: 80 * i)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
