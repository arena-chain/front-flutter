import 'package:arena_chain_flutter/core/api/feature_friends/friends_api.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';

class FriendsRepository {
  final FriendsApi _api;

  FriendsRepository({FriendsApi? api}) : _api = api ?? FriendsApi();

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    try {
      return await _api.searchUsers(query, excludeUserId: excludeUserId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<FriendshipModel> sendFriendRequest(String requesterId, String recipientId) async {
    try {
      return await _api.sendFriendRequest(requesterId, recipientId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    try {
      return await _api.getFriends(userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    try {
      return await _api.getPendingRequests(userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    try {
      return await _api.getSentRequests(userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    try {
      return await _api.acceptRequest(friendshipId, userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> rejectRequest(String friendshipId, String userId) async {
    try {
      return await _api.rejectRequest(friendshipId, userId);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
