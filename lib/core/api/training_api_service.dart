// lib/core/api/training_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/training_models.dart';

// ─── ADJUST THESE TO MATCH YOUR PROJECT ───────────────────────────────────────
String get _kBaseUrl => ApiConfig.restApiRoot;

class TrainingApiException implements Exception {
  final String message;
  final int? statusCode;
  const TrainingApiException(this.message, {this.statusCode});
  @override
  String toString() => 'TrainingApiException($statusCode): $message';
}

class TrainingApiService {
  final http.Client _client;
  final Future<String?> Function() _getToken; // inject token getter

  TrainingApiService({
    http.Client? client,
    required Future<String?> Function() getToken,
  })  : _client = client ?? http.Client(),
        _getToken = getToken;

  Future<Map<String, String>> get _authHeaders async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken() ?? ''}',
      };

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
      };

  // ── POST /training/result ─────────────────────────────────────────────────

  Future<void> saveResult(TrainingResult result) async {
    final uri = Uri.parse('$_kBaseUrl/training/result');
    final response = await _client.post(
      uri,
      headers: await _authHeaders,
      body: jsonEncode(result.toJson()),
    );

    if (response.statusCode != 201) {
      final body = _safeDecodeBody(response.body);
      throw TrainingApiException(
        body['message']?.toString() ?? 'Failed to save result',
        statusCode: response.statusCode,
      );
    }
  }

  // ── GET /training/leaderboard ─────────────────────────────────────────────

  Future<List<LeaderboardEntry>> getLeaderboard({
    int limit = 20,
    int? duration,
    String? difficulty,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (duration != null) 'duration': duration.toString(),
      if (difficulty != null) 'difficulty': difficulty,
    };
    final uri = Uri.parse('$_kBaseUrl/training/leaderboard')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _publicHeaders);

    if (response.statusCode != 200) {
      throw TrainingApiException('Failed to fetch leaderboard',
          statusCode: response.statusCode);
    }

    final body = _safeDecodeBody(response.body);
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /training/my-stats/:userId ────────────────────────────────────────

  Future<PersonalStats> getMyStats(String userId) async {
    final uri = Uri.parse('$_kBaseUrl/training/my-stats/$userId');
    final response = await _client.get(uri, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw TrainingApiException('Failed to fetch personal stats',
          statusCode: response.statusCode);
    }

    final body = _safeDecodeBody(response.body);
    return PersonalStats.fromJson(body['data'] as Map<String, dynamic>? ?? {});
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _safeDecodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  void dispose() => _client.close();
}
