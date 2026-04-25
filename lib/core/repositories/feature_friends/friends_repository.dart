import 'package:arena_chain_flutter/core/api/feature_friends/friends_api.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';

class FriendsRepository {
  final FriendsApi _api;

  FriendsRepository({FriendsApi? api}) : _api = api ?? FriendsApi();

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    return await _api.searchUsers(query, excludeUserId: excludeUserId);
  }

  Future<FriendshipModel> sendFriendRequest(String requesterId, String recipientId) async {
    return await _api.sendFriendRequest(requesterId, recipientId);
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    return await _api.getFriends(userId);
  }

  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    return await _api.getPendingRequests(userId);
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    return await _api.acceptRequest(friendshipId, userId);
  }

  Future<void> rejectRequest(String friendshipId, String userId) async {
    return await _api.rejectRequest(friendshipId, userId);
  }

  Future<void> removeFriend(String requesterId, String recipientId) async {
    return await _api.removeFriend(requesterId, recipientId);
  }
}
