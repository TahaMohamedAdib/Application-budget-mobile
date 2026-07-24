import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/transaction.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/modern_chart.dart';
import '../widgets/storage_image.dart';
import '../l10n/app_localizations.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all';
  String _sortBy = 'newest';
  bool _showFilters = false;
  String _chartTimeframe = '1W';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // T9: rebuild only when the data this screen actually reads changes
    // (transactions, categories, currency) — not on every unrelated
    // notifyListeners() (e.g. holding price ticks, daret state). The full
    // provider is still read for the body via context.read.
    return Selector<AppProvider, ({int txn, int cats, String currency})>(
      selector: (_, p) => (
        // Hash id+amount+date+type+category so both add/delete AND in-place
        // edits of a rendered field trigger a rebuild.
        txn: Object.hashAll(
          p.transactions.map(
            (t) => Object.hash(t.id, t.amount, t.date, t.type, t.categoryId),
          ),
        ),
        cats: p.categories.length,
        currency: p.settings.currency,
      ),
      builder: (context, _, __) {
        final provider = context.read<AppProvider>();
        // Filter and sort transactions
        var filteredTransactions = provider.transactions.where((t) {
          // Filter by type
          if (_filterType != 'all' && t.type != _filterType) return false;

          // Filter by search query
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final note = (t.note ?? '').toLowerCase();
            final amount = t.amount.toString();
            if (!note.contains(query) && !amount.contains(query)) return false;
          }

          return true;
        }).toList();

        // Sort transactions
        filteredTransactions.sort((a, b) {
          switch (_sortBy) {
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

        // Calculate totals
        final totalExpenses = filteredTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = filteredTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightSurface,
                                shape: BoxShape.circle,
                                boxShadow: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? []
                                    : AppTheme.cardShadowLight,
                              ),
                              child: IconButton(
                                icon: const Iconify(AppIcons.back, size: 20),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              s.transactions,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '${s.search}...',
                                  prefixIcon:
                                      const Icon(Icons.search, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _showFilters
                                    ? AppTheme.brandPrimary.withOpacity(0.2)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _showFilters
                                      ? AppTheme.brandPrimary
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: IconButton(
                                icon: Iconify(
                                  AppIcons.filter,
                                  color: _showFilters
                                      ? AppTheme.brandPrimary
                                      : Theme.of(context).iconTheme.color,
                                ),
                                onPressed: () => setState(
                                    () => _showFilters = !_showFilters),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),

                        // Filters
                        if (_showFilters) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.category,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _filterType,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                            value: 'all', child: Text(s.all)),
                                        DropdownMenuItem(
                                            value: 'expense',
                                            child: Text(s.expense)),
                                        DropdownMenuItem(
                                            value: 'income',
                                            child: Text(s.incomeLabel)),
                                        DropdownMenuItem(
                                            value: 'transfer',
                                            child: Text(s.transfer)),
                                        DropdownMenuItem(
                                            value: 'withdrawal',
                                            child: Text(s.withdrawal)),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _filterType = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sort By', // no matching l10n key
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _sortBy,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                            value: 'newest',
                                            child: Text(s.sortNewest)),
                                        DropdownMenuItem(
                                            value: 'oldest',
                                            child: Text(s.sortOldest)),
                                        DropdownMenuItem(
                                            value: 'highest',
                                            child: Text(s.sortHighest)),
                                        DropdownMenuItem(
                                            value: 'lowest',
                                            child: Text(s.sortLowest)),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _sortBy = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Spending Chart
                  _buildSpendingChart(context, provider, s),

                  // Transactions List
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Iconify(
                                  AppIcons.receipt,
                                  size: 64,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          _filterType != 'all'
                                      ? 'No transactions found'
                                      : 'No transactions yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          _filterType != 'all'
                                      ? 'Try adjusting your filters'
                                      : 'Tap the + button to add your first transaction',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final rows = _buildTransactionGroups(
                                  filteredTransactions, provider, context, s);
                              return ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 110),
                                itemCount: rows.length,
                                itemBuilder: (context, index) => rows[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpendingChart(BuildContext context, AppProvider provider, S s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final now = DateTime.now();

    // Determine chart color and label based on filter
    Color lineColor;
    String chartLabel;
    switch (_filterType) {
      case 'expense':
        lineColor = AppTheme.error;
        chartLabel = 'Expenses';
        break;
      case 'income':
        lineColor = AppTheme.success;
        chartLabel = 'Income';
        break;
      case 'transfer':
        lineColor = AppTheme.info;
        chartLabel = 'Transfers';
        break;
      case 'withdrawal':
        lineColor = AppTheme.warning;
        chartLabel = 'Withdrawals';
        break;
      default:
        lineColor = AppTheme.brandPrimary;
        chartLabel = 'Spending';
        break;
    }

    // Timeframe config
    late DateTime chartStart;
    late int numPoints;
    switch (_chartTimeframe) {
      case '1D':
        chartStart = now.subtract(const Duration(hours: 24));
        numPoints = 24;
        break;
      case '1W':
        chartStart = now.subtract(const Duration(days: 7));
        numPoints = 7;
        break;
      case '1M':
        chartStart = now.subtract(const Duration(days: 30));
        numPoints = 30;
        break;
      case '6M':
        chartStart = now.subtract(const Duration(days: 180));
        numPoints = 26;
        break;
      case '1Y':
        chartStart = now.subtract(const Duration(days: 365));
        numPoints = 12;
        break;
      default:
        chartStart = now.subtract(const Duration(days: 7));
        numPoints = 7;
    }

    final totalDuration = now.difference(chartStart);
    final intervalMs = totalDuration.inMilliseconds / (numPoints - 1);

    // Filter matching transactions
    bool matchesFilter(Transaction t) {
      if (_filterType == 'all')
        return t.type == 'expense' || t.type == 'income';
      return t.type == _filterType;
    }

    // Build cumulative spending per point
    final relevantTxns = provider.transactions.where((t) {
      if (!matchesFilter(t)) return false;
      final d = DateTime.parse(t.date);
      return d.isAfter(chartStart.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    double cumulative = 0;
    int txnIdx = 0;
    for (int i = 0; i < numPoints; i++) {
      final pointTime =
          chartStart.add(Duration(milliseconds: (intervalMs * i).round()));
      while (txnIdx < relevantTxns.length &&
          DateTime.parse(relevantTxns[txnIdx].date)
              .isBefore(pointTime.add(const Duration(seconds: 1)))) {
        cumulative += relevantTxns[txnIdx].amount;
        txnIdx++;
      }
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    final totalAmount = cumulative;

    if (spots.length < 2) {
      spots.add(const FlSpot(0, 0));
      spots.add(const FlSpot(1, 0));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final yPadding = range == 0 ? 100.0 : range * 0.15;

    String formatYLabel(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ModernChart(
        title: chartLabel,
        totalValue: totalAmount,
        currency: provider.settings.currency,
        spots: spots,
        selectedPeriod: _chartTimeframe,
        onPeriodChanged: (period) => setState(() => _chartTimeframe = period),
        periods: const ['1D', '1W', '1M', '6M', '1Y'],
        lineColor: lineColor,
        chartStart: chartStart,
        chartEnd: now,
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _chartLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
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

  List<Widget> _buildTransactionGroups(
      List transactions, AppProvider provider, BuildContext context, S s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);

    final groups = <String, List>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(t.date));
      groups.putIfAbsent(key, () => []).add(t);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      final date = DateTime.parse(entry.key);
      widgets.add(
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
      );
      widgets.add(
        Container(
          decoration: AppTheme.premiumCard(context),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final t = e.value;
              final tColor = _getTransactionColor(t.type);
              final date = DateTime.parse(t.date);

              // Look up category
              final cat = t.categoryId != null
                  ? provider.categories
                      .where((c) => c.id == t.categoryId)
                      .firstOrNull
                  : null;

              return Column(
                children: [
                  Slidable(
                    key: Key(t.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.22,
                      children: [
                        CustomSlidableAction(
                          onPressed: (_) async {
                            final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
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
                            if (confirmed) provider.deleteTransaction(t.id);
                          },
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                                color: AppTheme.error, shape: BoxShape.circle),
                            child: const Iconify(AppIcons.delete,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _showTransactionDetail(
                          context, t, provider, cf, isDark, s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? tColor.withOpacity(0.12)
                                    : const Color(0xFFF0F1F5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: cat != null
                                  ? _buildCategoryIcon(cat.icon, tColor)
                                  : Iconify(
                                      _getTransactionDisplayIcon(
                                          t.type, t.note),
                                      color: tColor,
                                      size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
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
                                      ),
                                      if (cat != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cat.name,
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: tColor),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${t.type == 'income' ? '+' : '-'}${cf.format(t.amount)}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(date),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 70,
                        color: Theme.of(context).dividerColor),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  void _showTransactionDetail(BuildContext context, Transaction t,
      AppProvider provider, NumberFormat cf, bool isDark, S s) {
    final cat = t.categoryId != null
        ? provider.categories.where((c) => c.id == t.categoryId).firstOrNull
        : null;
    final account =
        provider.accounts.where((a) => a.id == t.accountId).firstOrNull;
    final tColor = _getTransactionColor(t.type);
    final date = DateTime.parse(t.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                          : Iconify(_getTransactionDisplayIcon(t.type, t.note),
                              color: tColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.note ?? cat?.name ?? t.type,
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
                      ctx, AppIcons.notes, 'Description', t.description!),
                if (account != null)
                  _detailInfoRow(ctx, AppIcons.bank, 'Account', account.name),
                if (cat != null)
                  _detailInfoRow(
                      ctx, AppIcons.categoryIcon, 'Category', cat.name),
                if (t.expenseSubType != null)
                  _detailInfoRow(
                      ctx,
                      AppIcons.tag,
                      'Type',
                      t.expenseSubType![0].toUpperCase() +
                          t.expenseSubType!.substring(1)),
                if (t.isRecurring)
                  _detailInfoRow(ctx, AppIcons.repeat, 'Recurring', 'Yes'),
                const SizedBox(height: 8),
                // Receipt image
                if (t.imagePath != null) ...[
                  Text('Receipt',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openReceiptViewer(ctx, t.imagePath!),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: StorageImage(
                            stored: t.imagePath!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(ctx).dividerColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey.withOpacity(0.1),
                              child: const Center(
                                child: Iconify(AppIcons.image, size: 40),
                              ),
                            ),
                          ),
                        ),
                        // Zoom hint badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Iconify(AppIcons.zoomIn,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Tap to open',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Action buttons: Delete + Edit
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
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
                                      provider.deleteTransaction(t.id);
                                    },
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.error),
                                    child: Text(s.delete),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Iconify(AppIcons.delete, size: 18),
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
                          icon: const Iconify(AppIcons.edit, size: 18),
                          label: const Text('Edit Transaction',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandPrimary,
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
      BuildContext context, String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Iconify(icon,
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

  // ── Full-screen receipt viewer with pinch-to-zoom ──────────
  void _openReceiptViewer(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Tap outside to close
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(color: Colors.transparent),
                ),
                // Pinch-to-zoom image
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 6.0,
                    child: StorageImage(
                      stored: imagePath,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorBuilder: (_, __, ___) => const Iconify(
                        AppIcons.image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                // Close button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Iconify(AppIcons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                // Hint label
                const SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Pinch to zoom  •  Tap outside to close',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              Iconify(AppIcons.categoryIcon, color: color, size: 18),
        ),
      );
    }
    return Iconify(_categoryIcon(iconStr), color: color, size: 18);
  }

  String _categoryIcon(String iconName) {
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
      case 'autorenew':
        return AppIcons.autoRenew;
      case 'fitness_center':
        return AppIcons.gym;
      case 'local_cafe':
        return AppIcons.coffee;
      case 'child_care':
        return AppIcons.baby;
      case 'build':
        return AppIcons.tools;
      default:
        return AppIcons.categoryIcon;
    }
  }

  String _getTransactionDisplayIcon(String type, String? note) {
    if (type == 'income') {
      final n = note?.toLowerCase() ?? '';
      if (n.contains('salary') ||
          n.contains('salaire') ||
          n.contains('paycheck') ||
          n.contains('wage')) {
        return AppIcons.payment;
      }
    }
    return _getTransactionIcon(type);
  }

  String _getTransactionIcon(String type) {
    switch (type) {
      case 'expense':
        return AppIcons.expense;
      case 'income':
        return AppIcons.income;
      case 'transfer':
        return AppIcons.transfer;
      case 'withdrawal':
        return AppIcons.withdrawal;
      case 'goal_contribution':
        return AppIcons.savings;
      case 'debt_payment':
        return AppIcons.creditCard;
      default:
        return AppIcons.receipt;
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
        return AppTheme.brandPrimary;
      case 'debt_payment':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
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
}
