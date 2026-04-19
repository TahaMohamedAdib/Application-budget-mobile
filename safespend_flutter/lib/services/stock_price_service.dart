import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holding.dart';

class StockQuote {
  final String symbol;
  final double price;
  final double changePercent;
  final String? companyName;
  final String? currency;

  StockQuote({
    required this.symbol,
    required this.price,
    required this.changePercent,
    this.companyName,
    this.currency,
  });
}

class PortfolioPoint {
  final DateTime date;
  final double value;
  PortfolioPoint(this.date, this.value);
}

class StockSearchResult {
  final String symbol;
  final String name;
  final String exchange;
  final String type;

  StockSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
  });
}

class StockPriceService {
  // Yahoo Finance — free, no API key required.
  // Supports stocks (AAPL), ETFs (SPY), crypto (BTC-USD, ETH-USD), forex (EURUSD=X).
  static const _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _timeout = Duration(seconds: 10);

  static final _headers = {
    'User-Agent': 'Mozilla/5.0',
    'Accept': 'application/json',
  };

  /// Fetch live price for a single symbol. Returns null on failure.
  static Future<StockQuote?> fetchQuote(String symbol) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return null;
    try {
      final uri = Uri.parse('$_baseUrl/$sym?interval=1d&range=1d');
      final response =
          await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final result = data['chart']?['result'];
      if (result == null || result.isEmpty) return null;

      final meta = result[0]['meta'] as Map<String, dynamic>;
      final price = (meta['regularMarketPrice'] as num?)?.toDouble();
      if (price == null || price == 0) return null;

      final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ??
          (meta['previousClose'] as num?)?.toDouble() ??
          price;
      final changePercent =
          prevClose > 0 ? ((price - prevClose) / prevClose) * 100 : 0.0;

      return StockQuote(
        symbol: sym,
        price: price,
        changePercent: changePercent,
        companyName:
            meta['longName'] as String? ?? meta['shortName'] as String?,
        currency: meta['currency'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the exchange rate from USD to [targetCurrency].
  /// Uses Yahoo Finance forex symbol e.g. USDMAD=X.
  /// Returns 1.0 (no conversion) if the currency is USD or fetch fails.
  static final Map<String, double> _fxCache = {};
  static DateTime? _fxCacheTime;

  static Future<double> fetchUsdRate(String targetCurrency) async {
    final cur = targetCurrency.toUpperCase().trim();
    if (cur == 'USD' || cur.isEmpty) return 1.0;

    // Use cached rate if < 30 minutes old
    if (_fxCacheTime != null &&
        DateTime.now().difference(_fxCacheTime!).inMinutes < 30 &&
        _fxCache.containsKey(cur)) {
      return _fxCache[cur]!;
    }

    try {
      // Yahoo Finance forex symbol: USD→MAD = "USDMAD=X"
      final symbol = 'USD${cur}=X';
      final uri = Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return _fxCache[cur] ?? 1.0;

      final data = jsonDecode(response.body);
      final result = data['chart']?['result'];
      if (result == null || result.isEmpty) return _fxCache[cur] ?? 1.0;

      final meta = result[0]['meta'] as Map<String, dynamic>;
      final rate = (meta['regularMarketPrice'] as num?)?.toDouble();
      if (rate == null || rate == 0) return _fxCache[cur] ?? 1.0;

      _fxCache[cur] = rate;
      _fxCacheTime = DateTime.now();
      return rate;
    } catch (_) {
      return _fxCache[cur] ?? 1.0;
    }
  }

  // Exchange suffix boosters — when user types a bare ticker, also probe these
  // common non-US suffixes so local exchanges surface at the top.
  static const _boostSuffixes = ['.CS', '.PA', '.MC', '.L', '.DE', '.MI', '.AS'];

  static Future<List<StockSearchResult>> _querySingle(String q) async {
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v1/finance/search'
      '?q=${Uri.encodeComponent(q)}&quotesCount=8&newsCount=0&listsCount=0',
    );
    try {
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final quotes = data['quotes'] as List? ?? [];
      return quotes
          .where((q) => q['symbol'] != null)
          .map((q) => StockSearchResult(
                symbol: q['symbol'] as String,
                name: q['longname'] as String? ??
                    q['shortname'] as String? ??
                    q['symbol'] as String,
                exchange: q['exchDisp'] as String? ??
                    q['exchange'] as String? ??
                    '',
                type: q['quoteType'] as String? ?? 'EQUITY',
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search for stocks/ETFs/crypto by company name or ticker — worldwide.
  ///
  /// [preferredSuffix] — when provided (e.g. ".CS" for Morocco) results from
  /// that exchange are sorted to the top and the suffixed variant is also
  /// queried explicitly so local tickers are never missed.
  static Future<List<StockSearchResult>> searchSymbols(
    String query, {
    String? preferredSuffix,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final isBareSymbol = !q.contains(' ') && !q.contains('.') && q.length <= 8;

    final futures = <Future<List<StockSearchResult>>>[_querySingle(q)];

    // Always probe the preferred market explicitly
    if (preferredSuffix != null && preferredSuffix.isNotEmpty && isBareSymbol) {
      futures.add(_querySingle('$q$preferredSuffix'));
    }

    // Also probe the generic boost suffixes when no dot present
    if (isBareSymbol) {
      for (final suffix in _boostSuffixes) {
        if (suffix != preferredSuffix) futures.add(_querySingle('$q$suffix'));
      }
    }

    final all = (await Future.wait(futures)).expand((r) => r).toList();

    // De-duplicate by symbol, preserving first-seen order
    final seen = <String>{};
    final merged = <StockSearchResult>[];
    for (final r in all) {
      if (seen.add(r.symbol)) merged.add(r);
    }

    final upper = q.toUpperCase();
    merged.sort((a, b) {
      // 1. Preferred suffix wins
      final aPref = (preferredSuffix != null && a.symbol.toUpperCase().endsWith(preferredSuffix.toUpperCase())) ? 0 : 1;
      final bPref = (preferredSuffix != null && b.symbol.toUpperCase().endsWith(preferredSuffix.toUpperCase())) ? 0 : 1;
      if (aPref != bPref) return aPref.compareTo(bPref);
      // 2. Symbol starts with query
      final aStarts = a.symbol.toUpperCase().startsWith(upper) ? 0 : 1;
      final bStarts = b.symbol.toUpperCase().startsWith(upper) ? 0 : 1;
      return aStarts.compareTo(bStarts);
    });

    return merged;
  }

  /// Fetch live prices for multiple symbols in parallel.
  static Future<Map<String, StockQuote>> fetchMultiple(
      List<String> symbols) async {
    final results = await Future.wait(symbols.map(fetchQuote));
    final map = <String, StockQuote>{};
    for (final q in results) {
      if (q != null) map[q.symbol] = q;
    }
    return map;
  }

  /// Fetch daily closing prices for [symbol] over [range].
  /// [range] values: '5d', '1mo', '3mo', '1y'
  /// Returns a map of date-string (yyyy-MM-dd) → closing price.
  static Future<Map<String, double>> _fetchDailyCloses(
      String symbol, String range) async {
    final sym = symbol.trim().toUpperCase();
    try {
      final uri =
          Uri.parse('$_baseUrl/$sym?interval=1d&range=$range');
      final response =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body);
      final result = data['chart']?['result'];
      if (result == null || result.isEmpty) return {};

      final timestamps = result[0]['timestamp'] as List?;
      final closes = (result[0]['indicators']?['quote'] as List?)
          ?.first['close'] as List?;

      if (timestamps == null || closes == null) return {};

      final map = <String, double>{};
      for (int i = 0; i < timestamps.length; i++) {
        final close = (closes[i] as num?)?.toDouble();
        if (close == null || close == 0) continue;
        final dt = DateTime.fromMillisecondsSinceEpoch(
            (timestamps[i] as int) * 1000,
            isUtc: true);
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        map[key] = close;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Compute portfolio value history over [range] for a list of holdings.
  /// Only counts each holding from its [purchaseDate] onward.
  /// Returns daily [PortfolioPoint]s sorted ascending.
  static Future<List<PortfolioPoint>> fetchPortfolioHistory(
      List<Holding> holdings, String range) async {
    if (holdings.isEmpty) return [];

    // Fetch history for each unique symbol in parallel
    final symbols = holdings.map((h) => h.symbol).toSet().toList();
    final histories = await Future.wait(
        symbols.map((s) => _fetchDailyCloses(s, range)));

    final historyMap = <String, Map<String, double>>{
      for (int i = 0; i < symbols.length; i++) symbols[i]: histories[i],
    };

    // Collect all unique date keys present in at least one history
    final allDates = <String>{};
    for (final h in historyMap.values) {
      allDates.addAll(h.keys);
    }
    if (allDates.isEmpty) return [];

    final sortedDates = allDates.toList()..sort();

    // For each date, compute total portfolio value
    final points = <PortfolioPoint>[];
    for (final dateStr in sortedDates) {
      double total = 0;
      for (final holding in holdings) {
        // Skip dates before the user actually bought this holding
        if (holding.purchaseDate != null &&
            dateStr.compareTo(holding.purchaseDate!) < 0) {
          continue;
        }
        final sym = holding.symbol;
        final symHistory = historyMap[sym] ?? {};
        // Use this date's price, or the last known price before this date
        double? price = symHistory[dateStr];
        if (price == null) {
          // Walk backwards for the most recent prior close
          final priorDates = sortedDates
              .where((d) => d.compareTo(dateStr) < 0 && symHistory.containsKey(d))
              .toList();
          if (priorDates.isNotEmpty) {
            price = symHistory[priorDates.last];
          }
        }
        if (price != null) {
          total += holding.shares * price;
        }
      }
      if (total > 0) {
        final parts = dateStr.split('-');
        points.add(PortfolioPoint(
          DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          total,
        ));
      }
    }

    return points;
  }

  /// Fetches combined AND per-symbol portfolio history in one round-trip.
  /// Groups shares by symbol so duplicate holdings are summed.
  static Future<({
    List<PortfolioPoint> combined,
    Map<String, List<PortfolioPoint>> perSymbol,
  })> fetchPortfolioHistoryAll(List<Holding> holdings, String range) async {
    if (holdings.isEmpty) {
      return (
        combined: <PortfolioPoint>[],
        perSymbol: <String, List<PortfolioPoint>>{},
      );
    }

    final symbols = holdings.map((h) => h.symbol).toSet().toList();
    final histories =
        await Future.wait(symbols.map((s) => _fetchDailyCloses(s, range)));

    final historyMap = <String, Map<String, double>>{
      for (int i = 0; i < symbols.length; i++) symbols[i]: histories[i],
    };

    final allDates = <String>{};
    for (final h in historyMap.values) allDates.addAll(h.keys);
    if (allDates.isEmpty) {
      return (
        combined: <PortfolioPoint>[],
        perSymbol: <String, List<PortfolioPoint>>{},
      );
    }

    final sortedDates = allDates.toList()..sort();

    // Sum shares per symbol, respecting purchase dates.
    // Build a map of symbol → list of (shares, purchaseDate) for date filtering.
    final symbolHoldings = <String, List<({double shares, String? purchaseDate})>>{};
    for (final h in holdings) {
      symbolHoldings.putIfAbsent(h.symbol, () => []);
      symbolHoldings[h.symbol]!.add((shares: h.shares, purchaseDate: h.purchaseDate));
    }

    final combinedPoints = <PortfolioPoint>[];
    final perSymbol = <String, List<PortfolioPoint>>{
      for (final sym in symbols) sym: [],
    };

    for (final dateStr in sortedDates) {
      final parts = dateStr.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      double total = 0;

      for (final sym in symbols) {
        final symHistory = historyMap[sym] ?? {};
        double? price = symHistory[dateStr];
        if (price == null) {
          final priorDates = sortedDates
              .where((d) => d.compareTo(dateStr) < 0 && symHistory.containsKey(d))
              .toList();
          if (priorDates.isNotEmpty) price = symHistory[priorDates.last];
        }
        if (price != null) {
          // Only count shares the user already owned on this date
          double activeShares = 0;
          for (final entry in symbolHoldings[sym] ?? []) {
            if (entry.purchaseDate == null ||
                dateStr.compareTo(entry.purchaseDate!) >= 0) {
              activeShares += entry.shares;
            }
          }
          final value = activeShares * price;
          total += value;
          if (value > 0) perSymbol[sym]!.add(PortfolioPoint(date, value));
        }
      }
      if (total > 0) combinedPoints.add(PortfolioPoint(date, total));
    }

    perSymbol.removeWhere((_, v) => v.isEmpty);
    return (combined: combinedPoints, perSymbol: perSymbol);
  }
}
