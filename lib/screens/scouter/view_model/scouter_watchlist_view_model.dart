import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';

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
      final raw = await _repo.getProspects();
      allProspects = await _enrichNicknames(raw);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ProspectStatus>> _enrichNicknames(List<ProspectStatus> prospects) async {
    if (prospects.isEmpty) return prospects;
    try {
      final byId = <String, String>{};

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

      return prospects.map((p) {
        if (p.playerNickname != null && p.playerNickname!.isNotEmpty) return p;
        final pid = p.playerId;
        final found = byId[pid];
        if (found == null || found.isEmpty) return p;
        final enriched = Map<String, dynamic>.from(p.raw);
        // Store under the 'playerId' map key so the getter picks it up,
        // or inject directly as a helper key
        enriched['_enrichedNickname'] = found;
        return ProspectStatus(id: p.id, raw: enriched);
      }).toList();
    } catch (_) {
      return prospects;
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
