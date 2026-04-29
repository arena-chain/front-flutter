import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_auth/auth_repository.dart';
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/verify_email_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/forgot_password_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/reset_password_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_state.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ViewModel for managing authentication state and operations
/// Uses ChangeNotifier for state management with provider
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web Client ID from the new google-services.json
    clientId: kIsWeb
        ? '114048184741-vavvpvduv2a9lmtql6ak0r23tbvj4lfq.apps.googleusercontent.com'
        : null, // Android uses google-services.json automatically
    scopes: ['email', 'profile', 'openid'],
    // serverClientId is required to get the idToken for the backend
    // But it must be null on Web to avoid assertion error
    serverClientId: kIsWeb ? null : '114048184741-vavvpvduv2a9lmtql6ak0r23tbvj4lfq.apps.googleusercontent.com',
  );

  // State properties
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  AuthState _authState = AuthState.unauthenticated;
  String? _token;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthState get authState => _authState;
  String? get token => _token;

  Future<bool> registerPlayer({
    required String email,
    required String password,
    required String nickname,
    bool isPro = false,
    bool isVerified = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = RegisterPlayerDto(
        email: email,
        password: password,
        nickname: nickname,
        isPro: isPro,
        isVerified: isVerified,
      );

      await _authRepository.registerPlayer(dto);

      // We don't authenticate yet, we wait for OTP verification
      _authState = AuthState.unauthenticated;
      _currentUser = null;

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = LoginDto(email: email, password: password);
      final response = await _authRepository.login(dto);

      _currentUser = response.user;
      _token = response.accessToken;
      _authState = AuthState.authenticated;

      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerTeamManager({
    required String email,
    required String password,
    required String nickname,
    String? organizationName,
    String? firstName,
    String? lastName,
    String? cin,
    int? age,
    String? gender,
    String? description,
    String? phoneNumber,
    String? requestTeamId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = RegisterTeamManagerDto(
        email: email,
        password: password,
        nickname: nickname,
        organizationName: organizationName,
        firstName: firstName,
        lastName: lastName,
        cin: cin,
        age: age,
        gender: gender,
        description: description,
        phoneNumber: phoneNumber,
        requestTeamId: requestTeamId,
      );

      final response = await _authRepository.registerTeamManager(dto);

      _currentUser = response.user;
      _authState = response.user != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;

      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile details permanently synced with backend
  Future<bool> updateProfile({String? nickname, String? avatarUrl}) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authRepository.updateProfile(
        nickname: nickname,
        avatar: avatarUrl,
      );
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Instantly update local profile details (like Avatar) for UI reflection
  void updateLocalProfile({String? nickname, String? avatarUrl}) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        nickname: nickname ?? _currentUser!.nickname,
        role: _currentUser!.role,
        isEmailVerified: _currentUser!.isEmailVerified,
        avatar: avatarUrl ?? _currentUser!.avatar,
        country: _currentUser!.country,
        profile: _currentUser!.profile,
      );
      notifyListeners();
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.logout();
      
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      
      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = VerifyEmailDto(email: email, otp: otp);
      final response = await _authRepository.verifyEmail(dto);

      if (response.accessToken != null) {
        _currentUser = response.user;
        _authState = AuthState.authenticated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend verification OTP
  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.resendOtp(email);
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = ForgotPasswordDto(email: email);
      await _authRepository.forgotPassword(dto);
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password with OTP
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final dto = ResetPasswordDto(email: email, otp: otp, newPassword: newPassword);
      await _authRepository.resetPassword(dto);
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify reset password OTP
  Future<bool> verifyResetOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.verifyResetOtp(email, otp);
      return true;
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      // On Web, idToken is often null, so we fallback to accessToken
      final String? tokenToUse = idToken ?? accessToken;

      if (tokenToUse == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      final response = await _authRepository.googleLogin(tokenToUse);

      _currentUser = response.user;
      _authState = AuthState.authenticated;

      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is currently authenticated
  /// Call this on app startup to restore session
  Future<void> checkAuthStatus() async {
    _authState = AuthState.loading;
    notifyListeners();

    // Add delay to show splash screen
    await Future.delayed(const Duration(seconds: 3));

    try {
      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        _currentUser = await _authRepository.getUser();
        _token = await _authRepository.getAccessToken();
        if (_currentUser != null) {
          _authState = AuthState.authenticated;
        } else {
          // Token exists but user data missing/corrupted
          _authState = AuthState.unauthenticated;
          await _authRepository.logout(); // Clear invalid state
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Extract user-friendly error message from exception string
  String _extractErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    if (error.startsWith('Exception: ')) {
      error = error.substring('Exception: '.length);
    }
    
    // Remove nested "failed: Exception: " patterns
    if (error.contains('failed: Exception: ')) {
      final parts = error.split('failed: Exception: ');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    
    // Remove "Failed to " prefix for cleaner messages
    if (error.startsWith('Registration failed: ') || 
        error.startsWith('Login failed: ') ||
        error.startsWith('Logout failed: ')) {
      final colonIndex = error.indexOf(': ');
      if (colonIndex != -1 && colonIndex + 2 < error.length) {
        return error.substring(colonIndex + 2);
      }
    }
    
    return error;
  }
}
