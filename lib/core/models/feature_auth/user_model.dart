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
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      role: json['role'] as String,
      profile: json['profile'] != null
          ? PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>)
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
