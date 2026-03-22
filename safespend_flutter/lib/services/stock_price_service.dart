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

    // Sum shares per symbol (user may have same symbol entered multiple times)
    final symbolShares = <String, double>{};
    for (final h in holdings) {
      symbolShares[h.symbol] = (symbolShares[h.symbol] ?? 0) + h.shares;
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
          final value = (symbolShares[sym] ?? 0) * price;
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
