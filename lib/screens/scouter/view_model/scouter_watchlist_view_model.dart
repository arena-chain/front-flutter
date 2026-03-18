import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterWatchlistViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterWatchlistViewModel({
    this.scouterId = '',
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;

  // All prospects cached for every level
  List<ProspectStatus> allProspects = [];

  String activeLevel = 'WATCHLIST';

  static const levels = ['WATCHLIST', 'PROSPECT', 'ELITE', 'SIGNED'];

  // Map API values to display-friendly level names
  static const _apiLevelMap = {
    'WATCHLIST': 'WATCHLIST',
    'PROSPECT': 'PROSPECT',
    'ELITE': 'ELITE_PROSPECT',
    'SIGNED': 'SIGNED',
  };

  Future<void> loadWatchlist() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Load all prospects (no level filter) and cache
      allProspects = await _repo.getProspects();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setLevel(String level) {
    activeLevel = level;
    notifyListeners();
  }

  List<ProspectStatus> get filtered {
    final api = _apiLevelMap[activeLevel] ?? activeLevel;
    return allProspects
        .where((p) => p.prospectLevel.toUpperCase() == api)
        .toList();
  }

  Future<void> changeLevel(String playerId, String newLevel) async {
    final api = _apiLevelMap[newLevel] ?? newLevel;
    try {
      final body = <String, dynamic>{
        'playerId': playerId,
        'prospectLevel': api,
        'priority': 'MEDIUM',
      };
      if (scouterId.isNotEmpty) body['scouterId'] = scouterId;
      final updated = await _repo.upsertProspect(body);
      // Replace in list
      final idx = allProspects.indexWhere((p) => p.playerId == playerId);
      if (idx >= 0) {
        allProspects[idx] = updated;
      } else {
        allProspects.add(updated);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeFromWatchlist(String playerId) async {
    try {
      final body = <String, dynamic>{
        'playerId': playerId,
        'prospectLevel': 'UNKNOWN',
        'priority': 'LOW',
      };
      if (scouterId.isNotEmpty) body['scouterId'] = scouterId;
      await _repo.upsertProspect(body);
      allProspects.removeWhere((p) => p.playerId == playerId);
      notifyListeners();
    } catch (_) {}
  }
}
