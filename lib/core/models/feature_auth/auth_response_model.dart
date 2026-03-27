import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';

class AuthResponse {
  final String? accessToken;
  final String? refreshToken;
  final String? message;
  final User? user;

  AuthResponse({
    this.accessToken,
    this.refreshToken,
    this.message,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      message: json['message'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (message != null) 'message': message,
      if (user != null) 'user': user?.toJson(),
    };
  }
}
