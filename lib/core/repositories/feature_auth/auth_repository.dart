import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/verify_email_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/forgot_password_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/reset_password_dto.dart';
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
      // Prevent stale cached role/user from previous session influencing routing.
      await _tokenStorage.clearUser();
      final response = await _authApi.login(dto);

      // Always prefer backend profile as source of truth for role-based routing.
      User? resolvedUser = await getProfile();
      resolvedUser ??= response.user;

      if (resolvedUser != null) {
        await _tokenStorage.saveUser(resolvedUser.toJson());
      } else {
        await _tokenStorage.clearUser();
      }

      return AuthResponse(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        message: response.message,
        user: resolvedUser,
      );
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

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns `true` if the token was refreshed successfully.
  Future<bool> refreshAccessToken() async {
    final client = AuthenticatedClient();
    return client.tryRefreshToken();
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

  /// Get current user from backend profile endpoint and cache it locally.
  Future<User?> getProfile() async {
    try {
      final user = await _authApi.getProfile();
      await _tokenStorage.saveUser(user.toJson());
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Update the current user's profile
  Future<User> updateProfile({
    String? nickname,
    String? region,
    String? avatar,
  }) async {
    // Load the current saved user so we can merge fields
    final existingUserJson = await _tokenStorage.getUser();

    User? updatedUser;
    try {
      updatedUser = await _authApi.updateProfile(
        nickname: nickname,
        region: region,
        avatar: avatar,
      );
    } catch (e) {
      // Backend call failed - still persist locally if we have existing user
      if (existingUserJson != null) {
        final merged = {
          ...existingUserJson,
          if (nickname != null) 'nickname': nickname,
          if (avatar != null) 'avatar': avatar,
        };
        await _tokenStorage.saveUser(merged);
        return User.fromJson(merged);
      }
      throw Exception('Failed to update profile: ${e.toString()}');
    }

    // Backend call succeeded: merge any missing fields from existing data
    final mergedJson = {
      if (existingUserJson != null) ...existingUserJson,
      ...updatedUser.toJson(),
      // If backend didn't return avatar, keep our local one
      'avatar': updatedUser.avatar ?? avatar ?? existingUserJson?['avatar'],
      'nickname': updatedUser.nickname.isNotEmpty
          ? updatedUser.nickname
          : (nickname ?? existingUserJson?['nickname'] ?? 'Player'),
    };
    await _tokenStorage.saveUser(mergedJson);
    return User.fromJson(mergedJson);
  }

  /// Verify email with OTP
  Future<AuthResponse> verifyEmail(VerifyEmailDto dto) async {
    try {
      final response = await _authApi.verifyEmail(dto);
      if (response.user != null) {
        await _tokenStorage.saveUser(response.user!.toJson());
      }
      return response;
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  /// Resend verification OTP
  Future<void> resendOtp(String email) async {
    try {
      await _authApi.resendOtp(email);
    } catch (e) {
      throw Exception('Failed to resend OTP: ${e.toString()}');
    }
  }

  /// Request password reset
  Future<void> forgotPassword(ForgotPasswordDto dto) async {
    try {
      await _authApi.forgotPassword(dto);
    } catch (e) {
      throw Exception('Request failed: ${e.toString()}');
    }
  }

  /// Reset password with OTP
  Future<void> resetPassword(ResetPasswordDto dto) async {
    try {
      await _authApi.resetPassword(dto);
    } catch (e) {
      throw Exception('Reset failed: ${e.toString()}');
    }
  }

  /// Login with Google
  Future<AuthResponse> googleLogin(String idToken) async {
    try {
      await _tokenStorage.clearUser();
      final response = await _authApi.googleLogin(idToken);

      User? resolvedUser = await getProfile();
      resolvedUser ??= response.user;

      if (resolvedUser != null) {
        await _tokenStorage.saveUser(resolvedUser.toJson());
      } else {
        await _tokenStorage.clearUser();
      }

      return AuthResponse(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        message: response.message,
        user: resolvedUser,
      );
    } catch (e) {
      throw Exception('Google login failed: ${e.toString()}');
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    try {
      await _authApi.verifyResetOtp(email, otp);
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString()}');
    }
  }
}
