import 'package:arena_chain_flutter/core/models/feature_auth/player_profile_model.dart';

class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final bool isEmailVerified;
  final String? avatar;
  final String? country;
  final PlayerProfile? profile;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    this.isEmailVerified = false,
    this.avatar,
    this.country,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nickname: (json['nickname'] ?? 'Recruit').toString(),
      role: (json['role'] ?? 'PLAYER').toString(),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      country: json['country'] as String?,
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
      'isEmailVerified': isEmailVerified,
      'avatar': avatar,
      'country': country,
      'profile': profile?.toJson(),
    };
  }
}
