import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_response_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/core/config/api_config.dart';

class AuthApi {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const String baseUrl = 'http://10.0.2.2:3000';
  final TokenStorage _tokenStorage = TokenStorage();

  Future<AuthResponse> registerPlayer(RegisterPlayerDto dto) async {
    final url = Uri.parse('$baseUrl/auth/register/player');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _tokenStorage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<AuthResponse> registerTeamManager(RegisterTeamManagerDto dto) async {
    final url = Uri.parse('$baseUrl/auth/register/team-manager');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      throw Exception('Failed to register team manager: $e');
    }
  }

  Future<AuthResponse> _handleAuthResponse(http.Response response) async {
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Authentication failed');
    }
  }

  Future<AuthResponse> login(LoginDto dto) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}
