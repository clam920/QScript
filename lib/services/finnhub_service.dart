import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FinnhubService {
  // 1. Setup specific to Finnhub
  static String get _apiKey => dotenv.env['FINNHUB_API_KEY'] ?? '';
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  // 2. Finnhub-specific endpoints
  Future<List<dynamic>> getCompanyNews(String ticker, String fromDate, String toDate) async {
    try {
      // Finnhub uses a different URL structure than FMP
      final url = Uri.parse(
          '$_baseUrl/company-news?symbol=$ticker&from=$fromDate&to=$toDate&token=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        print('Finnhub API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Finnhub news: $e');
      return [];
    }
  }
}