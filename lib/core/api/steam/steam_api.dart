import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';

class SteamApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getStatus({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/steam-verification/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Steam status error: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> link({
    required String steamId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/steam-verification/link'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'steamId': steamId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errBody(res));
  }

  Future<Map<String, dynamic>> verify({
    required String steamId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/steam-verification/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'steamId': steamId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errBody(res));
  }

  Future<void> unlink({required String token}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/steam-verification/unlink'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errBody(res));
    }
  }

  String _errBody(http.Response res) {
    try {
      final d = jsonDecode(res.body);
      if (d is Map && d['message'] != null) return d['message'].toString();
    } catch (_) {}
    return 'Steam API error: ${res.statusCode}';
  }
}
