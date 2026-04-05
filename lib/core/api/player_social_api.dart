import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// Player profile + ranks for another user (mirrors desktop `profile/renderer.js`).
class PlayerSocialApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>?> getPlayerByUserId(String userId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/player/$userId'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) {
      return json.decode(r.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>> getRanksForUser(String userId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/rank/user/$userId/all'),
      headers: await _headers(),
    );
    if (r.statusCode != 200) return [];
    final decoded = json.decode(r.body);
    if (decoded is List) return decoded;
    return [];
  }

  /// GET /friendship/status/:userId1/:userId2 → { status: NONE|PENDING|ACCEPTED|... }
  Future<String?> getFriendshipStatus(String userId1, String userId2) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/friendship/status/$userId1/$userId2'),
      headers: await _headers(),
    );
    if (r.statusCode != 200) return null;
    final data = json.decode(r.body);
    if (data is Map && data['status'] != null) {
      return data['status'] as String;
    }
    return null;
  }
}
