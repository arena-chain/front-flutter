import 'package:arena_chain_flutter/core/models/feature_auth/player_profile_model.dart';

class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final PlayerProfile? profile;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    this.profile,
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

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      role: role,
      profile: profileData != null
          ? PlayerProfile.fromJson(profileData)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'role': role,
      'profile': profile?.toJson(),
    };
  }
}
