// lib/services/fingpt_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;


class FinGPTApiService {
  final String _baseUrl;

  FinGPTApiService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    const env = String.fromEnvironment('FINGPT_API_URL');
    if (env.isNotEmpty) return env;
    return 'http://${_host()}:8081';
  }

  static String _host() {
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  /// GET /
  Future<Map<String, dynamic>> health() async {
    final token = await _getIdToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('FinGPT API error: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /recommend  { "uid": user.uid }
  Future<List<String>> getRecommendations() async {
    final user   = FirebaseAuth.instance.currentUser!;
    final token  = await _getIdToken();
    final res = await http.post(
      Uri.parse('$_baseUrl/recommend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'uid': user.uid}),
    );
    if (res.statusCode != 200) {
      throw Exception('FinGPT recos error: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['recommendations'] as List<dynamic>).cast<String>();
  }
  Future<String?> _getIdToken() async =>
      FirebaseAuth.instance.currentUser!.getIdToken();
}
