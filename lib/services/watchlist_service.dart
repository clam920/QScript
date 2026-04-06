import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_item.dart';

// backend code for watchlist data functions
class WatchlistService {
  static const String _key = 'watchlist';

  Future<List<WatchlistItem>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WatchlistItem.fromJson(json)).toList();
  }

  Future<void> addToWatchlist(String ticker) async {
    final watchlist = await getWatchlist();

    // Check if already exists
    if (watchlist.any((item) => item.ticker.toLowerCase() == ticker.toLowerCase())) {
      return;
    }

    watchlist.add(WatchlistItem(
      ticker: ticker.toUpperCase(),
      addedDate: DateTime.now(),
    ));

    await _saveWatchlist(watchlist);
  }

  Future<void> removeFromWatchlist(String ticker) async {
    final watchlist = await getWatchlist();
    watchlist.removeWhere((item) => item.ticker.toLowerCase() == ticker.toLowerCase());
    await _saveWatchlist(watchlist);
  }

  Future<bool> isInWatchlist(String ticker) async {
    final watchlist = await getWatchlist();
    return watchlist.any((item) => item.ticker.toLowerCase() == ticker.toLowerCase());
  }

  Future<void> _saveWatchlist(List<WatchlistItem> watchlist) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(watchlist.map((item) => item.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}