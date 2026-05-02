import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';

class Team {
  final String id;
  final String name;
  final String? logo;
  final String? description;
  final String? captain;
  final List<dynamic> members;
  final TeamManagerProfile? teamManager;
  final List<String> scouts;
  final String type;
  final bool isVerified;
  final int elo;
  final String? ligue;
  final List<TeamMember>? roster;

  Team({
    required this.id,
    required this.name,
    this.logo,
    this.description,
    this.captain,
    required this.members,
    this.teamManager,
    required this.scouts,
    required this.type,
    required this.isVerified,
    required this.elo,
    this.ligue,
    this.roster,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? json['photo'],
      description: json['description'],
      captain: json['captain'] is Map ? json['captain']['_id'] : json['captain'],
      members: json['members'] ?? [],
      teamManager: json['teamManager'] != null 
          ? TeamManagerProfile.fromJson(json['teamManager']) 
          : null,
      scouts: List<String>.from(json['scouts'] ?? []),
      type: json['type'] ?? 'amateur',
      isVerified: json['isVerified'] ?? false,
      elo: json['elo'] ?? 0,
      ligue: json['ligue']?.toString(),
      roster: json['roster'] != null 
          ? (json['roster'] as List).map((i) => TeamMember.fromJson(i)).toList()
          : null,
    );
  }
}

class TeamMember {
  final String userId;
  final String? nickname;
  final String? avatar;
  final String role;
  final DateTime joinedAt;

  TeamMember({
    required this.userId,
    this.nickname,
    this.avatar,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return TeamMember(
      userId: user is Map ? user['_id'] : user.toString(),
      nickname: user is Map ? user['nickname'] : null,
      avatar: user is Map ? user['avatar'] : null,
      role: json['role'] ?? 'Substitute',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Invitation {
  final String id;
  final dynamic sender;
  final dynamic receiver;
  final dynamic team;
  final String role;
  final String message;
  final String status;
  final DateTime createdAt;

  Invitation({
    required this.id,
    this.sender,
    this.receiver,
    this.team,
    required this.role,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['_id'] ?? '',
      sender: json['sender'],
      receiver: json['receiver'],
      team: json['teamId'],
      role: json['role'] ?? 'Substitute',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class TeamPost {
  final String id;
  final String teamId;
  final dynamic author;
  final String content;
  final DateTime createdAt;

  TeamPost({
    required this.id,
    required this.teamId,
    this.author,
    required this.content,
    required this.createdAt,
  });

  factory TeamPost.fromJson(Map<String, dynamic> json) {
    return TeamPost(
      id: json['_id'] ?? '',
      teamId: json['teamId'] ?? '',
      author: json['authorId'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class TeamComment {
  final String id;
  final String postId;
  final dynamic user;
  final String content;
  final DateTime createdAt;

  TeamComment({
    required this.id,
    required this.postId,
    this.user,
    required this.content,
    required this.createdAt,
  });

  factory TeamComment.fromJson(Map<String, dynamic> json) {
    return TeamComment(
      id: json['_id'] ?? '',
      postId: json['postId'] ?? '',
      user: json['userId'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
