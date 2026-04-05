import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/rank_model.dart';

class RankApi {
  final String baseUrl = AuthApi.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<List<Rank>> getMyRanks() async {
    final token = await _tokenStorage.getAccessToken();
    final url = Uri.parse('$baseUrl/api/rank/me/all');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((r) => Rank.fromJson(r)).toList();
      } else {
        throw Exception('Failed to load ranks');
      }
    } catch (e) {
      throw Exception('Failed to load ranks: $e');
    }
  }
}
