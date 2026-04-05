import 'package:arena_chain_flutter/core/api/feature_friends/friends_api.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';

class FriendsRepository {
  final FriendsApi _api;

  FriendsRepository({FriendsApi? api}) : _api = api ?? FriendsApi();

  Future<List<FriendUser>> searchUsers(String query, {String? excludeUserId}) async {
    return _api.searchUsers(query, excludeUserId: excludeUserId);
  }

  Future<FriendshipModel> sendFriendRequest(String requesterId, String recipientId) async {
    return _api.sendFriendRequest(requesterId, recipientId);
  }

  Future<List<FriendshipModel>> getFriends(String userId) async {
    return _api.getFriends(userId);
  }

  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    return _api.getPendingRequests(userId);
  }

  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    return _api.getSentRequests(userId);
  }

  Future<List<FriendshipModel>> getBlockedUsers(String userId) async {
    return _api.getBlockedUsers(userId);
  }

  Future<FriendshipModel> acceptRequest(String friendshipId, String userId) async {
    return _api.acceptRequest(friendshipId, userId);
  }

  Future<void> rejectRequest(String friendshipId, String userId) async {
    return _api.rejectRequest(friendshipId, userId);
  }

  Future<void> removeFriend(String userId, String friendId) async {
    return _api.removeFriend(userId, friendId);
  }

  Future<void> blockUser(String userId, String blockedUserId) async {
    return _api.blockUser(userId, blockedUserId);
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    return _api.unblockUser(userId, blockedUserId);
  }
}
