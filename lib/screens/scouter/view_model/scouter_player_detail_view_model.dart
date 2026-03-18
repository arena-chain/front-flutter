import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Full state for the Player Detail screen.
class ScouterPlayerDetailViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterPlayerDetailViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;

  PlayerDetail? player;
  List<MatchSummary> matches = [];
  List<ScoutingReport> reports = [];
  ProspectStatus? prospect;
  List<Recommendation> recommendations = [];

  // Prospect editing state
  String selectedProspectLevel = 'UNKNOWN';
  String selectedPriority = 'MEDIUM';

  bool isSavingProspect = false;
  bool isAddingToEvaluated = false;
  String? actionSuccess;

  Future<void> loadPlayer(String playerUserId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getPlayerDetail(playerUserId),
        _repo.getPlayerMatches(playerUserId),
        _repo.getPlayerReports(playerUserId),
        _repo.getPlayerProspect(playerUserId),
        _repo.getPlayerRecommendations(playerUserId),
      ]);

      player = results[0] as PlayerDetail;
      matches = results[1] as List<MatchSummary>;
      reports = results[2] as List<ScoutingReport>;
      prospect = results[3] as ProspectStatus?;
      recommendations = results[4] as List<Recommendation>;

      if (prospect != null) {
        selectedProspectLevel = prospect!.prospectLevel;
        selectedPriority = prospect!.priority ?? 'MEDIUM';
      }
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
        'playerNickname': player?.userId?.nickname,
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
