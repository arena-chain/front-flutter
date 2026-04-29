import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/league_model.dart';

class LeagueApi {
  final String baseUrl = AuthApi.baseUrl; // No /api here because I added it to AuthApi.baseUrl or I'll handle it here.
  // Wait, I added /api to the AuthApi.baseUrl in my last rewrite of AuthApi.dart.
  // Let's re-verify AuthApi.baseUrl in Folder 2.
  
  final TokenStorage _tokenStorage = TokenStorage();

  Future<List<League>> getAllLeagues() async {
    final url = Uri.parse('$baseUrl/api/leagues'); // Added /api
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((l) => League.fromJson(l)).toList();
      } else {
        throw Exception('Failed to load leagues');
      }
    } catch (e) {
      throw Exception('Failed to load leagues: $e');
    }
  }
}
