import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';

class ScouterRecommendationsViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterRecommendationsViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;
  List<Recommendation> recommendations = [];

  Future<void> loadRecommendations() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _repo.getMyRecommendations(scouterId);
      // Enrich with real nicknames from the players directory
      recommendations = await _enrichNicknames(raw);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Recommendation>> _enrichNicknames(List<Recommendation> recs) async {
    if (recs.isEmpty) return recs;
    try {
      final byId = <String, String>{};

      // Source 1: merged players directory
      try {
        final players = await PlayersDirectoryApi().getPlayers();
        for (final p in players) {
          final nick = p.nickname;
          if (nick.isEmpty || nick == 'Unknown') continue;
          if (p.id.isNotEmpty) byId[p.id] = nick;
          final uid = p.effectiveUserId;
          if (uid.isNotEmpty) byId[uid] = nick;
        }
      } catch (_) {}

      // Source 2: raw scouter profiles (userId may be populated with user object)
      try {
        final profiles = await PlayersDirectoryApi().getRawProfiles();
        for (final p in profiles) {
          final nick = (p['nickname'] ?? p['displayName'] ?? '').toString();
          final pid = (p['_id'] ?? p['id'] ?? '').toString();
          if (pid.isNotEmpty && nick.isNotEmpty) byId[pid] = nick;
          final uid = p['userId'];
          if (uid is Map) {
            final uidStr = (uid['_id'] ?? uid['id'] ?? '').toString();
            final userNick = (uid['nickname'] ?? uid['displayName'] ?? uid['username'] ?? '').toString();
            if (uidStr.isNotEmpty) byId[uidStr] = userNick.isNotEmpty ? userNick : nick;
            if (pid.isNotEmpty && userNick.isNotEmpty) byId[pid] = userNick;
          } else if (uid is String && uid.isNotEmpty && nick.isNotEmpty) {
            byId[uid] = nick;
          }
        }
      } catch (_) {}

      return recs.map((r) {
        final pid = r.playerIdStr;
        final found = byId[pid];
        if (found == null || found.isEmpty) return r;
        final enriched = Map<String, dynamic>.from(r.raw);
        enriched['playerNickname'] = found;
        return Recommendation(id: r.id, raw: enriched);
      }).toList();
    } catch (_) {
      return recs;
    }
  }
}
