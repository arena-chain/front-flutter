import 'package:arena_chain_flutter/core/models/feature_auth/player_profile_model.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';

class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final bool isEmailVerified;
  final String? avatar;
  final String? country;
  final PlayerProfile? profile;
  final TeamManagerProfile? teamManagerProfile;
  final String teamIdValue;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    this.isEmailVerified = false,
    this.avatar,
    this.country,
    this.profile,
    this.teamManagerProfile,
    this.teamIdValue = '',
  });

  String get teamId => teamManagerProfile?.teamId ?? teamIdValue;

  factory User.fromJson(Map<String, dynamic> json) {
    String normalizeRole(String input) {
      return input
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');
    }

    // Handle backend response structure mismatch
    String role = 'unknown';
    if (json['roles'] != null && (json['roles'] as List).isNotEmpty) {
      role = (json['roles'] as List).first.toString();
    } else if (json['role'] != null) {
      role = json['role'] as String;
    }
    role = normalizeRole(role);

    PlayerProfile? playerProfile;
    TeamManagerProfile? teamManagerProfile;
    final profiles = json['profiles'];
    final Map<String, dynamic>? playerProfileData =
        profiles is Map<String, dynamic> && profiles['player'] is Map<String, dynamic>
        ? profiles['player'] as Map<String, dynamic>
        : (json['profile'] is Map<String, dynamic> ? json['profile'] as Map<String, dynamic> : null);
    final Map<String, dynamic>? teamManagerProfileData =
        profiles is Map<String, dynamic> && profiles['team_manager'] is Map<String, dynamic>
        ? profiles['team_manager'] as Map<String, dynamic>
        : (json['teamManagerProfile'] is Map<String, dynamic>
              ? json['teamManagerProfile'] as Map<String, dynamic>
              : null);

    if (role == 'player' && playerProfileData != null) {
      playerProfile = PlayerProfile.fromJson(playerProfileData);
    } else if (role == 'team_manager' && teamManagerProfileData != null) {
      teamManagerProfile = TeamManagerProfile.fromJson(teamManagerProfileData);
    }

    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nickname: (json['nickname'] ?? 'Recruit').toString(),
      role: role,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      country: json['country'] as String?,
      profile: playerProfile,
      teamManagerProfile: teamManagerProfile,
      teamIdValue: (json['teamId'] ?? json['team_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'avatar': avatar,
      'country': country,
      'profile': profile?.toJson(),
      'teamManagerProfile': teamManagerProfile?.toJson(),
      'teamId': teamIdValue,
    };
  }
}
