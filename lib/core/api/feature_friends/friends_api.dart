import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// Mirrors desktop `shared/api.js` + `freinds/renderer.js` against `/api/friendship` and `/api/users/search`.
class FriendsApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    final uri = Uri.parse('$baseUrl/api/users/search').replace(
      queryParameters: {
        'q': query,
        if (excludeUserId != null) 'excludeUserId': excludeUserId,
      },
    );

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendUser.fromJson(json as Map<String, dynamic>)).toList();
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
      return FriendshipModel.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to send friend request');
    }
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friendship/friends/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body) as List;
      return data.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
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
      final List data = json.decode(response.body) as List;
      return data.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load pending requests');
    }
  }

  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friendship/sent-requests/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body) as List;
      return data.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load sent requests');
    }
  }

  Future<List<FriendshipModel>> getBlockedUsers(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/friendship/blocked/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body) as List;
      return data.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load blocked users');
    }
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/accept/$friendshipId'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return FriendshipModel.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>;
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
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to reject request');
    }
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/friendship/remove'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId, 'friendId': friendId}),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to remove friend');
    }
  }

  Future<void> blockUser(String userId, String blockedUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/friendship/block'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId, 'blockedUserId': blockedUserId}),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to block user');
    }
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/friendship/unblock'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId, 'blockedUserId': blockedUserId}),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to unblock user');
    }
  }
}
