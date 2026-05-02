import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

class LeaguesApi {
  String get _base => '${ApiConfig.baseUrl}/api';
  String? _workingBase;
  static const Duration _timeout = Duration(seconds: 8);
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── helper ────────────────────────────────────────────────────────────────

  List<dynamic> _asList(dynamic data, List<String> keys) {
    if (data is List) return data;
    for (final k in keys) {
      if (data is Map && data[k] is List) return data[k] as List;
    }
    return [];
  }

  List<String> _candidateBases() {
    final configured = _base;
    final candidates = <String>[
      if (_workingBase case final String workingBase) workingBase,
      configured,
      'http://10.0.2.2:3000/api',
      'http://127.0.0.1:3000/api',
      'http://localhost:3000/api',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<dynamic> _getJson(String endpoint) async {
    Exception? lastError;
    final headers = await _headers();
    for (final base in _candidateBases()) {
      final uri = Uri.parse('$base$endpoint');
      try {
        final resp = await http.get(uri, headers: headers).timeout(_timeout);
        if (resp.statusCode == 200) {
          _workingBase = base;
          return jsonDecode(resp.body);
        }
        lastError = Exception(
          'Failed request ${uri.path} (${resp.statusCode}) on ${uri.host}',
        );
      } on SocketException catch (_) {
        lastError = Exception(
          'Network is unreachable. Check backend host/IP and emulator networking.',
        );
      } on TimeoutException {
        lastError = Exception('Request timed out on ${uri.host}');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach leagues backend.');
  }

  Future<dynamic> _postJson(String endpoint, Map<String, dynamic> body) async {
    Exception? lastError;
    final headers = await _headers();
    for (final base in _candidateBases()) {
      final uri = Uri.parse('$base$endpoint');
      try {
        final resp = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ).timeout(_timeout);
        
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          _workingBase = base;
          return jsonDecode(resp.body);
        }
        
        final errorMsg = _tryParseError(resp.body);
        lastError = Exception(errorMsg ?? 'Failed request ${resp.statusCode}');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach leagues backend.');
  }

  String? _tryParseError(String body) {
    try {
      final data = jsonDecode(body);
      return (data['message'] ?? data['error'])?.toString();
    } catch (_) {
      return null;
    }
  }

  // ── endpoints ─────────────────────────────────────────────────────────────

  Future<List<LeagueItem>> getLeagues() async {
    final data = await _getJson('/leagues');
    return _asList(data, ['leagues', 'data'])
        .map((e) => LeagueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeasonItem>> getSeasons(String leagueId) async {
    final data = await _getJson('/seasons?leagueId=$leagueId');
    final seasons = _asList(data, ['seasons', 'data'])
        .map((e) => SeasonItem.fromJson(e as Map<String, dynamic>))
        .toList();
    seasons.sort((a, b) {
      final scoreA = a.status.toUpperCase() == 'ONGOING' ? 0 : 1;
      final scoreB = b.status.toUpperCase() == 'ONGOING' ? 0 : 1;
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);
      return a.name.compareTo(b.name);
    });
    return seasons;
  }

  Future<List<MatchItem>> getMatches(String seasonId, {String? status}) async {
    final statusQuery = (status != null && status.isNotEmpty) ? '&status=$status' : '';
    final data = await _getJson('/matches?seasonId=$seasonId$statusQuery');
    final matches = _asList(data, ['matches', 'data'])
        .map((e) => MatchItem.fromJson(e as Map<String, dynamic>))
        .toList();
    matches.sort((a, b) {
      final aTime = a.scheduledDateTime;
      final bTime = b.scheduledDateTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });
    return matches;
  }

  Future<List<StandingItem>> getStandings(String seasonId) async {
    final data = await _getJson('/standings?seasonId=$seasonId');
    final standings = _asList(data, ['standings', 'data'])
        .map((e) => StandingItem.fromJson(e as Map<String, dynamic>))
        .toList();
    standings.sort((a, b) => a.rank.compareTo(b.rank));
    return standings;
  }

  Future<void> registerForLeague(String leagueId, String category) async {
    await _postJson('/leagues/$leagueId/register', {'category': category});
  }
}
