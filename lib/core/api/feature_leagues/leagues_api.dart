import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';

class LeaguesApi {
  String get _base => '${ApiConfig.baseUrl}/api';

  // ── helper ────────────────────────────────────────────────────────────────

  List<dynamic> _asList(dynamic data, List<String> keys) {
    if (data is List) return data;
    for (final k in keys) {
      if (data is Map && data[k] is List) return data[k] as List;
    }
    return [];
  }

  // ── endpoints ─────────────────────────────────────────────────────────────

  Future<List<LeagueItem>> getLeagues() async {
    final resp = await http.get(Uri.parse('$_base/leagues'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load leagues (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    return _asList(data, ['leagues', 'data'])
        .map((e) => LeagueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeasonItem>> getSeasons(String leagueId) async {
    final resp =
        await http.get(Uri.parse('$_base/seasons?leagueId=$leagueId'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load seasons (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    return _asList(data, ['seasons', 'data'])
        .map((e) => SeasonItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchItem>> getMatches(String seasonId) async {
    final resp =
        await http.get(Uri.parse('$_base/matches?seasonId=$seasonId'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load matches (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    return _asList(data, ['matches', 'data'])
        .map((e) => MatchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StandingItem>> getStandings(String seasonId) async {
    final resp =
        await http.get(Uri.parse('$_base/standings?seasonId=$seasonId'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load standings (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    return _asList(data, ['standings', 'data'])
        .map((e) => StandingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
