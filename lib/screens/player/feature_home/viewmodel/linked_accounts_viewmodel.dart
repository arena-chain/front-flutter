import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/steam/steam_api.dart';
import 'package:arena_chain_flutter/core/models/linked_accounts/linked_game_account.dart';
import 'package:arena_chain_flutter/core/models/rank_model.dart';

bool _riotVerified(Map<String, dynamic> s) {
  final v = s['status'] ?? s['riotLinkStatus'];
  return v != null && v.toString().toLowerCase() == 'verified';
}

bool _steamVerified(Map<String, dynamic> s) {
  final v = s['steamVerified'] ?? s['steam_verified'];
  if (v == true) return true;
  if (v == false || v == null) return false;
  return v.toString().toLowerCase() == 'true';
}

String _rankGameLabel(dynamic game) {
  if (game == null) return '';
  if (game is String) return game;
  if (game is Map) {
    return (game['title'] ?? game['name'] ?? game['_id'] ?? '').toString();
  }
  return game.toString();
}

Rank? _rankForLol(List<Rank> ranks) {
  for (final r in ranks) {
    final g = _rankGameLabel(r.game).toLowerCase();
    if (g.contains('lol') ||
        g.contains('league') ||
        g.contains('legends') ||
        g == 'lol') {
      return r;
    }
  }
  return null;
}

Rank? _rankForValorant(List<Rank> ranks) {
  for (final r in ranks) {
    final g = _rankGameLabel(r.game).toLowerCase();
    if (g.contains('valorant') || g.contains('val ') || g == 'val') {
      return r;
    }
  }
  return null;
}

String _winPct(Rank? r) {
  if (r == null) return '--';
  final wins = r.wins;
  final losses = r.losses;
  final t = wins + losses;
  if (t == 0) return '--';
  return '${((wins / t) * 100).round()}%';
}

String? _rankTierLabel(Rank? r) {
  if (r == null) return null;
  final t = r.tier.trim();
  if (t.isEmpty || t.toLowerCase() == 'unranked') return null;
  return t;
}

/// Parses `kda` like `2.41:1` from LoL-style rows or Val rows from our API.
double? _parseKdaRatio(dynamic kdaField) {
  final s = kdaField?.toString();
  if (s == null || s.isEmpty) return null;
  final head = s.split(':').first.trim();
  return double.tryParse(head);
}

({String kd, String win}) _aggregateFromMatches(List<dynamic> matches) {
  if (matches.isEmpty) return (kd: '--', win: '--');
  var sum = 0.0;
  var n = 0;
  var wins = 0;
  for (final raw in matches) {
    if (raw is! Map) continue;
    final k = _parseKdaRatio(raw['kda']);
    if (k != null) {
      sum += k;
      n++;
    }
    if (raw['win'] == true) wins++;
  }
  final kd = n == 0 ? '--' : (sum / n).toStringAsFixed(2);
  final win = matches.isEmpty
      ? '--'
      : '${((wins / matches.length) * 100).round()}%';
  return (kd: kd, win: win);
}

class LinkedAccountsViewModel extends ChangeNotifier {
  final RiotApi _riot = RiotApi();
  final SteamApi _steam = SteamApi();
  final TokenStorage _tokens = TokenStorage();

  List<LinkedGameAccount> _accounts = [];
  bool _loading = false;
  String? _error;
  Map<String, dynamic> _lastRiotStatus = {};
  Map<String, dynamic> _lastSteamStatus = {};

  List<LinkedGameAccount> get accounts => _accounts;
  bool get isLoading => _loading;
  String? get error => _error;
  Map<String, dynamic> get lastRiotStatus => Map.unmodifiable(_lastRiotStatus);
  Map<String, dynamic> get lastSteamStatus =>
      Map.unmodifiable(_lastSteamStatus);

  bool get riotVerified => _riotVerified(_lastRiotStatus);
  bool get steamVerified => _steamVerified(_lastSteamStatus);

  Future<void> refresh({List<Rank> platformRanks = const []}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _tokens.getAccessToken();
      if (token == null) {
        _accounts = [];
        _lastRiotStatus = {};
        _lastSteamStatus = {};
        return;
      }

      Map<String, dynamic> riotStatus = {};
      try {
        riotStatus = await _riot.getLinkStatus(token: token);
      } catch (e) {
        debugPrint('[LinkedAccounts] Riot link-status failed: $e');
      }

      Map<String, dynamic> steamStatus = {};
      try {
        steamStatus = await _steam.getStatus(token: token);
      } catch (e) {
        debugPrint('[LinkedAccounts] Steam status failed: $e');
      }

      _lastRiotStatus = riotStatus;
      _lastSteamStatus = steamStatus;

      final out = <LinkedGameAccount>[];
      final riotLinked = _riotVerified(riotStatus);
      final steamOk = _steamVerified(steamStatus);

      List<dynamic> lolMatches = const [];
      List<dynamic> valMatches = const [];

      if (riotLinked) {
        try {
          final lolRes = await _riot.getMatchHistory(token: token, game: 'lol');
          lolMatches = (lolRes['matches'] as List?) ?? const [];
        } catch (_) {
          lolMatches = const [];
        }
        try {
          final valRes = await _riot.getMatchHistory(token: token, game: 'val');
          valMatches = (valRes['matches'] as List?) ?? const [];
        } catch (_) {
          valMatches = const [];
        }
      }

      final lolAgg = _aggregateFromMatches(lolMatches);
      final valAgg = _aggregateFromMatches(valMatches);
      final rankLol = _rankForLol(platformRanks);
      final rankVal = _rankForValorant(platformRanks);
      final lolWin = _winPct(rankLol) != '--' ? _winPct(rankLol) : lolAgg.win;
      final valWin = _winPct(rankVal) != '--' ? _winPct(rankVal) : valAgg.win;

      if (riotLinked) {
        out.add(
          LinkedGameAccount.lol(
            riotStatus,
            primaryStat: lolAgg.kd,
            secondaryStat: lolWin,
            fallbackName: 'RIOT',
            rankTier: _rankTierLabel(rankLol),
            matchesCount: lolMatches.isNotEmpty ? '${lolMatches.length}' : null,
            mainRole: null,
            streak: null,
          ),
        );
        out.add(
          LinkedGameAccount.valorant(
            riotStatus,
            primaryStat: valAgg.kd,
            secondaryStat: valWin,
            fallbackName: 'RIOT',
            rankTier: _rankTierLabel(rankVal),
            matchesCount: valMatches.isNotEmpty ? '${valMatches.length}' : null,
            mainRole: null,
            streak: null,
          ),
        );
      }

      if (steamOk) {
        out.add(
          LinkedGameAccount.cs2(
            steamStatus,
            primaryStat: '--',
            secondaryStat: '--',
          ),
        );
        out.add(
          LinkedGameAccount.dota2(
            steamStatus,
            primaryStat: '--',
            secondaryStat: '--',
          ),
        );
      }

      _accounts = out;
    } catch (e) {
      _error = e.toString();
      _accounts = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
