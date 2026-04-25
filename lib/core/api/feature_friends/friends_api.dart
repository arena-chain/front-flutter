import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class FriendsApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token', // Uncomment when auth is enabled on backend
    };
  }

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    final uri = Uri.parse('$baseUrl/api/users/search').replace(
      queryParameters: {
        'q': query,
        if (excludeUserId != null) 'excludeUserId': excludeUserId,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<FriendshipModel> sendFriendRequest(String requesterId, String recipientId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/send-request'),
      headers: await _getHeaders(),
      body: json.encode({
        'requesterId': requesterId,
        'recipientId': recipientId,
      }),
    );

    if (response.statusCode == 201) {
      return FriendshipModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to send friend request');
    }
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friendship/friends/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendshipModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load friends');
    }
  }

  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friendship/pending-requests/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendshipModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending requests');
    }
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/accept/$friendshipId'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return FriendshipModel.fromJson(json.decode(response.body));
    } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept request');
    }
  }

  Future<void> rejectRequest(String friendshipId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/reject/$friendshipId'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
    }
  }

  Future<void> removeFriend(String requesterId, String recipientId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/remove'),
      headers: await _getHeaders(),
      body: json.encode({
        'requesterId': requesterId,
        'recipientId': recipientId,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to remove friend');
      } catch (_) {
        throw Exception('Failed to remove friend');
      }
    }
  }
}
