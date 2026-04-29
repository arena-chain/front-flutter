import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';

class NewsApi {
  final String baseUrl = AuthApi.baseUrl;

  Future<NewsResponse> getNews({String? game, String? category, int page = 1, int limit = 10}) async {
    final queryParams = {
      if (game case final String g) 'game': g,
      if (category case final String c) 'category': c,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    final uri = Uri.parse('$baseUrl/api/news').replace(queryParameters: queryParams); // Added /api
    
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load news');
      }
    } on TimeoutException {
      throw Exception('News request timed out');
    } catch (e) {
      throw Exception('Failed to load news: $e');
    }
  }
}
