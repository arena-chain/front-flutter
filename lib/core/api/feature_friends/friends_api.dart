import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class FriendsApi {
  static String get baseUrl => ApiConfig.baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();
  String? _workingBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<String> _candidateBaseUrls() {
    final candidates = <String>[
      if (_workingBaseUrl case final String working) working,
      baseUrl,
      'http://10.0.2.2:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3000',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Exception? lastError;
    for (final candidate in _candidateBaseUrls()) {
      try {
        final response = await request(candidate).timeout(const Duration(seconds: 8));
        if (response.statusCode < 500) {
          _workingBaseUrl = candidate;
        }
        return response;
      } on SocketException {
        lastError = Exception(
          'Network unreachable. Check backend host/IP or API_BASE_URL.',
        );
      } on TimeoutException {
        lastError = Exception('Friends API timeout on $candidate');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach friends backend.');
  }

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    final response = await _requestWithFallback((candidateBase) {
      final uri = Uri.parse('$candidateBase/api/users/search').replace(
        queryParameters: {
          'q': query,
          if (excludeUserId case final String excludedId) 'excludeUserId': excludedId,
        },
      );
      return http.get(uri);
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<FriendshipModel> sendFriendRequest(String requesterId, String recipientId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.post(
        Uri.parse('$candidateBase/api/friendship/send-request'),
        headers: headers,
        body: json.encode({
          'requesterId': requesterId,
          'recipientId': recipientId,
        }),
      ),
    );

    if (response.statusCode == 201) {
      return FriendshipModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to send friend request');
    }
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.get(
        Uri.parse('$candidateBase/api/friendship/friends/$userId'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendshipModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load friends');
    }
  }

  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.get(
        Uri.parse('$candidateBase/api/friendship/pending-requests/$userId'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendshipModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending requests');
    }
  }

  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.get(
        Uri.parse('$candidateBase/api/friendship/sent-requests/$userId'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => FriendshipModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sent requests');
    }
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.post(
        Uri.parse('$candidateBase/api/friendship/accept/$friendshipId'),
        headers: headers,
        body: json.encode({'userId': userId}),
      ),
    );

    if (response.statusCode == 200) {
      return FriendshipModel.fromJson(json.decode(response.body));
    } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept request');
    }
  }

  Future<void> rejectRequest(String friendshipId, String userId) async {
    final headers = await _getHeaders();
    final response = await _requestWithFallback(
      (candidateBase) => http.post(
        Uri.parse('$candidateBase/api/friendship/reject/$friendshipId'),
        headers: headers,
        body: json.encode({'userId': userId}),
      ),
    );

    if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
    }
  }
}
