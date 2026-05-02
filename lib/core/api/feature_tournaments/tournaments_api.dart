import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/tournaments/create_tournament_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class TournamentsApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();
  String? _workingBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<String> _candidateBaseUrls() {
    final candidates = <String>[
      if (_workingBaseUrl case final String working) working,
      baseUrl,
      'http://10.0.2.2:3000/api',
      'http://127.0.0.1:3000/api',
      'http://localhost:3000/api',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Exception? lastError;
    for (final candidate in _candidateBaseUrls()) {
      try {
        final response = await request(candidate).timeout(const Duration(seconds: 8));
        if (response.statusCode < 500) {
          _workingBaseUrl = candidate;
        }
        return response;
      } on SocketException {
        lastError = Exception(
          'Network unreachable. Check backend host/IP or use API_BASE_URL override.',
        );
      } on TimeoutException {
        lastError = Exception('Tournament API timeout on $candidate');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach tournaments backend.');
  }

  Future<TournamentModel> createTournament(CreateTournamentDto dto) async {
    final jsonData = dto.toJson();
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.post(
        Uri.parse('$candidateBase/tournements'),
        headers: headers,
        body: jsonEncode(jsonData),
      ),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return TournamentModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create tournament');
    }
  }

  Future<List<TournamentModel>> getTournaments() async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.get(
        Uri.parse('$candidateBase/api/tournements'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TournamentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tournaments');
    }
  }

  Future<TournamentModel> getTournamentById(String id) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.get(
        Uri.parse('$candidateBase/tournements/$id'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TournamentModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Failed to load tournament details');
  }
}
