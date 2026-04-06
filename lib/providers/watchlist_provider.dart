import 'package:flutter/foundation.dart';
import '../models/watchlist_item.dart';
import '../models/stock_quote.dart';
import '../services/watchlist_service.dart';
import '../services/api_service.dart';

// WatchlistProver is a very useful tool when we have a long watchlist
// it calls notifyListeners to update UI to avoid manual setStates
class WatchlistProvider extends ChangeNotifier {
  final WatchlistService _watchlistService = WatchlistService();
  final ApiService _apiService = ApiService();

  List<WatchlistItem> _watchlist = [];
  Map<String, StockQuote> _quotes = {};
  bool _isLoading = false;
  String? _error;

  List<WatchlistItem> get watchlist => _watchlist;
  Map<String, StockQuote> get quotes => _quotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWatchlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _watchlist = await _watchlistService.getWatchlist();

      if (_watchlist.isNotEmpty) {
        await refreshQuotes();
      }
    } catch (e) {
      _error = 'Failed to load watchlist: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshQuotes() async {
    if (_watchlist.isEmpty) return;

    _isLoading = true;
    notifyListeners(); // Show loading indicator

    try {
      final tickers = _watchlist.map((item) => item.ticker).toList();
      print('Refreshing quotes for: $tickers');

      // Call getQuote individually for each ticker (no batch API available)
      for (var ticker in tickers) {
        final quote = await _apiService.getQuote(ticker);
        if (quote != null) {
          _quotes[ticker] = quote;
          print('Added quote for $ticker: \$${quote.price}');
          notifyListeners(); // Update UI progressively as each quote loads
        } else {
          print('Failed to get quote for $ticker');
        }
      }

      print('Total quotes loaded: ${_quotes.length}');
    } catch (e) {
      print('Error refreshing quotes: $e');
      _error = 'Failed to load stock prices';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a single quote (useful for detail screen to use cached data)
  Future<StockQuote?> getQuoteForTicker(String ticker) async {
    // Check if we already have it cached
    if (_quotes.containsKey(ticker)) {
      print('Using cached quote for $ticker');
      return _quotes[ticker];
    }

    // Fetch it if not cached
    print('Fetching fresh quote for $ticker');
    final quote = await _apiService.getQuote(ticker);
    if (quote != null) {
      _quotes[ticker] = quote;
      notifyListeners();
    }
    return quote;
  }

  Future<void> addStock(String ticker) async {
    try {
      await _watchlistService.addToWatchlist(ticker);
      await loadWatchlist();
    } catch (e) {
      _error = 'Failed to add stock: $e';
      notifyListeners();
    }
  }

  Future<void> removeStock(String ticker) async {
    try {
      await _watchlistService.removeFromWatchlist(ticker);
      _quotes.remove(ticker);
      await loadWatchlist();
    } catch (e) {
      _error = 'Failed to remove stock: $e';
      notifyListeners();
    }
  }

  Future<bool> isInWatchlist(String ticker) async {
    return await _watchlistService.isInWatchlist(ticker);
  }
}