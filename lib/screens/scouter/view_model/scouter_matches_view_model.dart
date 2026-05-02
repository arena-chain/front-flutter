import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/api/feature_leagues/leagues_api.dart';
import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Combines (1) matches for the scouter's evaluated players and (2) schedule
/// from public leagues (ongoing season when available). Deduplicated by match id.
class ScouterMatchesViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterMatchesViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? error;

  List<MatchSummary> allMatches = [];

  /// Filter the current sub-tab: 'LIVE' | 'TODAY' | 'UPCOMING' | 'RESULTS'
  String activeFilter = 'RESULTS';

  Future<void> loadMatches() async {
    if (scouterId.isEmpty) return;
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final fromPlayers = _loadMatchesFromEvaluatedPlayers();
      final fromLeagues = _loadMatchesFromLeagues();
      final lists = await Future.wait([fromPlayers, fromLeagues]);
      final seen = <String>{};
      final flat = <MatchSummary>[];
      for (final m in lists.expand((e) => e)) {
        if (m.id.isEmpty) continue;
        if (seen.add(m.id)) flat.add(m);
      }
      flat.sort((a, b) =>
          (b.scheduledStart ?? '').compareTo(a.scheduledStart ?? ''));
      allMatches = flat;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      hasLoadedOnce = true;
      notifyListeners();
    }
  }

  Future<List<MatchSummary>> _loadMatchesFromEvaluatedPlayers() async {
    try {
      final profile = await _repo
          .getScouterProfile(scouterId)
          .timeout(const Duration(seconds: 5));
      final playerIds = profile.evaluatedPlayerIds.take(4).toList();
      if (playerIds.isEmpty) return [];
      final results = await Future.wait(
        playerIds.map((id) async {
          try {
            return await _repo
                .getPlayerMatches(id)
                .timeout(const Duration(seconds: 4));
          } catch (_) {
            return <MatchSummary>[];
          }
        }),
      );
      final seen = <String>{};
      final flat = <MatchSummary>[];
      for (final list in results) {
        for (final m in list) {
          if (seen.add(m.id)) flat.add(m);
        }
      }
      return flat;
    } catch (_) {
      return [];
    }
  }

  Future<List<MatchSummary>> _loadMatchesFromLeagues() async {
    try {
      final api = LeaguesApi();
      final leagues = await api.getLeagues();
      if (leagues.isEmpty) return [];
      final capped = leagues.take(5).toList();
      const t = Duration(seconds: 6);
      final perLeague = await Future.wait(
        capped.map((lg) async {
          try {
            final seasons = await api.getSeasons(lg.id).timeout(t);
            if (seasons.isEmpty) return <MatchSummary>[];
            final ongoing =
                seasons.where((s) => s.status.toUpperCase() == 'ONGOING');
            final season =
                ongoing.isNotEmpty ? ongoing.first : seasons.first;
            final items = await api.getMatches(season.id).timeout(t);
            return items.map(_leagueMatchToSummary).toList();
          } catch (_) {
            return <MatchSummary>[];
          }
        }),
      );
      return perLeague.expand((e) => e).toList();
    } catch (_) {
      return [];
    }
  }

  /// Map leagues API match rows into [MatchSummary] with statuses the filters understand.
  MatchSummary _leagueMatchToSummary(MatchItem m) {
    final map = Map<String, dynamic>.from(m.raw);
    final s = m.status.toUpperCase();
    if (s == 'ONGOING') {
      map['status'] = 'LIVE';
    } else if (s == 'FORFEIT') {
      map['status'] = 'COMPLETED';
    }
    return MatchSummary(id: m.id, raw: map);
  }

  void setFilter(String f) {
    activeFilter = f;
    notifyListeners();
  }

  List<MatchSummary> get filtered {
    if (allMatches.isEmpty) return [];
    final now = DateTime.now();
    return allMatches.where((m) {
      final status = (m.status ?? '').toUpperCase();
      final dt = m.scheduledStart != null
          ? DateTime.tryParse(m.scheduledStart!)
          : null;

      switch (activeFilter) {
        case 'LIVE':
          return status == 'LIVE' ||
              status == 'IN_PROGRESS' ||
              status == 'ONGOING';
        case 'TODAY':
          if (dt == null) return false;
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        case 'UPCOMING':
          if (dt == null) return false;
          return dt.isAfter(now) &&
              !(dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day);
        case 'RESULTS':
        default:
          return status == 'COMPLETED' ||
              status == 'FINISHED' ||
              status == 'DONE' ||
              status == 'FORFEIT' ||
              (dt != null && dt.isBefore(now));
      }
    }).toList();
  }
}
