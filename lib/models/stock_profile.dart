class StockProfile {
  final String symbol;
  final String companyName;
  final String? sector;
  final String? industry;
  final String? description;

  StockProfile({
    required this.symbol,
    required this.companyName,
    this.sector,
    this.industry,
    this.description,
  });

  factory StockProfile.fromJson(Map<String, dynamic> json) {
    return StockProfile(
      symbol: json['symbol'] ?? '',
      companyName: json['companyName'] ?? '',
      sector: json['sector'],
      industry: json['industry'],
      description: json['description'],
    );
  }
}