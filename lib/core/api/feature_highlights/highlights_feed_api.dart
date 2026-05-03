import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Player-facing public highlights feed (`GET /api/highlights/public`).
/// See `MOBILE_HIGHLIGHTS_FEED_GUIDE.md`.
class HighlightsFeedApi {
  static const Duration _timeout = Duration(seconds: 8);
  String? _workingApiRoot;
  final TokenStorage _tokenStorage = TokenStorage();

  String get _configuredApiRoot => ApiConfig.baseUrl;

  List<String> _candidateApiRoots() {
    final candidates = <String>[
      if (_workingApiRoot case final String working) working,
      _configuredApiRoot,
      'http://10.0.2.2:3000/api',
      'http://127.0.0.1:3000/api',
      'http://localhost:3000/api',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<List<HighlightItem>> fetchPublicHighlights() async {
    Exception? lastError;
    for (final root in _candidateApiRoots()) {
      final uri = Uri.parse('$root/highlights/public');
      try {
        final resp = await http.get(uri).timeout(_timeout);
        if (resp.statusCode == 200) {
          _workingApiRoot = root;
          if (resp.body.isEmpty) return [];
          final decoded = jsonDecode(resp.body);
          if (decoded is! List) return [];
          return decoded
              .map((e) => HighlightItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        lastError = Exception('Highlights feed failed (${resp.statusCode})');
      } on SocketException {
        lastError = Exception('Network unreachable on $root');
      } on TimeoutException {
        lastError = Exception('Highlights request timed out');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to load highlights');
  }

  // ─── Engagement (likes / comments) ────────────────────────────────────

  Future<Map<String, String>> _authedHeaders({required bool json}) async {
    final token = await _tokenStorage.getAccessToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getEngagement(String highlightId) async {
    final headers = await _authedHeaders(json: false);
    final root = _workingApiRoot ?? _configuredApiRoot;
    final res = await http
        .get(
          Uri.parse('$root/highlights/$highlightId/engagement'),
          headers: headers,
        )
        .timeout(_timeout);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception(_decodeError(res, fallback: 'engagement'));
  }

  Future<Map<String, dynamic>> like(String highlightId) async {
    final headers = await _authedHeaders(json: true);
    final root = _workingApiRoot ?? _configuredApiRoot;
    final res = await http
        .post(
          Uri.parse('$root/highlights/$highlightId/like'),
          headers: headers,
          body: jsonEncode(<String, dynamic>{}),
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception(_decodeError(res, fallback: 'like'));
  }

  Future<Map<String, dynamic>> unlike(String highlightId) async {
    final headers = await _authedHeaders(json: false);
    final root = _workingApiRoot ?? _configuredApiRoot;
    final res = await http
        .delete(
          Uri.parse('$root/highlights/$highlightId/like'),
          headers: headers,
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 204) {
      if (res.body.isEmpty) return {'liked': false};
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception(_decodeError(res, fallback: 'unlike'));
  }

  Future<List<Map<String, dynamic>>> listComments(String highlightId) async {
    final headers = await _authedHeaders(json: false);
    final root = _workingApiRoot ?? _configuredApiRoot;
    final res = await http
        .get(
          Uri.parse('$root/highlights/$highlightId/comments'),
          headers: headers,
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return [];
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return [];
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw Exception(_decodeError(res, fallback: 'list comments'));
  }

  Future<Map<String, dynamic>> addComment(
    String highlightId, {
    required String body,
    String? parentCommentId,
  }) async {
    final headers = await _authedHeaders(json: true);
    final root = _workingApiRoot ?? _configuredApiRoot;
    final payload = <String, dynamic>{
      'body': body,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    };
    final res = await http
        .post(
          Uri.parse('$root/highlights/$highlightId/comments'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    throw Exception(_decodeError(res, fallback: 'add comment'));
  }

  String _decodeError(http.Response res, {required String fallback}) {
    try {
      final d = jsonDecode(res.body);
      if (d is Map && d['message'] != null) return d['message'].toString();
    } catch (_) {}
    return 'Highlights $fallback failed (${res.statusCode})';
  }
}
