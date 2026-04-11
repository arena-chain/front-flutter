import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';

class ScouterReportsViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterReportsViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;
  List<ScoutingReport> reports = [];

  Future<void> loadReports() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _repo.getMyReports(scouterId);
      reports = await _enrichNicknames(raw);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ScoutingReport>> _enrichNicknames(List<ScoutingReport> reps) async {
    if (reps.isEmpty) return reps;
    try {
      // Build nickname lookup from merged players directory (no role filter)
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

      // Also fetch raw scouter profiles for userId→nickname matching
      try {
        final profiles = await PlayersDirectoryApi().getRawProfiles();
        for (final p in profiles) {
          final nick = (p['nickname'] ?? p['displayName'] ?? '').toString();
          if (nick.isEmpty) continue;
          final pid = (p['_id'] ?? p['id'] ?? '').toString();
          if (pid.isNotEmpty) byId[pid] = nick;
          // userId inside profile may be a populated user object
          final uid = p['userId'];
          if (uid is Map) {
            final uidStr = (uid['_id'] ?? uid['id'] ?? '').toString();
            final userNick = (uid['nickname'] ?? uid['displayName'] ?? uid['username'] ?? '').toString();
            if (uidStr.isNotEmpty) byId[uidStr] = userNick.isNotEmpty ? userNick : nick;
            if (pid.isNotEmpty && userNick.isNotEmpty) byId[pid] = userNick;
          } else if (uid is String && uid.isNotEmpty) {
            byId[uid] = nick;
          }
        }
      } catch (_) {}

      return reps.map((r) {
        final pid = r.playerIdStr;
        final found = byId[pid];
        if (found == null || found.isEmpty) return r;
        final enriched = Map<String, dynamic>.from(r.raw);
        enriched['playerNickname'] = found;
        return ScoutingReport(id: r.id, raw: enriched);
      }).toList();
    } catch (_) {
      return reps;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _repo.deleteReport(id);
      reports = reports.where((r) => r.id != id).toList();
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
