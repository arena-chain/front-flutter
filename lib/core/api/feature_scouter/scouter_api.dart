import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// HTTP client for all scouter + scouting endpoints.
class ScouterApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response resp, String ctx) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return null;
      return jsonDecode(resp.body);
    }
    String msg = ctx;
    try {
      final err = jsonDecode(resp.body);
      msg = err['message']?.toString() ?? ctx;
    } catch (_) {}
    throw Exception(msg);
  }

  // ── Catalog ───────────────────────────────────────────────────────────────

  Future<List<GameModel>> getCatalog() async {
    final headers = await _authHeaders();
    final resp = await http.get(Uri.parse('$baseUrl/api/catalog'), headers: headers);
    final data = _decode(resp, 'Failed to load games') as List<dynamic>;
    return data.map((e) => GameModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Scouter profile ───────────────────────────────────────────────────────

  Future<ScouterProfile> getScouterProfile(String userId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouter/me/$userId'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load profile') as Map<String, dynamic>;
    return ScouterProfile.fromJson(data);
  }

  // ── Players ───────────────────────────────────────────────────────────────

  Future<List<PlayerDetail>> getPlayers() async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouter/players'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load players') as List<dynamic>;
    return data
        .map((e) => PlayerDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerDetail> getPlayerDetail(String playerUserId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouter/players/$playerUserId'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load player') as Map<String, dynamic>;
    return PlayerDetail.fromJson(data);
  }

  Future<List<MatchSummary>> getPlayerMatches(String playerUserId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouter/players/$playerUserId/matches'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load matches') as List<dynamic>;
    return data
        .map((e) => MatchSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String gameId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouter/leaderboard?gameId=$gameId'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load leaderboard') as List<dynamic>;
    return data
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToEvaluated(
      String scouterUserId, String playerProfileId) async {
    final headers = await _authHeaders();
    final resp = await http.patch(
      Uri.parse('$baseUrl/api/scouter/$scouterUserId/scouted/$playerProfileId'),
      headers: headers,
      body: '{}',
    );
    _decode(resp, 'Failed to add to evaluated list');
  }

  // ── Filter players ────────────────────────────────────────────────────────

  Future<List<PlayerDetail>> filterPlayers({
    String? gameId,
    String? tier,
    String? country,
    bool? hasTeam,
    String? prospectLevel,
    String? priority,
  }) async {
    final params = <String, String>{};
    if (gameId != null) params['gameId'] = gameId;
    if (tier != null) params['tier'] = tier;
    if (country != null) params['country'] = country;
    if (hasTeam != null) params['hasTeam'] = hasTeam.toString();
    if (prospectLevel != null) params['prospectLevel'] = prospectLevel;
    if (priority != null) params['priority'] = priority;
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/players/filter')
          .replace(queryParameters: params),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to filter players') as List<dynamic>;
    return data
        .map((e) => PlayerDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<List<ScoutingReport>> getMyReports(String scouterId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/reports/scouter/$scouterId'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load reports') as List<dynamic>;
    return data
        .map((e) => ScoutingReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScoutingReport>> getPlayerReports(String playerId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/reports/player/$playerId'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load reports') as List<dynamic>;
    return data
        .map((e) => ScoutingReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScoutingReport> createReport(Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/api/scouting/reports'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = _decode(resp, 'Failed to create report') as Map<String, dynamic>;
    return ScoutingReport.fromJson(data);
  }

  Future<ScoutingReport> updateReport(
      String id, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final resp = await http.patch(
      Uri.parse('$baseUrl/api/scouting/reports/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = _decode(resp, 'Failed to update report') as Map<String, dynamic>;
    return ScoutingReport.fromJson(data);
  }

  Future<void> deleteReport(String id) async {
    final headers = await _authHeaders();
    final resp = await http.delete(
      Uri.parse('$baseUrl/api/scouting/reports/$id'),
      headers: headers,
    );
    _decode(resp, 'Failed to delete report');
  }

  // ── Prospects ─────────────────────────────────────────────────────────────

  Future<List<ProspectStatus>> getProspects(
      {String? prospectLevel, String? priority}) async {
    final params = <String, String>{};
    if (prospectLevel != null) params['prospectLevel'] = prospectLevel;
    if (priority != null) params['priority'] = priority;
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/prospects')
          .replace(queryParameters: params),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load prospects') as List<dynamic>;
    return data
        .map((e) => ProspectStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProspectStatus?> getPlayerProspect(String playerId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/prospects/player/$playerId'),
      headers: headers,
    );
    if (resp.statusCode == 404) return null;
    final data = _decode(resp, 'Failed to load prospect');
    if (data == null) return null;
    return ProspectStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<ProspectStatus> upsertProspect(Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/api/scouting/prospects'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data =
        _decode(resp, 'Failed to save prospect') as Map<String, dynamic>;
    return ProspectStatus.fromJson(data);
  }

  // ── Recommendations ───────────────────────────────────────────────────────

  Future<List<Recommendation>> getMyRecommendations(String scouterId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/recommendations/scouter/$scouterId'),
      headers: headers,
    );
    final data =
        _decode(resp, 'Failed to load recommendations') as List<dynamic>;
    return data
        .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recommendation>> getPlayerRecommendations(
      String playerId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/scouting/recommendations/player/$playerId'),
      headers: headers,
    );
    final data =
        _decode(resp, 'Failed to load recommendations') as List<dynamic>;
    return data
        .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recommendation> createRecommendation(
      Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse('$baseUrl/api/scouting/recommendations'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = _decode(resp, 'Failed to create recommendation')
        as Map<String, dynamic>;
    return Recommendation.fromJson(data);
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  Future<List<HighlightItem>> getHighlights() async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/highlights'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load highlights');
    if (data is List) {
      return data
          .map((e) => HighlightItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

<<<<<<< HEAD
=======
  /// Public catalog (same as web `GET /highlights/public`).
  Future<List<HighlightItem>> getPublicHighlights() async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/highlights/public'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load public highlights');
    if (data is List) {
      return data
          .map((e) => HighlightItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<HighlightItem>> getHighlightsForVideo(
    String videoId, {
    bool publicOnly = false,
  }) async {
    final headers = await _authHeaders();
    final q = publicOnly ? '?publicOnly=true' : '';
    final resp = await http.get(
      Uri.parse(
        '$baseUrl/api/highlights/video/${Uri.encodeComponent(videoId)}$q',
      ),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load highlights for video');
    if (data is List) {
      return data
          .map((e) => HighlightItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getHighlightEngagement(String highlightId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/engagement',
      ),
      headers: headers,
    );
    return _decode(resp, 'Failed to load engagement') as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getHighlightComments(
    String highlightId,
  ) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/comments',
      ),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load comments');
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> postHighlightComment(
    String highlightId,
    String body, {
    String? parentCommentId,
  }) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/comments',
      ),
      headers: headers,
      body: jsonEncode({
        'body': body,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      }),
    );
    return _decode(resp, 'Failed to post comment') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> likeHighlight(String highlightId) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/like',
      ),
      headers: headers,
    );
    return _decode(resp, 'Failed to like') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlikeHighlight(String highlightId) async {
    final headers = await _authHeaders();
    final resp = await http.delete(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/like',
      ),
      headers: headers,
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {'liked': false};
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
      return {'liked': false};
    }
    throw Exception('Failed to unlike');
  }

  Future<Map<String, dynamic>> saveHighlight(String highlightId) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/save',
      ),
      headers: headers,
    );
    return _decode(resp, 'Failed to save') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unsaveHighlight(String highlightId) async {
    final headers = await _authHeaders();
    final resp = await http.delete(
      Uri.parse(
        '$baseUrl/api/highlights/${Uri.encodeComponent(highlightId)}/save',
      ),
      headers: headers,
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {'saved': false};
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
      return {'saved': false};
    }
    throw Exception('Failed to unsave');
  }

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  // ── Rank progression ──────────────────────────────────────────────────────

  Future<List<RankEntry>> getPlayerRanks(String playerUserId) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/api/rank/user/$playerUserId/all'),
      headers: headers,
    );
    final data = _decode(resp, 'Failed to load ranks');
    if (data is List) {
      return data
          .map((e) => RankEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Watchlist check ───────────────────────────────────────────────────────

  Future<bool> checkWatchlist({
    required String scouterId,
    required String playerId,
  }) async {
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse(
          '$baseUrl/api/scouting/watchlist/check?scouterId=$scouterId&playerId=$playerId'),
      headers: headers,
    );
    if (resp.statusCode == 404) return false;
    final data = _decode(resp, 'Failed to check watchlist');
    if (data is Map) {
      return (data['onWatchlist'] ?? data['found'] ?? data['exists'] ?? false) == true;
    }
    return false;
  }
}
