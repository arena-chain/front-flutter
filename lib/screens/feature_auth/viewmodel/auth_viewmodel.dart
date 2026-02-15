import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_auth/auth_repository.dart';
import 'package:arena_chain_flutter/core/dto/auth/login_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_player_dto.dart';
import 'package:arena_chain_flutter/core/dto/auth/register_team_manager_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_state.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/user_model.dart';

/// ViewModel for managing authentication state and operations
/// Uses ChangeNotifier for state management with provider
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // State properties
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  AuthState _authState = AuthState.unauthenticated;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthState get authState => _authState;

  /// Register a new player
  Future<void> registerPlayer({
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

      final response = await _authRepository.registerPlayer(dto);
      
      // Note: Registration response only contains tokens, not user data
      // We'll set authenticated state but currentUser will be null
      _authState = AuthState.authenticated;
      _currentUser = response.user;
      
      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new team manager
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
      
      _authState = AuthState.authenticated;
      _currentUser = response.user;
      
      notifyListeners();
    } catch (e) {
      _setError(_extractErrorMessage(e.toString()));
      _authState = AuthState.unauthenticated;
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
      final dto = LoginDto(
        email: email,
        password: password,
      );

      final response = await _authRepository.login(dto);
      
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
