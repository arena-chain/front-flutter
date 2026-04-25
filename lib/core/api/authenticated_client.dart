import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// An HTTP helper that transparently refreshes the access token on 401.
///
/// Usage — replace raw `http.get/post/delete` calls:
/// ```dart
/// final client = AuthenticatedClient();
/// final response = await client.get(Uri.parse(url));
/// ```
///
/// If the server returns 401, the client will:
///   1. Call `POST /auth/refresh` with the stored refresh token.
///   2. Store the new tokens.
///   3. Retry the original request **once**.
///   4. If the refresh itself fails, the 401 is returned as-is.
class AuthenticatedClient {
  final TokenStorage _tokenStorage;

  /// Singleton so all API classes share the same refresh-lock.
  static final AuthenticatedClient _instance = AuthenticatedClient._internal();
  factory AuthenticatedClient() => _instance;

  AuthenticatedClient._internal() : _tokenStorage = TokenStorage();

  /// Whether a refresh is already in progress (prevents parallel refreshes).
  bool _isRefreshing = false;

  // ── Internal helpers ───────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Try to refresh the access token using the stored refresh token.
  /// Returns `true` if new tokens were saved, `false` on failure.
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

  /// Public method to proactively refresh the token (e.g., on app startup).
  Future<bool> tryRefreshToken() => _refreshTokens();

  // ── Public HTTP methods ────────────────────────────────────────────────

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
}
