class StockNote {
  final int? id;
  final String ticker;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockNote({
    this.id,
    required this.ticker,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticker': ticker,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StockNote.fromMap(Map<String, dynamic> map) {
    return StockNote(
      id: map['id'],
      ticker: map['ticker'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  StockNote copyWith({
    int? id,
    String? ticker,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockNote(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}