class StockQuote {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final int? volume;
  final double? marketCap;
  final double? dayHigh;
  final double? dayLow;

  StockQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    this.volume,
    this.marketCap,
    this.dayHigh,
    this.dayLow,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercentage'] ?? 0).toDouble(),
      volume: json['volume'],
      marketCap: json['marketCap']?.toDouble(),
      dayHigh: json['dayHigh']?.toDouble(),
      dayLow: json['dayLow']?.toDouble(),
    );
  }
}
