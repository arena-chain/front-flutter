import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/api/video_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/models/video_model.dart';

/// Full state for the Player Detail screen.
class ScouterPlayerDetailViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final VideoApi _videoApi = VideoApi();
  final String scouterId;

  ScouterPlayerDetailViewModel({
    required this.scouterId,
    ScouterRepository? repo,
    PlayerDetail? initialPlayer,
  }) : _repo = repo ?? ScouterRepository() {
    if (initialPlayer != null) {
      playerIdentity = initialPlayer;
    }
  }

  bool isLoading = false;
  String? error;

  PlayerDetail? player;
  PlayerDetail? playerIdentity;  // identity enrichment from /scouter/players list
  List<MatchSummary> matches = [];
  List<ScoutingReport> reports = [];
  ProspectStatus? prospect;
  List<Recommendation> recommendations = [];
  List<HighlightItem> highlights = [];
  List<RankEntry> ranks = [];
  bool isOnWatchlist = false;

  // Derived helpers: prefer identity fields when available
  String get displayNickname =>
      playerIdentity?.nickname.isNotEmpty == true
          ? playerIdentity!.nickname
          : (player?.nickname ?? 'Unknown');

  String? get displayAvatar =>
      playerIdentity?.avatar ?? player?.avatar;

  String get displayCountry =>
      playerIdentity?.country.isNotEmpty == true &&
              playerIdentity?.country != 'Unknown'
          ? playerIdentity!.country
          : (player?.country ?? '');

  // Prospect editing state
  String selectedProspectLevel = 'UNKNOWN';
  String selectedPriority = 'MEDIUM';

  bool isSavingProspect = false;
  bool isAddingToEvaluated = false;
  String? actionSuccess;

  // Safe wrapper — never throws; returns fallback on error
  Future<T> _safe<T>(Future<T> fn, T fallback) async {
    try {
      return await fn;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> loadPlayer(String playerUserId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Core data — these drive the primary content
      final coreResults = await Future.wait([
        _repo.getPlayerDetail(playerUserId),
        _repo.getPlayerMatches(playerUserId),
        _repo.getPlayerReports(playerUserId),
        _repo.getPlayerProspect(playerUserId),
        _repo.getPlayerRecommendations(playerUserId),
      ]);

      player = coreResults[0] as PlayerDetail;
      matches = coreResults[1] as List<MatchSummary>;
      reports = coreResults[2] as List<ScoutingReport>;
      prospect = coreResults[3] as ProspectStatus?;
      recommendations = coreResults[4] as List<Recommendation>;

      if (prospect != null) {
        selectedProspectLevel = prospect!.prospectLevel;
        selectedPriority = prospect!.priority ?? 'MEDIUM';
      }

      // Extract the User._id from the loaded profile (needed for highlights/ranks)
      final userObjectId = player!.effectiveUserId;

      // Enrichment — best-effort, never fails the load
      final enrichResults = await Future.wait([
        _safe(_repo.getPlayers(), <PlayerDetail>[]),
        _safe(_repo.getHighlights(), <HighlightItem>[]),
        _safe(
          userObjectId.isNotEmpty
              ? _repo.getPlayerRanks(userObjectId)
              : Future.value(<RankEntry>[]),
          <RankEntry>[],
        ),
        _safe(
          _repo.checkWatchlist(scouterId: scouterId, playerId: playerUserId),
          false,
        ),
      ]);

      // Identity enrichment: find the player in the list by profileId OR userId
      final allPlayers = enrichResults[0] as List<PlayerDetail>;
      playerIdentity = allPlayers.cast<PlayerDetail?>().firstWhere(
        (p) => p != null && (p.id == playerUserId || p.effectiveUserId == userObjectId),
        orElse: () => null,
      );

      // Filter highlights client-side: creator._id matches User._id
      final allHighlights = enrichResults[1] as List<HighlightItem>;
      final List<HighlightItem> filteredHighlights = userObjectId.isNotEmpty
          ? allHighlights.where((h) => h.creatorId == userObjectId).toList()
          : <HighlightItem>[];

      // Fallback: if dedicated highlights are empty, use uploaded videos for that player.
      if (filteredHighlights.isEmpty) {
        final uploadedVideos = await _safe(_videoApi.getVideos(), <Video>[]);
        final playerNickname = (player?.nickname ?? playerIdentity?.nickname ?? '').toLowerCase();
        final candidateIds = <String>{
          playerUserId,
          player?.id ?? '',
          playerIdentity?.id ?? '',
          player?.effectiveUserId ?? '',
          playerIdentity?.effectiveUserId ?? '',
          userObjectId,
        }.where((id) => id.isNotEmpty).toSet();

        final linkedVideos = uploadedVideos.where((video) {
          final uploaderId = video.uploaderId ?? '';
          if (uploaderId.isNotEmpty && candidateIds.contains(uploaderId)) return true;
          final uploaderName = (video.uploaderNickname ?? '').toLowerCase();
          if (playerNickname.isNotEmpty && uploaderName == playerNickname) return true;
          return false;
        }).toList();

        if (linkedVideos.isEmpty) {
          highlights = <HighlightItem>[];
        } else {
          highlights = linkedVideos.map((video) {
            return HighlightItem.fromJson({
              '_id': video.id,
              'title': video.title,
              'videoUrl': video.videoUrl,
              'thumbnailUrl': video.thumbnailUrl,
              'creator': video.uploaderId ?? userObjectId,
              'video': {
                'title': video.title,
                'url': video.videoUrl,
                'thumbnailUrl': video.thumbnailUrl,
                'duration': video.duration?.toString(),
              },
            });
          }).toList();
        }
      } else {
        highlights = filteredHighlights;
      }

      ranks = enrichResults[2] as List<RankEntry>;
      isOnWatchlist = enrichResults[3] as bool;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToEvaluated(String playerProfileId) async {
    isAddingToEvaluated = true;
    actionSuccess = null;
    notifyListeners();
    try {
      await _repo.addToEvaluated(scouterId, playerProfileId);
      actionSuccess = 'Player added to your evaluated list!';
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isAddingToEvaluated = false;
      notifyListeners();
    }
  }

  Future<void> saveProspect(String playerId) async {
    isSavingProspect = true;
    actionSuccess = null;
    notifyListeners();
    try {
      prospect = await _repo.upsertProspect({
        'scouterId': scouterId,
        'playerId': playerId,
        'playerNickname': player?.nickname,
        'prospectLevel': selectedProspectLevel,
        'priority': selectedPriority,
      });
      actionSuccess = 'Prospect status saved!';
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isSavingProspect = false;
      notifyListeners();
    }
  }

  Future<void> createReport(Map<String, dynamic> body) async {
    try {
      final r = await _repo.createReport(body);
      reports = [r, ...reports];
      actionSuccess = 'Report created!';
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> createRecommendation(Map<String, dynamic> body) async {
    try {
      final r = await _repo.createRecommendation(body);
      recommendations = [r, ...recommendations];
      actionSuccess = 'Recommendation sent!';
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void clearAction() {
    actionSuccess = null;
    error = null;
    notifyListeners();
  }
}
