import 'package:arena_chain_flutter/core/api/feature_scouter/scouter_api.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/storage/local_scouting_storage.dart';
import 'package:arena_chain_flutter/core/utils/highlight_ranking.dart';

/// Repository layer – delegates to ScouterApi, falls back to local storage when API fails.
class ScouterRepository {
  final ScouterApi _api;
  final LocalScoutingStorage _local;

  ScouterRepository({
    ScouterApi? api,
    LocalScoutingStorage? local,
  })  : _api = api ?? ScouterApi(),
        _local = local ?? LocalScoutingStorage();

  Future<List<GameModel>> getCatalog() => _api.getCatalog();

  Future<ScouterProfile> getScouterProfile(String userId) =>
      _api.getScouterProfile(userId);

  Future<List<PlayerDetail>> getPlayers() => _api.getPlayers();
  Future<PlayerDetail> getPlayerDetail(String id) async {
    try {
      return await _api.getPlayerDetail(id);
    } catch (_) {
      return PlayerDetail.fromJson({'_id': id, 'userId': id});
    }
  }
  Future<List<MatchSummary>> getPlayerMatches(String id) async {
    try {
      return await _api.getPlayerMatches(id);
    } catch (_) {
      return [];
    }
  }
  Future<List<LeaderboardEntry>> getLeaderboard(String gameId) async {
    try {
      return await _api.getLeaderboard(gameId);
    } catch (_) {
      // Fallback: build leaderboard from the working players directory
      try {
        final players = await PlayersDirectoryApi().getPlayers();
        return players.map((p) => LeaderboardEntry.fromJson({
          '_id': p.id,
          'elo': p.elo,
          'tier': p.raw['tier'] ?? p.raw['rank'] ?? 'UNRANKED',
          'rank': p.raw['rank'] ?? p.raw['tier'] ?? 'UNRANKED',
          'user': {
            '_id': p.raw['userId'] ?? p.id,
            'nickname': p.nickname,
            'avatar': p.avatar,
            'country': p.raw['country'],
          },
        })).toList();
      } catch (_) {
        return [];
      }
    }
  }
  Future<void> addToEvaluated(String scouterUserId, String playerProfileId) =>
      _api.addToEvaluated(scouterUserId, playerProfileId);
  Future<List<PlayerDetail>> filterPlayers({
    String? gameId,
    String? tier,
    String? country,
    bool? hasTeam,
    String? prospectLevel,
    String? priority,
  }) =>
      _api.filterPlayers(
        gameId: gameId,
        tier: tier,
        country: country,
        hasTeam: hasTeam,
        prospectLevel: prospectLevel,
        priority: priority,
      );

  Future<List<ScoutingReport>> getMyReports(String scouterId) async {
    try {
      return await _api.getMyReports(scouterId);
    } catch (_) {
      return _local.getReports(scouterId);
    }
  }

  Future<List<ScoutingReport>> getPlayerReports(String playerId) async {
    try {
      return await _api.getPlayerReports(playerId);
    } catch (_) {
      return _local.getReportsForPlayer(playerId);
    }
  }

  Future<ScoutingReport> createReport(Map<String, dynamic> body) async {
    try {
      return await _api.createReport(body);
    } catch (_) {
      return _local.addReport(body);
    }
  }

  Future<ScoutingReport> updateReport(String id, Map<String, dynamic> body) async {
    try {
      return await _api.updateReport(id, body);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _api.deleteReport(id);
    } catch (_) {
      if (id.startsWith('local_')) {
        await _local.deleteReport(id);
      } else {
        rethrow;
      }
    }
  }

  Future<List<ProspectStatus>> getProspects({
    String? prospectLevel,
    String? priority,
  }) async {
    try {
      return await _api.getProspects(
        prospectLevel: prospectLevel,
        priority: priority,
      );
    } catch (_) {
      var list = await _local.getProspects();
      if (prospectLevel != null) {
        final level = prospectLevel == 'ELITE' ? 'ELITE_PROSPECT' : prospectLevel;
        list = list.where((p) => p.prospectLevel.toUpperCase() == level).toList();
      }
      if (priority != null) {
        list = list.where((p) => (p.priority ?? '').toUpperCase() == priority).toList();
      }
      return list;
    }
  }

  Future<ProspectStatus?> getPlayerProspect(String playerId) async {
    try {
      return await _api.getPlayerProspect(playerId);
    } catch (_) {
      final all = await _local.getProspects();
      try {
        return all.firstWhere((p) => p.playerId == playerId);
      } catch (_) {
        return null;
      }
    }
  }

  Future<ProspectStatus> upsertProspect(Map<String, dynamic> body) async {
    try {
      return await _api.upsertProspect(body);
    } catch (_) {
      final nickname = body['playerNickname'] as String?;
      return _local.upsertProspect(body, nickname);
    }
  }

  Future<List<Recommendation>> getMyRecommendations(String scouterId) =>
      _api.getMyRecommendations(scouterId);
  Future<List<Recommendation>> getPlayerRecommendations(String playerId) =>
      _api.getPlayerRecommendations(playerId);
  Future<Recommendation> createRecommendation(Map<String, dynamic> body) =>
      _api.createRecommendation(body);

  Future<List<HighlightItem>> getHighlights() async {
    try {
      return await _api.getHighlights();
    } catch (_) {
      return [];
    }
  }

  Future<List<HighlightItem>> getPublicHighlights() async {
    try {
      return await _api.getPublicHighlights();
    } catch (_) {
      return [];
    }
  }

  /// Top [limit] public clips by reactions (for scouter home feed).
  Future<List<HighlightItem>> getRankedPublicHighlights({int limit = 20}) async {
    try {
      final list = await _api.getPublicHighlights();
      final ranked = await rankHighlightsByEngagement(_api, list);
      if (ranked.length <= limit) return ranked;
      return ranked.sublist(0, limit);
    } catch (_) {
      return [];
    }
  }

  Future<List<HighlightItem>> getHighlightsForVideo(
    String videoId, {
    bool publicOnly = false,
  }) async {
    try {
      return await _api.getHighlightsForVideo(videoId, publicOnly: publicOnly);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getHighlightEngagement(String id) =>
      _api.getHighlightEngagement(id);

  Future<List<Map<String, dynamic>>> getHighlightComments(String id) =>
      _api.getHighlightComments(id);

  Future<Map<String, dynamic>> postHighlightComment(
    String id,
    String body, {
    String? parentCommentId,
  }) =>
      _api.postHighlightComment(id, body, parentCommentId: parentCommentId);

  Future<Map<String, dynamic>> likeHighlight(String id) => _api.likeHighlight(id);

  Future<Map<String, dynamic>> unlikeHighlight(String id) =>
      _api.unlikeHighlight(id);

  Future<Map<String, dynamic>> saveHighlight(String id) =>
      _api.saveHighlight(id);

  Future<Map<String, dynamic>> unsaveHighlight(String id) =>
      _api.unsaveHighlight(id);

  Future<List<HighlightItem>> rankHighlights(List<HighlightItem> items) =>
      rankHighlightsByEngagement(_api, items);

  Future<List<RankEntry>> getPlayerRanks(String playerUserId) async {
    try {
      return await _api.getPlayerRanks(playerUserId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> checkWatchlist({
    required String scouterId,
    required String playerId,
  }) async {
    try {
      return await _api.checkWatchlist(scouterId: scouterId, playerId: playerId);
    } catch (_) {
      return false;
    }
  }
}
