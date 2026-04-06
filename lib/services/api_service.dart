import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stock_quote.dart';
import '../models/stock_profile.dart';

class ApiService {
  static String get _apiKey => dotenv.env['FMP_API_KEY'] ?? '';
  static const String _baseUrl = 'https://financialmodelingprep.com/stable';

  // Get real-time quote for a stock
  Future<StockQuote?> getQuote(String ticker) async {
    try {
      final url = Uri.parse('$_baseUrl/quote?symbol=$ticker&apikey=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return StockQuote.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching quote: $e');
      return null;
    }
  }

  // Get company profile
  Future<StockProfile?> getProfile(String ticker) async {
    try {
      final url = Uri.parse('$_baseUrl/profile?symbol=$ticker&apikey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return StockProfile.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Get historical price data for chart (using free tier endpoint)
  Future<List<Map<String, dynamic>>> getHistoricalPrices(
      String ticker, {
        int days = 30,
      }) async {
    try {
      // Use the free tier endpoint: historical-price-eod/light
      final url = Uri.parse(
        '$_baseUrl/historical-price-eod/light?symbol=$ticker&apikey=$_apiKey',
      );
      print('Fetching historical prices from: $url');

      final response = await http.get(url);
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('Received ${data.length} historical data points');

        return data
            .take(days)
            .map((item) => {
          'date': item['date'],
          'close': (item['price'] ?? 0).toDouble(),
        })
            .toList()
            .reversed
            .toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      print('Error fetching historical prices: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> searchStocks(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse('$_baseUrl/search-symbol?query=$query&apikey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => {
          'symbol': item['symbol'].toString(),
          'name': item['name'].toString(),
        })
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }
}