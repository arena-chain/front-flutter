import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Dashboard stats + recent data for the scouter home tab.
class ScouterHomeViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterHomeViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;

  int playerCount = 0;
  int reportCount = 0;
  int prospectCount = 0;
  int recommendationCount = 0;
  String scouterLevel = 'REGIONAL';

  List<ScoutingReport> recentReports = [];

  Future<void> loadDashboard() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getPlayers(),
        _repo.getMyReports(scouterId),
        _repo.getProspects(),
        _repo.getMyRecommendations(scouterId),
      ]);

      playerCount = (results[0] as List).length;
      final reports = results[1] as List<ScoutingReport>;
      reportCount = reports.length;
      recentReports = reports.take(3).toList();
      prospectCount = (results[2] as List).length;
      recommendationCount = (results[3] as List).length;

      try {
        final profile = await _repo.getScouterProfile(scouterId);
        scouterLevel = profile.level;
      } catch (_) {}
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
