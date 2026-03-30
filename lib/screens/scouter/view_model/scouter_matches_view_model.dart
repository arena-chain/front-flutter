import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Groups matches fetched for the evaluated players of the current scouter.
/// Since there's no global "all matches" endpoint, we fetch matches for the
/// scouter's profile's evaluatedPlayerIds (first 10 to avoid over-fetching).
class ScouterMatchesViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterMatchesViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;

  List<MatchSummary> allMatches = [];

  /// Filter the current sub-tab: 'LIVE' | 'TODAY' | 'UPCOMING' | 'RESULTS'
  String activeFilter = 'RESULTS';

  Future<void> loadMatches() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Try to load scouter profile to get evaluated player IDs.
      // If the backend endpoint doesn't exist yet, just show empty.
      List<String> playerIds = [];
      try {
        final profile = await _repo.getScouterProfile(scouterId);
        playerIds = profile.evaluatedPlayerIds.take(10).toList();
      } catch (_) {
        // Endpoint not available yet — show empty matches list gracefully
        allMatches = [];
        return;
      }

      if (playerIds.isEmpty) {
        allMatches = [];
      } else {
        final results = await Future.wait(
          playerIds.map((id) => _repo.getPlayerMatches(id)),
        );
        // Flatten and deduplicate by match id
        final seen = <String>{};
        final flat = <MatchSummary>[];
        for (final list in results) {
          for (final m in list) {
            if (seen.add(m.id)) flat.add(m);
          }
        }
        // Sort newest first
        flat.sort((a, b) =>
            (b.scheduledStart ?? '').compareTo(a.scheduledStart ?? ''));
        allMatches = flat;
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
          return status == 'LIVE' || status == 'IN_PROGRESS';
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
              (dt != null && dt.isBefore(now));
      }
    }).toList();
  }
}
