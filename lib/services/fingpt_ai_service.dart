// lib/services/fingpt_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class FinGPTApiService {
  static const _baseUrl = 'https://fingpt-api-xxxxx-uc.a.run.app'; // <-- your URL

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
  Future<List<dynamic>> getRecommendations() async {
    final user   = FirebaseAuth.instance.currentUser!;
    final token  = await user.getIdToken();
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
    return body['recommendations'] as List<dynamic>;
  }

  Future<Future<String?>> _getIdToken() async =>
      FirebaseAuth.instance.currentUser!.getIdToken();
}
