import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/tournaments/create_tournament_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/core/models/feature_tournaments/ticket_model.dart';

class TournamentsApi {
  static const String baseUrl = 'http://10.0.2.2:3000';
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<TournamentModel> createTournament(CreateTournamentDto dto) async {
    final jsonData = dto.toJson();
    print('Creating tournament with data: $jsonData');
    
    final response = await http.post(
      Uri.parse('$baseUrl/tournements'),
      headers: await _getHeaders(),
      body: jsonEncode(jsonData),
    );

    print('Tournament API Response Status: ${response.statusCode}');
    print('Tournament API Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return TournamentModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create tournament');
    }
  }

  Future<List<TournamentModel>> getTournaments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tournements'),
      headers: await _getHeaders(),
    );

    print('Tournaments API Response Status: ${response.statusCode}');
    print('Tournaments API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('Number of tournaments: ${data.length}');
      if (data.isNotEmpty) {
        print('First tournament data: ${data[0]}');
        print('First tournament ticketTypes: ${data[0]['ticketTypes']}');
      }
      return data.map((json) => TournamentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tournaments');
    }
  }

  Future<List<TicketModel>> bookTicket({
    required String tournamentId,
    required String userId,
    required String ticketType,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tickets'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'tournament': tournamentId,
        'user': userId,
        'type': ticketType,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TicketModel.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to book ticket');
    }
  }

  Future<List<TicketModel>> getMyTickets(String userId) async {
    print('═══════════════════════════════════════');
    print('🎫 FETCHING TICKETS FOR USER: $userId');
    print('📍 URL: $baseUrl/tickets/my-tickets?userId=$userId');

    final response = await http.get(
      Uri.parse('$baseUrl/tickets/my-tickets?userId=$userId'),
      headers: await _getHeaders(),
    );

    print('📊 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('✅ Number of tickets: ${data.length}');

      if (data.isNotEmpty) {
        print('🔍 First ticket raw data:');
        print(data[0]);
      }

      try {
        final tickets = data.map((json) {
          print('🎯 Parsing ticket: ${json['_id']}');
          return TicketModel.fromJson(json);
        }).toList();
        print('✅ Successfully parsed ${tickets.length} tickets');
        print('═══════════════════════════════════════');
        return tickets;
      } catch (e) {
        print('❌ ERROR parsing tickets: $e');
        print('═══════════════════════════════════════');
        rethrow;
      }
    } else {
      final error = jsonDecode(response.body);
      print('❌ API Error: ${error['message']}');
      print('═══════════════════════════════════════');
      throw Exception(error['message'] ?? 'Failed to fetch tickets');
    }
  }
}
