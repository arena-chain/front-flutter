import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class AuthenticatedClient {
  final TokenStorage _tokenStorage;

  static final AuthenticatedClient _instance = AuthenticatedClient._internal();
  factory AuthenticatedClient() => _instance;

  AuthenticatedClient._internal() : _tokenStorage = TokenStorage();

  bool _isRefreshing = false;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _refreshTokens() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        debugPrint('Token refreshed successfully');
        return true;
      } else {
        debugPrint('Token refresh failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> tryRefreshToken() => _refreshTokens();

  Future<http.Response> get(Uri url) async {
    var response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        response = await http.get(url, headers: await _authHeaders());
      }
    }
    return response;
  }

  Future<http.Response> post(Uri url, {Object? body}) async {
    var response = await http.post(
      url,
      headers: await _authHeaders(),
      body: body is String ? body : jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        response = await http.post(
          url,
          headers: await _authHeaders(),
          body: body is String ? body : jsonEncode(body),
        );
      }
    }
    return response;
  }

  Future<http.Response> patch(Uri url, {Object? body}) async {
    var response = await http.patch(
      url,
      headers: await _authHeaders(),
      body: body is String ? body : jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        response = await http.patch(
          url,
          headers: await _authHeaders(),
          body: body is String ? body : jsonEncode(body),
        );
      }
    }
    return response;
  }

  Future<http.Response> delete(Uri url) async {
    var response = await http.delete(url, headers: await _authHeaders());

    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        response = await http.delete(url, headers: await _authHeaders());
      }
    }
    return response;
  }
}
