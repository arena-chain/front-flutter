import 'dart:convert';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/ticket_model.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/game_match_model.dart';

class MatchmakingApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<dynamic> _firstOkGetJson(List<String> endpoints) async {
    for (final endpoint in endpoints) {
      try {
        final response = await _client.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<TicketModel> joinQueue({
    required String game,
    required String mode,
    required String server,
    required String region,
    DateTime? scheduledAt,
    Map<String, dynamic>? riotAccountInfo,
  }) async {
    final url = Uri.parse('$baseUrl/api/matchmaking/queue');
    final body = <String, dynamic>{
      'game': game,
      'mode': mode,
      'server': server,
      'region': region,
    };
    if (scheduledAt != null) {
      body['scheduledAt'] = scheduledAt.toUtc().toIso8601String();
    }
    if (riotAccountInfo != null) {
      body['riotAccountInfo'] = riotAccountInfo;
    }
    final response = await _client.post(url, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return TicketModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to join queue');
    }
  }

  Future<void> cancelQueue(String ticketId) async {
    final url = Uri.parse('$baseUrl/api/matchmaking/queue/$ticketId');
    final response = await _client.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to cancel queue');
    }
  }

  Future<GameMatchModel> respondToMatch(String gameId, bool accept) async {
    final url = Uri.parse('$baseUrl/api/matchmaking/games/$gameId/response');
    final response = await _client.post(url, body: {'accept': accept});

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GameMatchModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to respond to match');
    }
  }

  Future<GameMatchModel> getGame(String gameId) async {
    final url = Uri.parse('$baseUrl/api/matchmaking/games/$gameId');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return GameMatchModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get game');
    }
  }

  Future<TicketModel?> getActiveTicket() async {
    final data = await _firstOkGetJson([
      '$baseUrl/api/matchmaking/my-active-ticket',
      '$baseUrl/matchmaking/my-active-ticket',
      '$baseUrl/api/matchmaking/active-ticket',
      '$baseUrl/matchmaking/active-ticket',
    ]);
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final ticket = data['ticket'];
      if (ticket is Map<String, dynamic>) return TicketModel.fromJson(ticket);
    }
    return null;
  }

  Future<void> acknowledgeGame(String gameId) async {
    final url = Uri.parse('$baseUrl/api/matchmaking/games/$gameId/acknowledge');
    final response = await _client.post(url, body: {});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to acknowledge game');
    }
  }

  Future<GameMatchModel?> getActiveGame() async {
    final data = await _firstOkGetJson([
      '$baseUrl/api/matchmaking/my-active-game',
      '$baseUrl/matchmaking/my-active-game',
      '$baseUrl/api/matchmaking/active-game',
      '$baseUrl/matchmaking/active-game',
    ]);
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final game = data['game'];
      if (game is Map<String, dynamic>) return GameMatchModel.fromJson(game);
    }
    return null;
  }

  Future<List<TicketModel>> getScheduledTickets() async {
    final data = await _firstOkGetJson([
      '$baseUrl/api/matchmaking/my-scheduled-tickets',
      '$baseUrl/matchmaking/my-scheduled-tickets',
      '$baseUrl/api/matchmaking/scheduled-tickets',
      '$baseUrl/matchmaking/scheduled-tickets',
    ]);
    if (data is Map<String, dynamic>) {
      final list = data['tickets'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((t) => TicketModel.fromJson(t))
          .toList();
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((t) => TicketModel.fromJson(t))
          .toList();
    }
    return [];
  }
}
