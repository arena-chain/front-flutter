import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';
import 'dart:async';

class ScouterWatchlistViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterWatchlistViewModel({
    this.scouterId = '',
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? error;
  bool _loadInFlight = false;

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

  Future<void> loadWatchlist({bool refresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    final blockFullSpinner = !refresh && allProspects.isEmpty;
    if (blockFullSpinner) {
      isLoading = true;
      error = null;
      notifyListeners();
    } else if (refresh) {
      error = null;
    }
    try {
      final raw = await _repo
          .getProspects()
          .timeout(const Duration(seconds: 12));
      allProspects = raw;
      unawaited(_enrichAndApply(raw));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      hasLoadedOnce = true;
      _loadInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _enrichAndApply(List<ProspectStatus> raw) async {
    final enriched = await _enrichNicknames(raw);
    if (identical(enriched, raw)) return;
    allProspects = enriched;
    notifyListeners();
  }

  Future<List<ProspectStatus>> _enrichNicknames(List<ProspectStatus> prospects) async {
    if (prospects.isEmpty) return prospects;
    try {
      final byId = <String, String>{};
      final profileByKey = <String, PlayerDetail>{};

      try {
        final players = await PlayersDirectoryApi()
            .getPlayers()
            .timeout(const Duration(seconds: 4));
        for (final p in players) {
          final nick = p.nickname;
          if (nick.isNotEmpty && nick != 'Unknown') {
            if (p.id.isNotEmpty) byId[p.id] = nick;
            final uid = p.effectiveUserId;
            if (uid.isNotEmpty) byId[uid] = nick;
          }
          if (p.id.isNotEmpty) profileByKey[p.id] = p;
          final uid = p.effectiveUserId;
          if (uid.isNotEmpty) profileByKey[uid] = p;
        }
      } catch (_) {}

      try {
        final profiles = await PlayersDirectoryApi()
            .getRawProfiles()
            .timeout(const Duration(seconds: 4));
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
        final hasNick =
            p.playerNickname != null && p.playerNickname!.isNotEmpty;
        String? foundNick = hasNick ? p.playerNickname : null;
        if (!hasNick) {
          for (final key in _nicknameLookupKeys(p)) {
            final v = byId[key];
            if (v != null && v.isNotEmpty) {
              foundNick = v;
              break;
            }
          }
        }

        PlayerDetail? match;
        for (final key in _nicknameLookupKeys(p)) {
          match = profileByKey[key];
          if (match != null) break;
        }

        if (!hasNick && foundNick == null && match == null) return p;

        final enriched = Map<String, dynamic>.from(p.raw);
        if (match != null) {
          enriched['_enrichedProfile'] = {
            'nickname': match.nickname,
            'email': match.email,
            'avatar': match.avatar,
            'elo': match.elo,
            'rank': match.rank,
            'country': match.country,
          };
        }
        if (!hasNick) {
          final nick = foundNick ??
              (match != null &&
                      match.nickname.isNotEmpty &&
                      match.nickname != 'Unknown'
                  ? match.nickname
                  : null);
          if (nick != null && nick.isNotEmpty) {
            enriched['_enrichedNickname'] = nick;
          }
        }
        if (!enriched.containsKey('_enrichedProfile') &&
            !enriched.containsKey('_enrichedNickname')) {
          return p;
        }
        return ProspectStatus(id: p.id, raw: enriched);
      }).toList();
    } catch (_) {
      return prospects;
    }
  }

  /// Ids to match against the merged players directory (profile id, user id, doc id).
  static List<String> _nicknameLookupKeys(ProspectStatus p) {
    final keys = <String>{};
    void add(String? s) {
      if (s == null || s.isEmpty) return;
      keys.add(s);
    }

    add(p.playerId);
    add(p.id);
    final rawPid = p.raw['playerId'];
    if (rawPid is Map) {
      add((rawPid['_id'] ?? rawPid['id'])?.toString());
      final u = rawPid['userId'];
      if (u is Map) {
        add((u['_id'] ?? u['id'])?.toString());
      } else if (u is String) {
        add(u);
      }
    }
    return keys.toList();
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
