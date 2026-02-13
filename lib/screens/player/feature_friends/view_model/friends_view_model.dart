import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/repositories/feature_friends/friends_repository.dart';
import 'package:flutter/material.dart';

class FriendsViewModel extends ChangeNotifier {
  final FriendsRepository _repository;
  final String currentUserId; // We need the current user ID for context

  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  List<FriendUser> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<FriendshipModel> get friends => _friends;
  List<FriendshipModel> get pendingRequests => _pendingRequests;
  List<FriendUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FriendsViewModel({
    required this.currentUserId,
    FriendsRepository? repository,
  }) : _repository = repository ?? FriendsRepository();

  Future<void> loadFriends() async {
    _setLoading(true);
    try {
      _friends = await _repository.getFriends(currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingRequests() async {
    // Note: Don't set global loading here to avoid blocking UI if done in background
    try {
      _pendingRequests = await _repository.getPendingRequests(currentUserId);
      notifyListeners();
    } catch (e) {
      print('Error loading pending requests: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResults = await _repository.searchUsers(query, excludeUserId: currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
    try {
      await _repository.sendFriendRequest(currentUserId, recipientId);
      // Optionally update some state or show success message
      // We might want to remove the user from search results or change their status UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    // 1. Optimistic Update: Remove from pending immediately
    final index = _pendingRequests.indexWhere((r) => r.id == friendshipId);
    FriendshipModel? removedRequest;
    
    if (index != -1) {
      removedRequest = _pendingRequests[index];
      _pendingRequests.removeAt(index);
      notifyListeners();
    }

    try {
      // 2. Make API Call
      await _repository.acceptRequest(friendshipId, currentUserId);
      
      // 3. Refresh Data to ensure sync (especially for the friends list)
      await Future.wait([
        loadFriends(),
        // loadPendingRequests(), // Already removed locally, but good to sync
      ]);
    } catch (e) {
      // 4. Revert on Error
      if (removedRequest != null) {
        _pendingRequests.insert(index, removedRequest);
        notifyListeners();
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
    try {
      await _repository.rejectRequest(friendshipId, currentUserId);
      await loadPendingRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Helper to clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
