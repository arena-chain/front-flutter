import 'dart:convert';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/ticket_model.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/game_match_model.dart';

class MatchmakingApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthenticatedClient _client = AuthenticatedClient();

  Future<TicketModel> joinQueue({
    required String game,
    required String mode,
    required String server,
    required String region,
    DateTime? scheduledAt,
    Map<String, dynamic>? riotAccountInfo,
  }) async {
    final url = Uri.parse('$baseUrl/matchmaking/queue');
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
    final url = Uri.parse('$baseUrl/matchmaking/queue/$ticketId');
    final response = await _client.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to cancel queue');
    }
  }

  Future<GameMatchModel> respondToMatch(String gameId, bool accept) async {
    final url = Uri.parse('$baseUrl/matchmaking/games/$gameId/response');
    final response = await _client.post(url, body: {'accept': accept});

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GameMatchModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to respond to match');
    }
  }

  Future<GameMatchModel> getGame(String gameId) async {
    final url = Uri.parse('$baseUrl/matchmaking/games/$gameId');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return GameMatchModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get game');
    }
  }

  Future<TicketModel?> getActiveTicket() async {
    final url = Uri.parse('$baseUrl/matchmaking/my-active-ticket');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ticket'] == null) return null;
      return TicketModel.fromJson(data['ticket']);
    } else {
      throw Exception('Failed to get active ticket');
    }
  }

  Future<void> acknowledgeGame(String gameId) async {
    final url = Uri.parse('$baseUrl/matchmaking/games/$gameId/acknowledge');
    final response = await _client.post(url, body: {});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to acknowledge game');
    }
  }

  Future<GameMatchModel?> getActiveGame() async {
    final url = Uri.parse('$baseUrl/matchmaking/my-active-game');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['game'] == null) return null;
      return GameMatchModel.fromJson(data['game']);
    } else {
      throw Exception('Failed to get active game');
    }
  }

  Future<List<TicketModel>> getScheduledTickets() async {
    final url = Uri.parse('$baseUrl/matchmaking/my-scheduled-tickets');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['tickets'] as List<dynamic>? ?? [];
      return list.map((t) => TicketModel.fromJson(t as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get scheduled tickets');
    }
  }
}
