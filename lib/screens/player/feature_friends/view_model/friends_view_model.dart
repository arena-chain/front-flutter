import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/repositories/feature_friends/friends_repository.dart';
import 'package:flutter/material.dart';

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
  String? _error;

  List<FriendshipModel> get friends => _friends;
  List<FriendshipModel> get pendingRequests => _pendingRequests;
  List<FriendshipModel> get sentRequests => _sentRequests;
  List<FriendshipModel> get blocked => _blocked;
  List<FriendUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearchLoading => _isSearchLoading;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;

  FriendsViewModel({
    required this.currentUserId,
    FriendsRepository? repository,
  }) : _repository = repository ?? FriendsRepository();

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
    try {
      _pendingRequests = await _repository.getPendingRequests(currentUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadPendingRequests: $e');
    }
  }

  /// Desktop: search only when query length >= 2.
  Future<void> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _searchResults = [];
      _isSearchLoading = false;
      notifyListeners();
      return;
    }

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
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
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
      _pendingRequests.removeAt(index);
      notifyListeners();
    }

    try {
      await _repository.acceptRequest(friendshipId, currentUserId);
      await loadAllFriendData();
    } catch (e) {
      if (removed != null && index >= 0) {
        _pendingRequests.insert(index, removed);
        notifyListeners();
      }
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
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
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
