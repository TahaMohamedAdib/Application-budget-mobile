import 'dart:convert';

class Holding {
  final String id;
  final String symbol;
  final double shares;
  final double costBasis;
  final double currentPrice;
  final String? notes;

  Holding({
    required this.id,
    required this.symbol,
    required this.shares,
    required this.costBasis,
    this.currentPrice = 0,
    this.notes,
  });

  double get totalCost => shares * costBasis;
  double get currentValue => shares * currentPrice;
  double get gainLoss => currentValue - totalCost;
  double get gainLossPercent => totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

  Holding copyWith({
    String? id,
    String? symbol,
    double? shares,
    double? costBasis,
    double? currentPrice,
    String? notes,
  }) {
    return Holding(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      currentPrice: currentPrice ?? this.currentPrice,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'shares': shares,
      'costBasis': costBasis,
      'currentPrice': currentPrice,
      'notes': notes,
    };
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'],
      symbol: json['symbol'],
      shares: (json['shares'] as num).toDouble(),
      costBasis: (json['costBasis'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Holding.fromJsonString(String str) => Holding.fromJson(jsonDecode(str));
}
