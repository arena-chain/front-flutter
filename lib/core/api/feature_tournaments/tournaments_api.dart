import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/tournaments/create_tournament_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class TournamentsApi {
  static String get baseUrl => ApiConfig.baseUrl;
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
      Uri.parse('$baseUrl/api/tournements'),
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
      Uri.parse('$baseUrl/api/tournements'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TournamentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tournaments');
    }
  }
}
