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

  Future<Team> getTeamById(String id) async {
    final url = Uri.parse('$baseUrl/api/teams/$id');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return Team.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load team details');
      }
    } catch (e) {
      throw Exception('Error loading team: $e');
    }
  }

  Future<List<Team>> getTeams() async {
    final url = Uri.parse('$baseUrl/api/teams');
    
    try {
      final response = await http.get(url);

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

  // --- Recruitment & Invitations ---

  Future<void> sendInvitation(String teamId, String receiverId, String role, String message) async {
    final url = Uri.parse('$baseUrl/api/teams/invitations');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'teamId': teamId,
        'receiverId': receiverId,
        'role': role,
        'message': message,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send invitation: ${response.body}');
    }
  }

  Future<List<Invitation>> getReceivedInvitations() async {
    final url = Uri.parse('$baseUrl/api/teams/invitations/received');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invitation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch invitations');
    }
  }

  Future<List<Invitation>> getInvitationsSent(String teamId) async {
    final url = Uri.parse('$baseUrl/api/teams/$teamId/invitations/sent');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invitation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch sent invitations');
    }
  }

  Future<void> respondToInvitation(String invitationId, String status) async {
    final url = Uri.parse('$baseUrl/api/teams/invitations/$invitationId/respond');
    final headers = await _getHeaders();

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to respond to invitation: ${response.body}');
    }
  }

  // --- Roster Management ---

  Future<void> removeMember(String teamId, String userId) async {
    final url = Uri.parse('$baseUrl/api/teams/$teamId/members/$userId');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  // --- Communication ---

  Future<void> createPost(String teamId, String content) async {
    final url = Uri.parse('$baseUrl/api/teams/posts');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'teamId': teamId,
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  Future<List<TeamPost>> getTeamPosts(String teamId) async {
    final url = Uri.parse('$baseUrl/api/teams/$teamId/posts');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TeamPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> addComment(String postId, String content) async {
    final url = Uri.parse('$baseUrl/api/teams/posts/$postId/comments');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  Future<List<TeamComment>> getComments(String postId) async {
    final url = Uri.parse('$baseUrl/api/teams/posts/$postId/comments');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TeamComment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<List<dynamic>> searchPlayers(String query) async {
    final url = Uri.parse('$baseUrl/api/teams/players/search?q=$query');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to search players: ${response.body}');
    }
  }
}
