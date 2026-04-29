import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Handles the leaderboard/players tab: game list + leaderboard + filter.
class ScouterPlayersViewModel extends ChangeNotifier {
  final ScouterRepository _repo;

  ScouterPlayersViewModel({ScouterRepository? repo})
      : _repo = repo ?? ScouterRepository();

  // Games catalog
  List<GameModel> games = [];
  String? selectedGameId;

  // Leaderboard
  bool isLoadingLeaderboard = false;
  List<LeaderboardEntry> leaderboard = [];
  String? leaderboardError;

  // Filter
  bool isFiltering = false;
  List<PlayerDetail> filterResults = [];
  String? filterError;

  // Filter params
  String? filterTier;
  String? filterCountry;
  bool? filterHasTeam;
  String? filterProspectLevel;
  String? filterPriority;
  bool showFilterResults = false;

  Future<void> loadGames() async {
    try {
      games = await _repo.getCatalog();
      if (games.isNotEmpty && selectedGameId == null) {
        selectedGameId = games.first.id;
        await loadLeaderboard();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectGame(String gameId) async {
    selectedGameId = gameId;
    showFilterResults = false;
    notifyListeners();
    await loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    if (selectedGameId == null) return;
    isLoadingLeaderboard = true;
    leaderboardError = null;
    notifyListeners();
    try {
      leaderboard = await _repo.getLeaderboard(selectedGameId!);
    } catch (e) {
      leaderboardError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter() async {
    isFiltering = true;
    filterError = null;
    showFilterResults = true;
    notifyListeners();
    try {
      filterResults = await _repo.filterPlayers(
        gameId: selectedGameId,
        tier: filterTier,
        country: filterCountry,
        hasTeam: filterHasTeam,
        prospectLevel: filterProspectLevel,
        priority: filterPriority,
      );
    } catch (e) {
      filterError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }

  void resetFilter() {
    filterTier = null;
    filterCountry = null;
    filterHasTeam = null;
    filterProspectLevel = null;
    filterPriority = null;
    showFilterResults = false;
    filterResults = [];
    notifyListeners();
  }
}
