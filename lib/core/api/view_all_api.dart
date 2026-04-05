import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/view_all_models.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// Thin HTTP client for the three public "view all" endpoints.
class ViewAllApi {
  static String get _base => ApiConfig.baseUrl;
  final TokenStorage _ts = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _ts.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _check(http.Response r, String ctx) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    String msg = ctx;
    try {
      msg = jsonDecode(r.body)['message']?.toString() ?? ctx;
    } catch (_) {}
    throw Exception(msg);
  }

  // GET /player
  Future<List<PlayerDetail>> getAllPlayers() async {
    final r = await http.get(
      Uri.parse('$_base/api/player'),
      headers: await _headers(),
    );
    final data = _check(r, 'Failed to load players') as List<dynamic>;
    return data
        .map((e) => PlayerDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /leagues
  Future<List<LeagueModel>> getAllLeagues() async {
    final r = await http.get(
      Uri.parse('$_base/api/leagues'),
      headers: await _headers(),
    );
    final data = _check(r, 'Failed to load leagues') as List<dynamic>;
    return data
        .map((e) => LeagueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /tournements
  Future<List<TournamentListItem>> getAllTournaments() async {
    final r = await http.get(
      Uri.parse('$_base/api/tournements'),
      headers: await _headers(),
    );
    final data = _check(r, 'Failed to load tournaments') as List<dynamic>;
    return data
        .map((e) => TournamentListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
