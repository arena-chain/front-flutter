import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/verify_email_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/forgot_password_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/reset_password_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_response_model.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

class AuthApi {
  static const String baseUrl = 'http://192.168.100.34:3000';
  static const Duration _timeout = Duration(seconds: 10);
  final TokenStorage _tokenStorage = TokenStorage();

  Future<AuthResponse> registerPlayer(RegisterPlayerDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/register/player');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse(message: data['message']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<AuthResponse> login(LoginDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _tokenStorage.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Check that the server is running and reachable.');
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        
        if (authResponse.accessToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
        }
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Failed to verify email: $e');
    }
  }

  Future<void> resendOtp(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/resend-otp');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }

  Future<void> forgotPassword(ForgotPasswordDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      ).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
    }
  }

  Future<void> resetPassword(ResetPasswordDto dto) async {
    final url = Uri.parse('$baseUrl/api/auth/reset-password');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      ).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Reset failed');
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<AuthResponse> googleLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/google/mobile');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _tokenStorage.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Google login failed');
      }
    } catch (e) {
      throw Exception('Failed to login with Google: $e');
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-reset-otp');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
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
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
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
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (nickname != null) 'nickname': nickname,
          if (region != null) 'region': region,
          if (avatar != null) 'avatar': avatar,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic userJson = data is Map<String, dynamic> && data['user'] != null
            ? data['user']
            : data;
        return User.fromJson(userJson as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
