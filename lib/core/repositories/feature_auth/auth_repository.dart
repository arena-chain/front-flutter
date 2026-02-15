import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_response_model.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';

/// Repository layer for authentication operations
/// Acts as a single source of truth for authentication data
class AuthRepository {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthRepository({
    AuthApi? authApi,
    TokenStorage? tokenStorage,
  })  : _authApi = authApi ?? AuthApi(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Register a new player
  /// 
  /// Returns [AuthResponse] containing access token, refresh token, and user data
  /// Throws [Exception] if registration fails
  Future<AuthResponse> registerPlayer(RegisterPlayerDto dto) async {
    try {
      final response = await _authApi.registerPlayer(dto);
      if (response.user != null) {
        await _tokenStorage.saveUser(response.user!.toJson());
      }
      return response;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Register a new team manager
  Future<AuthResponse> registerTeamManager(RegisterTeamManagerDto dto) async {
    try {
      final response = await _authApi.registerTeamManager(dto);
      if (response.user != null) {
        await _tokenStorage.saveUser(response.user!.toJson());
      }
      return response;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Login with email and password
  /// 
  /// Returns [AuthResponse] containing access token, refresh token, and user data
  /// Throws [Exception] if login fails
  Future<AuthResponse> login(LoginDto dto) async {
    try {
      final response = await _authApi.login(dto);
      if (response.user != null) {
        await _tokenStorage.saveUser(response.user!.toJson());
      }
      return response;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Logout the current user
  /// 
  /// Clears all stored tokens
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // Continue to clear local storage even if API call fails
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  /// Check if user is currently authenticated
  /// 
  /// Returns true if a valid access token exists
  Future<bool> isAuthenticated() async {
    try {
      return await _tokenStorage.hasToken();
    } catch (e) {
      return false;
    }
  }

  /// Get the current access token
  /// 
  /// Returns the access token or null if not authenticated
  Future<String?> getAccessToken() async {
    try {
      return await _tokenStorage.getAccessToken();
    } catch (e) {
      return null;
    }
  }

  /// Get the current refresh token
  /// 
  /// Returns the refresh token or null if not authenticated
  Future<String?> getRefreshToken() async {
    try {
      return await _tokenStorage.getRefreshToken();
    } catch (e) {
      return null;
    }
  }

  /// Get the current user
  /// 
  /// Returns the user or null if not authenticated or not found
  Future<User?> getUser() async {
    try {
      final userJson = await _tokenStorage.getUser();
      if (userJson != null) {
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
