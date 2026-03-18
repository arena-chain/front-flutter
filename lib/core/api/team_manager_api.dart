import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';

import 'package:arena_chain_flutter/core/config/api_config.dart';

class TeamManagerApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<TeamManagerProfile>> getPendingManagers() async {
    final url = Uri.parse('$baseUrl/team-manager/pending');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TeamManagerProfile.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending managers');
      }
    } catch (e) {
      throw Exception('Error loading pending managers: $e');
    }
  }

  Future<void> approveManager(String userId) async {
    final url = Uri.parse('$baseUrl/team-manager/$userId/approve');
    final headers = await _getHeaders();

    try {
      final response = await http.patch(url, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to approve manager: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error approving manager: $e');
    }
  }

  Future<void> rejectManager(String userId) async {
    final url = Uri.parse('$baseUrl/team-manager/$userId/reject');
    final headers = await _getHeaders();

    try {
      final response = await http.patch(url, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to reject manager: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error rejecting manager: $e');
    }
  }
}
