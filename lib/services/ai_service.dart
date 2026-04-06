import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Use dotenv to hide the API URL from the source code
  static String get _baseUrl => dotenv.env['AI_SERVICE_URL'] ?? 'http://localhost:8000';

  Future<Map<String, dynamic>?> analyzeSentiment(String headline, String summary) async {
    try {
      final url = Uri.parse('$_baseUrl/analyze');
      
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'headline': headline,
          'summary': summary,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      print('AI Service Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error calling AI service: $e');
      return null;
    }
  }
}