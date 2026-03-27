import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/models/team_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/core/config/api_config.dart';

class TeamApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Team>> getTeams() async {
    final url = Uri.parse('$baseUrl/api/teams');
    
    try {
      final response = await http.get(url); // Public endpoint might not need token, but good to have if we change it

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Team.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load teams');
      }
    } catch (e) {
      throw Exception('Failed to load teams: $e');
    }
  }

  Future<void> createTeam(Map<String, dynamic> teamData) async {
    final url = Uri.parse('$baseUrl/api/teams');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(teamData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create team: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating team: $e');
    }
  }

  Future<void> updateTeam(String id, Map<String, dynamic> teamData) async {
    final url = Uri.parse('$baseUrl/api/teams/$id');
    final headers = await _getHeaders();

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(teamData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update team: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating team: $e');
    }
  }

  Future<void> deleteTeam(String id) async {
    final url = Uri.parse('$baseUrl/api/teams/$id');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete team: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting team: $e');
    }
  }
}
