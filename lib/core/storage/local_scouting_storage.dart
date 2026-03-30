import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Local storage for reports and prospects when backend API is unavailable.
/// Enables scouter management (reports, watchlist) to work offline / without backend.
class LocalScoutingStorage {
  static const _keyReports = 'scouting_reports';
  static const _keyProspects = 'scouting_prospects';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // ─── Reports ─────────────────────────────────────────────────────────────

  Future<List<ScoutingReport>> getReports(String scouterId) async {
    final all = await _getAllReports(await _prefs);
    return all.where((r) => r.scouterId == scouterId).toList();
  }

  Future<List<ScoutingReport>> getReportsForPlayer(String playerId) async {
    final all = await _getAllReports(await _prefs);
    return all.where((r) => r.playerIdStr == playerId).toList();
  }

  Future<ScoutingReport> addReport(Map<String, dynamic> body) async {
    final prefs = await _prefs;
    final existing = await _getAllReports(prefs);
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final playerId = body['playerId'];
    final playerNickname = body['playerNickname'] as String?;
    final reportJson = {
      '_id': id,
      'scouterId': body['scouterId'] ?? '',
      'playerId': playerNickname != null
          ? {'_id': playerId, 'nickname': playerNickname}
          : playerId,
      if (body['matchId'] != null) 'matchId': body['matchId'],
      'rating': (body['rating'] as num?)?.toInt() ?? 0,
      if (body['strengths'] != null) 'strengths': body['strengths'],
      if (body['weaknesses'] != null) 'weaknesses': body['weaknesses'],
      if (body['notes'] != null) 'notes': body['notes'],
      if (body['recommendedRole'] != null) 'recommendedRole': body['recommendedRole'],
      'createdAt': DateTime.now().toIso8601String(),
    };
    final report = ScoutingReport.fromJson(reportJson);
    existing.add(report);
    await _saveReports(prefs, existing);
    return report;
  }

  Future<void> deleteReport(String id) async {
    final prefs = await _prefs;
    final existing = await _getAllReports(prefs);
    existing.removeWhere((r) => r.id == id);
    await _saveReports(prefs, existing);
  }

  Future<List<ScoutingReport>> _getAllReports(SharedPreferences prefs) async {
    final json = prefs.getString(_keyReports);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => ScoutingReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveReports(
      SharedPreferences prefs, List<ScoutingReport> reports) async {
    final list = reports.map((r) => _reportToJson(r)).toList();
    await prefs.setString(_keyReports, jsonEncode(list));
  }

  Map<String, dynamic> _reportToJson(ScoutingReport r) {
    return {
      '_id': r.id,
      'scouterId': r.scouterId,
      'playerId': r.playerId is Map
          ? r.playerId
          : {'_id': r.playerIdStr, 'nickname': r.playerNickname},
      if (r.matchId != null) 'matchId': r.matchId,
      'rating': r.rating,
      if (r.strengths != null) 'strengths': r.strengths,
      if (r.weaknesses != null) 'weaknesses': r.weaknesses,
      if (r.notes != null) 'notes': r.notes,
      if (r.recommendedRole != null) 'recommendedRole': r.recommendedRole,
      'createdAt': r.createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // ─── Prospects ──────────────────────────────────────────────────────────

  Future<List<ProspectStatus>> getProspects() async {
    final prefs = await _prefs;
    final json = prefs.getString(_keyProspects);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => ProspectStatus.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ProspectStatus> upsertProspect(
      Map<String, dynamic> body, String? playerNickname) async {
    final prefs = await _prefs;
    final existing = await getProspects();
    final playerId = body['playerId']?.toString() ?? '';
    final prospectLevel = body['prospectLevel']?.toString() ?? 'WATCHLIST';
    final priority = body['priority']?.toString() ?? 'MEDIUM';
    final idx = existing.indexWhere((p) => p.playerId == playerId);

    final id = idx >= 0 ? existing[idx].id : 'local_${DateTime.now().millisecondsSinceEpoch}';
    final updated = ProspectStatus(
      id: id,
      raw: {
        '_id': id,
        'playerId': playerNickname != null && playerNickname.isNotEmpty
            ? {'_id': playerId, 'nickname': playerNickname}
            : playerId,
        'prospectLevel': prospectLevel,
        'priority': priority,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
    );

    final newList = [...existing];
    if (idx >= 0) {
      newList[idx] = updated;
    } else {
      newList.add(updated);
    }
    final list = newList.map((p) => _prospectToJson(p)).toList();
    await prefs.setString(_keyProspects, jsonEncode(list));
    return updated;
  }

  Map<String, dynamic> _prospectToJson(ProspectStatus p) {
    return {
      '_id': p.id,
      'playerId': p.playerIdRaw is Map
          ? p.playerIdRaw
          : {'_id': p.playerId, 'nickname': p.playerNickname},
      'prospectLevel': p.prospectLevel,
      'priority': p.priority ?? 'MEDIUM',
      'lastUpdated': p.lastUpdated ?? DateTime.now().toIso8601String(),
    };
  }
}
