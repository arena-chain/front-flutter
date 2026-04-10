import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/repositories/feature_friends/friends_repository.dart';
import 'package:flutter/material.dart';

<<<<<<< HEAD
enum FriendSearchRelation {
  none,
  friends,
  pendingIncoming,
  pendingOutgoing,
}

/// Maps desktop `freinds/renderer.js`: search (min 2 chars), lists, actions.
class FriendsViewModel extends ChangeNotifier {
  final FriendsRepository _repository;
  final String currentUserId;

  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  List<FriendshipModel> _sentRequests = [];
  List<FriendshipModel> _blocked = [];
  List<FriendUser> _searchResults = [];
  bool _isLoading = false;
  bool _isSearchLoading = false;
=======
class FriendsViewModel extends ChangeNotifier {
  final FriendsRepository _repository;
  final String currentUserId; // We need the current user ID for context

  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  List<FriendUser> _searchResults = [];
  bool _isLoading = false;
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  String? _error;

  List<FriendshipModel> get friends => _friends;
  List<FriendshipModel> get pendingRequests => _pendingRequests;
<<<<<<< HEAD
  List<FriendshipModel> get sentRequests => _sentRequests;
  List<FriendshipModel> get blocked => _blocked;
  List<FriendUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearchLoading => _isSearchLoading;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;
=======
  List<FriendUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

  FriendsViewModel({
    required this.currentUserId,
    FriendsRepository? repository,
  }) : _repository = repository ?? FriendsRepository();

<<<<<<< HEAD
  Set<String> get _friendIds => _friends.map(_otherUserId).whereType<String>().toSet();
  Set<String> get _pendingIncomingIds =>
      _pendingRequests.map(_otherUserId).whereType<String>().toSet();
  Set<String> get _sentOutgoingIds =>
      _sentRequests.map(_otherUserId).whereType<String>().toSet();

  static bool _sameMongoId(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a.toLowerCase() == b.toLowerCase();
  }

  /// Public for UI that compares user ids (Mongo/ObjectId strings, case-insensitive).
  static bool sameUserId(String a, String b) => _sameMongoId(a, b);

  FriendSearchRelation relationToSearchUser(String userId) {
    if (_friendIds.any((id) => _sameMongoId(id, userId))) return FriendSearchRelation.friends;
    if (_pendingIncomingIds.any((id) => _sameMongoId(id, userId))) {
      return FriendSearchRelation.pendingIncoming;
    }
    if (_sentOutgoingIds.any((id) => _sameMongoId(id, userId))) {
      return FriendSearchRelation.pendingOutgoing;
    }
    return FriendSearchRelation.none;
  }

  int _relationSortOrder(FriendSearchRelation r) {
    switch (r) {
      case FriendSearchRelation.friends:
        return 0;
      case FriendSearchRelation.pendingIncoming:
        return 1;
      case FriendSearchRelation.pendingOutgoing:
        return 2;
      case FriendSearchRelation.none:
        return 3;
    }
  }

  /// Friends first, then incoming requests, sent, then non-friends (desktop-style priority).
  List<FriendUser> get sortedSearchResults {
    final list = List<FriendUser>.from(_searchResults);
    list.sort((a, b) {
      final oa = _relationSortOrder(relationToSearchUser(a.id));
      final ob = _relationSortOrder(relationToSearchUser(b.id));
      if (oa != ob) return oa.compareTo(ob);
      return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
    });
    return list;
  }

  /// Pending request **received** from this user (for Accept).
  String? incomingFriendshipIdForUser(String userId) {
    for (final f in _pendingRequests) {
      final other = _otherUserId(f);
      if (other != null && other.isNotEmpty && _sameMongoId(other, userId) && f.id.isNotEmpty) {
        return f.id;
      }
    }
    return null;
  }

  String? _otherUserId(FriendshipModel f) {
    final req = f.requester;
    final rec = f.recipient;
    if (req is FriendUser && req.id.isNotEmpty && !_sameMongoId(req.id, currentUserId)) {
      return req.id;
    }
    if (rec is FriendUser && rec.id.isNotEmpty && !_sameMongoId(rec.id, currentUserId)) {
      return rec.id;
    }
    if (req is String && req.isNotEmpty && !_sameMongoId(req, currentUserId)) return req;
    if (rec is String && rec.isNotEmpty && !_sameMongoId(rec, currentUserId)) return rec;
    return null;
  }

  Future<void> loadAllFriendData() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repository.getFriends(currentUserId),
        _repository.getPendingRequests(currentUserId),
        _repository.getSentRequests(currentUserId),
        _repository.getBlockedUsers(currentUserId),
      ]);
      _friends = results[0];
      _pendingRequests = results[1];
      _sentRequests = results[2];
      _blocked = results[3];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
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
<<<<<<< HEAD
=======
    // Note: Don't set global loading here to avoid blocking UI if done in background
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    try {
      _pendingRequests = await _repository.getPendingRequests(currentUserId);
      notifyListeners();
    } catch (e) {
<<<<<<< HEAD
      debugPrint('loadPendingRequests: $e');
    }
  }

  /// Desktop: search only when query length >= 2.
  Future<void> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _searchResults = [];
      _isSearchLoading = false;
=======
      print('Error loading pending requests: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      notifyListeners();
      return;
    }

<<<<<<< HEAD
    _isSearchLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchUsers(
        trimmed,
        excludeUserId: currentUserId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearchLoading = false;
      notifyListeners();
=======
    _setLoading(true);
    try {
      _searchResults = await _repository.searchUsers(query, excludeUserId: currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
<<<<<<< HEAD
    await _repository.sendFriendRequest(currentUserId, recipientId);
    await loadAllFriendData();
    notifyListeners();
  }

  Future<void> acceptRequest(String friendshipId) async {
    if (friendshipId.isEmpty) {
      throw ArgumentError('Invalid friendship id');
    }
    final index = _pendingRequests.indexWhere((r) => r.id == friendshipId);
    FriendshipModel? removed;
    if (index != -1) {
      removed = _pendingRequests[index];
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      _pendingRequests.removeAt(index);
      notifyListeners();
    }

    try {
<<<<<<< HEAD
      await _repository.acceptRequest(friendshipId, currentUserId);
      await loadAllFriendData();
    } catch (e) {
      if (removed != null && index >= 0) {
        _pendingRequests.insert(index, removed);
        notifyListeners();
      }
      _error = e.toString();
      rethrow;
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
<<<<<<< HEAD
    await _repository.rejectRequest(friendshipId, currentUserId);
    await loadAllFriendData();
  }

  Future<void> removeFriend(String friendId) async {
    await _repository.removeFriend(currentUserId, friendId);
    await loadAllFriendData();
  }

  Future<void> blockUser(String blockedUserId) async {
    await _repository.blockUser(currentUserId, blockedUserId);
    await loadAllFriendData();
  }

  Future<void> unblockUser(String blockedUserId) async {
    await _repository.unblockUser(currentUserId, blockedUserId);
    await loadAllFriendData();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
=======
    try {
      await _repository.rejectRequest(friendshipId, currentUserId);
      await loadPendingRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
<<<<<<< HEAD
=======
  
  // Helper to clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
}
