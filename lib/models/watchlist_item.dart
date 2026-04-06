class WatchlistItem {
  final String ticker;
  final DateTime addedDate;

  WatchlistItem({
    required this.ticker,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'addedDate': addedDate.toIso8601String(),
  };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      ticker: json['ticker'],
      addedDate: DateTime.parse(json['addedDate']),
    );
  }
}