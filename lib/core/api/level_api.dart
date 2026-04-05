import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/level_model.dart';

class LevelApi {
  final String baseUrl = AuthApi.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<PlayerLevel> getMyLevel() async {
    final token = await _tokenStorage.getAccessToken();
    final url = Uri.parse('$baseUrl/api/me/level');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlayerLevel.fromJson(data);
      } else {
        throw Exception('Failed to load level data');
      }
    } catch (e) {
      throw Exception('Failed to load level progression: $e');
    }
  }
}
