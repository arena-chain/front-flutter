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
    return FriendshipModel(
      id: json['_id'] as String,
      requester: _parseUser(json['requesterId']),
      recipient: _parseUser(json['recipientId']),
      status: _parseStatus(json['status'] as String),
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static dynamic _parseUser(dynamic userJson) {
    if (userJson is String) {
      return userJson;
    } else if (userJson is Map<String, dynamic>) {
      return FriendUser.fromJson(userJson);
    }
    return null;
  }

  static FriendshipStatus _parseStatus(String status) {
    switch (status) {
      case 'PENDING':
        return FriendshipStatus.PENDING;
      case 'ACCEPTED':
        return FriendshipStatus.ACCEPTED;
      case 'REJECTED':
        return FriendshipStatus.REJECTED;
      case 'BLOCKED':
        return FriendshipStatus.BLOCKED;
      default:
        throw Exception('Unknown friendship status: $status');
    }
  }

  FriendUser? get friendUser {
     // Helper to get the "other" user logic will be handled in Repository/ViewModel 
     // or we keep it simple here. 
     // For now, returning null as we need current user ID to know who is the friend.
     return null; 
  }
}
