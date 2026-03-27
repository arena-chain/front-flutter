import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Google Sign-In operations
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '258917578177-fnjlpkqdthcvr2r4ibruccodtugnuf0e.apps.googleusercontent.com',
    serverClientId: kIsWeb ? null : '258917578177-fnjlpkqdthcvr2r4ibruccodtugnuf0e.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and return the ID token
  /// Returns null if the user cancels the sign-in
  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return googleAuth.idToken;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore sign-out errors
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get the current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
