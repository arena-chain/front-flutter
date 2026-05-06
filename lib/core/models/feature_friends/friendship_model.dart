import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';

enum FriendshipStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  BLOCKED,
}

class FriendshipModel {
  final String id;
  final dynamic requester; // Can be String (ID) or FriendUser
  final dynamic recipient; // Can be String (ID) or FriendUser
  final FriendshipStatus status;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  FriendshipModel({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
    this.acceptedAt,
    required this.createdAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['_id'] ?? json['id'];
    return FriendshipModel(
      id: idRaw?.toString() ?? '',
      requester: _parseUser(json['requesterId']),
      recipient: _parseUser(json['recipientId']),
      status: _parseStatus(json['status']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'].toString())
          : null,
      createdAt: _parseCreatedAt(json),
    );
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> json) {
    for (final key in ['createdAt', 'updatedAt', 'acceptedAt']) {
      final v = json[key];
      if (v != null) {
        final d = DateTime.tryParse(v.toString());
        if (d != null) return d;
      }
    }
    return DateTime.now();
  }

  static dynamic _parseUser(dynamic userJson) {
    if (userJson == null) return null;
    if (userJson is String) return userJson;
    if (userJson is Map) {
      return FriendUser.fromJson(Map<String, dynamic>.from(userJson));
    }
    return null;
  }

  static FriendshipStatus _parseStatus(dynamic status) {
    final s = status?.toString().trim().toUpperCase() ?? '';
    switch (s) {
      case 'PENDING':
        return FriendshipStatus.PENDING;
      case 'ACCEPTED':
        return FriendshipStatus.ACCEPTED;
      case 'REJECTED':
        return FriendshipStatus.REJECTED;
      case 'BLOCKED':
        return FriendshipStatus.BLOCKED;
      default:
        if (s.isEmpty) return FriendshipStatus.ACCEPTED;
        throw Exception('Unknown friendship status: $status');
    }
  }

  /// The other user in this friendship (for lists keyed by the current account).
  FriendUser? counterpartFor(String myUserId) {
    final my = myUserId.trim();
    if (my.isEmpty) return null;
    final reqId = _partyId(requester);
    final recId = _partyId(recipient);
    if (reqId != null && reqId == my) return _partyToFriendUser(recipient);
    if (recId != null && recId == my) return _partyToFriendUser(requester);
    return null;
  }

  static String? _partyId(dynamic party) {
    if (party == null) return null;
    if (party is String) return party.trim();
    if (party is FriendUser) return party.id;
    return null;
  }

  static FriendUser? _partyToFriendUser(dynamic party) {
    if (party is FriendUser) return party;
    if (party is String && party.isNotEmpty) {
      return FriendUser(id: party, nickname: 'Friend', email: '');
    }
    return null;
  }

  FriendUser? get friendUser {
     // Helper to get the "other" user logic will be handled in Repository/ViewModel 
     // or we keep it simple here. 
     // For now, returning null as we need current user ID to know who is the friend.
     return null; 
  }
}
