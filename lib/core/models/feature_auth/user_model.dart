import 'package:arena_chain_flutter/core/models/feature_auth/player_profile_model.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';

class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final PlayerProfile? playerProfile;
  final TeamManagerProfile? teamManagerProfile;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    this.playerProfile,
    this.teamManagerProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle backend response structure mismatch
    String role = 'unknown';
    if (json['roles'] != null && (json['roles'] as List).isNotEmpty) {
      role = (json['roles'] as List).first.toString();
    } else if (json['role'] != null) {
      role = json['role'] as String;
    }

    // Handle profiles map vs single profile
    Map<String, dynamic>? profileData;
    if (json['profiles'] != null && json['profiles']['player'] != null) {
      profileData = json['profiles']['player'] as Map<String, dynamic>;
    } else if (json['profile'] != null) {
      profileData = json['profile'] as Map<String, dynamic>;
    }

    PlayerProfile? playerProfile;
    TeamManagerProfile? teamManagerProfile;

    if (role == 'player' && profileData != null) {
      playerProfile = PlayerProfile.fromJson(profileData);
    } else if (role == 'team_manager' && profileData != null) {
      teamManagerProfile = TeamManagerProfile.fromJson(profileData);
    }

    return User(
      id: json['id'] as String? ?? json['_id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      role: role,
      playerProfile: playerProfile,
      teamManagerProfile: teamManagerProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'role': role,
      'playerProfile': playerProfile?.toJson(),
      'teamManagerProfile': teamManagerProfile?.toJson(),
    };
  }
}
