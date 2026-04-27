import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/verify_email_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/forgot_password_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/reset_password_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_response_model.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/core/config/api_config.dart';

class AuthApi {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 10);
  final TokenStorage _tokenStorage = TokenStorage();
  String? _workingBaseUrl;

  /// Throws if the body is HTML (common when the wrong server/port is hit on Web).
  static dynamic _decodeResponseBody(http.Response response) {
    final body = response.body;
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<')) {
      throw FormatException(
        'Server returned HTML instead of JSON (HTTP ${response.statusCode}). '
        'Expected your REST API at $baseUrl. On Flutter Web, set the correct URL with '
        '--dart-define=API_BASE_URL=http://HOST:PORT (see ApiConfig), ensure CORS allows '
        'this browser origin, and avoid running a non-API service on the same port.',
      );
    }
    if (body.isEmpty) {
      throw const FormatException('Empty response body from server.');
    }
    return jsonDecode(body);
  }

  List<String> _candidateBaseUrls() {
    final candidates = <String>[
      if (_workingBaseUrl case final String working) working,
      baseUrl,
    ];
    if (kIsWeb) {
      candidates.addAll(['http://127.0.0.1:3000', 'http://localhost:3000']);
    }
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<http.Response> _postWithFallback({
    required String path,
    required Map<String, String> headers,
    required String body,
  }) async {
    Exception? lastError;
    for (final candidate in _candidateBaseUrls()) {
      try {
        final response = await http
            .post(Uri.parse('$candidate$path'), headers: headers, body: body)
            .timeout(_timeout);
        if (response.statusCode < 500) {
          _workingBaseUrl = candidate;
        }
        return response;
      } on SocketException {
        lastError = Exception('Network unreachable on $candidate');
      } on TimeoutException {
        lastError = Exception('Connection timed out on $candidate');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach auth backend.');
  }

  Future<AuthResponse> registerPlayer(RegisterPlayerDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/register/player');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _decodeResponseBody(response);
        return AuthResponse(message: data['message']);
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<AuthResponse> registerTeamManager(RegisterTeamManagerDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/register/team-manager');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _decodeResponseBody(response);
        return AuthResponse.fromJson(data);
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<AuthResponse> login(LoginDto dto) async {
    try {
      final response = await _postWithFallback(
        path: '/api/auth/login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeResponseBody(response);
        final authResponse = AuthResponse.fromJson(data);
        await _tokenStorage.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
        return authResponse;
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<AuthResponse> verifyEmail(VerifyEmailDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-email');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeResponseBody(response);
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.accessToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
        }
        return authResponse;
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Failed to verify email: $e');
    }
  }

  Future<void> resendOtp(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/resend-otp');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }

  Future<void> forgotPassword(ForgotPasswordDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  Future<void> resetPassword(ResetPasswordDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/reset-password');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dto.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Reset failed');
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<AuthResponse> googleLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/google/mobile');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeResponseBody(response);
        final authResponse = AuthResponse.fromJson(data);
        await _tokenStorage.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
        return authResponse;
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Google login failed');
      }
    } catch (e) {
      throw Exception('Failed to login with Google: $e');
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-reset-otp');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<User> getProfile() async {
    final url = Uri.parse('$baseUrl/api/auth/profile');
    final token = await _tokenStorage.getAccessToken();

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _decodeResponseBody(response);
        return User.fromJson(data);
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<User> updateProfile({
    String? nickname,
    String? region,
    String? avatar,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/profile');
    final token = await _tokenStorage.getAccessToken();

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (nickname case final String n) 'nickname': n,
              if (region case final String r) 'region': r,
              if (avatar case final String a) 'avatar': a,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _decodeResponseBody(response);
        final dynamic userJson =
            data is Map<String, dynamic> && data['user'] != null
            ? data['user']
            : data;
        return User.fromJson(userJson as Map<String, dynamic>);
      } else {
        final error = _decodeResponseBody(response);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
