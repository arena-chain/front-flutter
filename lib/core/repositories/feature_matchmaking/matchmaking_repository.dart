import 'package:arena_chain_flutter/core/api/feature_matchmaking/matchmaking_api.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/ticket_model.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/game_match_model.dart';

class MatchmakingRepository {
  final MatchmakingApi _api;

  MatchmakingRepository({MatchmakingApi? api})
      : _api = api ?? MatchmakingApi();

  Future<TicketModel> findMatch({
    required String game,
    required String mode,
    required String server,
    required String region,
    DateTime? scheduledAt,
    Map<String, dynamic>? riotAccountInfo,
  }) async {
    try {
      return await _api.joinQueue(
        game: game,
        mode: mode,
        server: server,
        region: region,
        scheduledAt: scheduledAt,
        riotAccountInfo: riotAccountInfo,
      );
    } catch (e) {
      throw Exception('Failed to find match: $e');
    }
  }

  Future<void> cancelSearch(String ticketId) async {
    try {
      await _api.cancelQueue(ticketId);
    } catch (e) {
      throw Exception('Failed to cancel search: $e');
    }
  }

  Future<GameMatchModel> acceptMatch(String gameId) async {
    try {
      return await _api.respondToMatch(gameId, true);
    } catch (e) {
      throw Exception('Failed to accept match: $e');
    }
  }

  Future<GameMatchModel> declineMatch(String gameId) async {
    try {
      return await _api.respondToMatch(gameId, false);
    } catch (e) {
      throw Exception('Failed to decline match: $e');
    }
  }

  Future<GameMatchModel> getGame(String gameId) async {
    try {
      return await _api.getGame(gameId);
    } catch (e) {
      throw Exception('Failed to get game: $e');
    }
  }

  Future<TicketModel?> getActiveTicket() async {
    try {
      return await _api.getActiveTicket();
    } catch (e) {
      throw Exception('Failed to get active ticket: $e');
    }
  }

  Future<void> acknowledgeGame(String gameId) async {
    try {
      await _api.acknowledgeGame(gameId);
    } catch (e) {
      throw Exception('Failed to acknowledge game: $e');
    }
  }

  Future<GameMatchModel?> getActiveGame() async {
    try {
      return await _api.getActiveGame();
    } catch (e) {
      throw Exception('Failed to get active game: $e');
    }
  }

  Future<List<TicketModel>> getScheduledTickets() async {
    try {
      return await _api.getScheduledTickets();
    } catch (e) {
      throw Exception('Failed to get scheduled tickets: $e');
    }
  }
}
