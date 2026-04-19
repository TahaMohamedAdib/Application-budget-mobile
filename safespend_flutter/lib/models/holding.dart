import 'dart:convert';

class Holding {
  final String id;
  final String symbol;
  final String? title;
  final double shares;
  final double costBasis;
  final double currentPrice;
  final String? notes;
  /// ISO-8601 date string (yyyy-MM-dd) of when the user bought this holding.
  final String? purchaseDate;
  final String? sourceAccountId;
  final bool affectsSourceBalance;
  final double? sourceAmount;

  Holding({
    required this.id,
    required this.symbol,
    this.title,
    required this.shares,
    required this.costBasis,
    this.currentPrice = 0,
    this.notes,
    this.purchaseDate,
    this.sourceAccountId,
    this.affectsSourceBalance = false,
    this.sourceAmount,
  });

  double get totalCost => shares * costBasis;
  double get currentValue => shares * currentPrice;
  double get gainLoss => currentValue - totalCost;
  double get gainLossPercent => totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

  Holding copyWith({
    String? id,
    String? symbol,
    String? title,
    double? shares,
    double? costBasis,
    double? currentPrice,
    String? notes,
    String? purchaseDate,
    String? sourceAccountId,
    bool? affectsSourceBalance,
    double? sourceAmount,
  }) {
    return Holding(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      title: title ?? this.title,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      currentPrice: currentPrice ?? this.currentPrice,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      affectsSourceBalance: affectsSourceBalance ?? this.affectsSourceBalance,
      sourceAmount: sourceAmount ?? this.sourceAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'title': title,
      'shares': shares,
      'costBasis': costBasis,
      'currentPrice': currentPrice,
      'notes': notes,
      'purchaseDate': purchaseDate,
      'sourceAccountId': sourceAccountId,
      'affectsSourceBalance': affectsSourceBalance,
      'sourceAmount': sourceAmount,
    };
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'],
      symbol: json['symbol'],
      title: json['title'],
      shares: (json['shares'] as num).toDouble(),
      costBasis: (json['costBasis'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      purchaseDate: json['purchaseDate'] as String?,
      sourceAccountId: json['sourceAccountId'] as String?,
      affectsSourceBalance: json['affectsSourceBalance'] ?? false,
      sourceAmount: (json['sourceAmount'] as num?)?.toDouble(),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Holding.fromJsonString(String str) => Holding.fromJson(jsonDecode(str));
}
