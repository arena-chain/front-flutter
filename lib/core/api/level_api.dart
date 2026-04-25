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
    final endpoints = [
      '$baseUrl/api/level/me',
      '$baseUrl/level/me',
    ];
    
    try {
      for (final endpoint in endpoints) {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return PlayerLevel.fromJson(data);
        }
      }
      // Graceful fallback so app keeps working when endpoint is absent.
      return PlayerLevel.fromJson(const {
        'level': 1,
        'xp': 0,
        'xpToNextLevel': 1000,
        'progressPct': 0.0,
      });
    } catch (e) {
      return PlayerLevel.fromJson(const {
        'level': 1,
        'xp': 0,
        'xpToNextLevel': 1000,
        'progressPct': 0.0,
      });
    }
  }
}
