import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/directory_models.dart';

/// Handles the Players Directory: real users + scouter-stats merge, teams, rosters.
class PlayersDirectoryApi {
  static String get _base => ApiConfig.baseUrl;
  final TokenStorage _ts = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _ts.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _check(http.Response r, String ctx) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    String msg = ctx;
    try { msg = jsonDecode(r.body)['message']?.toString() ?? ctx; } catch (_) {}
    throw Exception(msg);
  }

  // ── GET /users ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getRawUsers() async {
    final r = await http.get(Uri.parse('$_base/api/users'), headers: await _headers());
    final data = _check(r, 'Failed to load users');
    if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  // ── GET /scouter/players ───────────────────────────────────────────────────

  Future<List<PlayerDetail>> _getScouterProfiles() async {
    try {
      final r = await http.get(Uri.parse('$_base/api/scouter/players'), headers: await _headers());
      final data = _check(r, 'Failed to load scouter profiles');
      if (data is List) return data.map((e) => PlayerDetail.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    return [];
  }

  // ── Merged players (real nicknames + real stats) ───────────────────────────

  Future<List<PlayerDetail>> getPlayers() async {
    final results = await Future.wait([_getRawUsers(), _getScouterProfiles()]);
    final rawUsers = results[0] as List<Map<String, dynamic>>;
    final profiles = results[1] as List<PlayerDetail>;

    // Build userId → PlayerDetail map for quick lookup
    final profileByUserId = <String, PlayerDetail>{};
    for (final p in profiles) {
      final uid = p.effectiveUserId;
      if (uid.isNotEmpty) profileByUserId[uid] = p;
    }

    // Build ProfileId → PlayerDetail map (fallback match by document _id)
    final profileById = <String, PlayerDetail>{};
    for (final p in profiles) {
      profileById[p.id] = p;
    }

    final players = <PlayerDetail>[];

    // Include all users except admins/scouters so players with missing/varied
    // role values are not excluded from the nickname lookup.
    final playerUsers = rawUsers.where((u) {
      final role = (u['role'] ?? u['roles']?[0] ?? '').toString().toLowerCase();
      return role != 'scouter' && role != 'admin' && role != 'moderator';
    }).toList();

    for (final user in playerUsers) {
      final userId = (user['_id'] ?? user['id'] ?? '').toString();
      if (userId.isEmpty) continue;

      final profile = profileByUserId[userId];

      // Merge: user identity + profile stats
      final merged = <String, dynamic>{
        '_id': profile?.id ?? userId,  // prefer ProfileId so scouter endpoints work
        'userId': userId,              // keep the User._id accessible
        'nickname': user['nickname'] ?? user['displayName'] ?? user['username'] ?? '',
        'avatar': user['avatar'] ?? user['photo'],
        'country': user['country'],
        'email': user['email'],
        'isPro': profile?.isPro ?? false,
        'elo': profile?.elo ?? 0,
        'tier': profile?.raw['tier'] ?? profile?.raw['rank'] ?? 'UNRANKED',
        'rank': profile?.raw['rank'] ?? profile?.raw['tier'] ?? 'UNRANKED',
        'team': profile?.raw['team'],
        'region': profile?.raw['region'],
        'stats': profile?.stats,
        'riotLinkStatus': profile?.raw['riotLinkStatus'],
        'riotGameName': profile?.raw['riotGameName'],
        'riotPuuid': profile?.raw['riotPuuid'],
      };

      players.add(PlayerDetail.fromJson(merged));
    }

    // Sort by ELO descending
    players.sort((a, b) => b.elo.compareTo(a.elo));
    return players;
  }

  // ── GET /scouter/players raw (with populated userId) ───────────────────────

  Future<List<Map<String, dynamic>>> getRawProfiles() async {
    final r = await http.get(Uri.parse('$_base/api/scouter/players'), headers: await _headers());
    final data = _check(r, 'Failed to load profiles');
    if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  // ── GET /teams ─────────────────────────────────────────────────────────────

  Future<List<TeamItem>> getTeams() async {
    final r = await http.get(Uri.parse('$_base/api/teams'), headers: await _headers());
    final data = _check(r, 'Failed to load teams');
    if (data is List) return data.map((e) => TeamItem.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }

  // ── GET /season-rosters/by-season?seasonId=... ─────────────────────────────

  Future<List<SeasonRosterItem>> getSeasonRoster(String seasonId) async {
    final r = await http.get(
      Uri.parse('$_base/api/season-rosters/by-season?seasonId=$seasonId'),
      headers: await _headers(),
    );
    final data = _check(r, 'Failed to load roster');
    if (data is List) return data.map((e) => SeasonRosterItem.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}
