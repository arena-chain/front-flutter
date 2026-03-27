import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/models/feature_catalog/catalog_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class CatalogApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<CatalogModel>> getGames() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/catalog'),
        headers: await _getHeaders(),
      );

      print('Catalog API Response Status: ${response.statusCode}');
      print('Catalog API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => CatalogModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load games catalog (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Catalog API Error: $e');
      rethrow;
    }
  }
}
