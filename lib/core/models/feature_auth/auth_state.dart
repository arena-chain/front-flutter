/// Enum representing the authentication state of the user
enum AuthState {
  /// User is authenticated and logged in
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
  
  /// Authentication status is being checked
  loading,
}
