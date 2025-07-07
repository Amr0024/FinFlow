import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Point this at your Cloud Run (or local) URL:
  final String _baseUrl = 'https://YOUR-CLOUD-RUN-URL';
  // If testing on Android emulator locally, use 10.0.2.2:
  // final _baseUrl = 'http://10.0.2.2:8080';

  /// Fetch AI recommendations for the current user.
  Future<Map<String, dynamic>> fetchRecommendations(String uid) async {
    final uri = Uri.parse('$_baseUrl/recommend?uid=$uid');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('API error: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }
}
