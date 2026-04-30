import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/steam/steam_api.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_account_model.dart';
import 'package:arena_chain_flutter/core/models/steam/steam_link_status_model.dart';

enum GameStatsTarget { lol, valorant, cs2, dota2 }

bool _riotVerified(Map<String, dynamic> s) {
  final v = s['status'] ?? s['riotLinkStatus'];
  return v != null && v.toString().toLowerCase() == 'verified';
}

class GameStatsViewModel extends ChangeNotifier {
  GameStatsViewModel(this.target);

  final GameStatsTarget target;
  final RiotApi _riot = RiotApi();
  final SteamApi _steam = SteamApi();
  final TokenStorage _tokens = TokenStorage();

  bool loading = true;
  String? error;
  Map<String, dynamic> linkStatus = {};
  RiotAccountModel? lolAccount;
  List<dynamic> matches = [];
  SteamLinkStatusModel? steamStatus;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _tokens.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      switch (target) {
        case GameStatsTarget.lol:
          linkStatus = await _riot.getLinkStatus(token: token);
          if (!_riotVerified(linkStatus)) {
            throw Exception('Riot account not linked');
          }
          final gn = linkStatus['riotGameName']?.toString() ?? '';
          final tag = linkStatus['riotTagLine']?.toString() ?? '';
          final region = linkStatus['riotRegion']?.toString() ?? 'na1';
          if (gn.isEmpty || tag.isEmpty) {
            throw Exception('Missing Riot ID on profile');
          }
          lolAccount = await _riot.fetchPlayerAccount(
            gameName: gn,
            tagLine: tag,
            region: region,
            token: token,
          );
          final hist = await _riot.getMatchHistory(
            token: token,
            game: 'lol',
            count: 10,
          );
          matches = List<dynamic>.from(hist['matches'] as List? ?? const []);
          break;

        case GameStatsTarget.valorant:
          linkStatus = await _riot.getLinkStatus(token: token);
          if (!_riotVerified(linkStatus)) {
            throw Exception('Riot account not linked');
          }
          final hist = await _riot.getMatchHistory(
            token: token,
            game: 'val',
            count: 10,
          );
          matches = List<dynamic>.from(hist['matches'] as List? ?? const []);
          break;

        case GameStatsTarget.cs2:
        case GameStatsTarget.dota2:
          final m = await _steam.getStatus(token: token);
          steamStatus = SteamLinkStatusModel.fromJson(m);
          if (!steamStatus!.steamVerified) {
            throw Exception('Steam not verified');
          }
          break;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
