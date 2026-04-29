# Flutter Authentication Implementation Guide

This document explains the complete authentication implementation for the Flutter app, including OTP verification, password reset, and Google Sign-In.

## 📁 Project Structure

```
lib/
├── core/
│   ├── api/
│   │   └── feature_auth/
│   │       ├── auth_api.dart              # API calls to backend
│   │       ├── google_auth_service.dart   # Google Sign-In helper
│   │       └── token_storage.dart         # Token management
│   ├── dto/
│   │   └── auth/
│   │       ├── login_dto.dart
│   │       ├── register_player_dto.dart
│   │       ├── verify_email_dto.dart      # NEW
│   │       ├── forgot_password_dto.dart   # NEW
│   │       └── reset_password_dto.dart    # NEW
│   ├── models/
│   │   └── feature_auth/
│   │       ├── auth_response_model.dart
│   │       └── user_model.dart            # Updated with isEmailVerified
│   └── repositories/
│       └── feature_auth/
│           └── auth_repository.dart       # Updated with new methods
├── screens/
│   └── feature_auth/
│       ├── ui/
│       │   ├── login_screen.dart          # Updated with Google & Forgot Password
│       │   ├── signup_screen.dart         # Updated with email verification flow
│       │   ├── verify_email_screen.dart   # NEW
│       │   ├── forgot_password_screen.dart # NEW
│       │   └── reset_password_screen.dart # NEW
│       └── viewmodel/
│           └── auth_viewmodel.dart        # Updated with new methods
```

## 🔧 Implementation Details

### 1. Dependencies Added

In `pubspec.yaml`:
```yaml
dependencies:
  google_sign_in: ^6.1.6  # For Google authentication
```

### 2. Data Models

#### User Model Updates
Added `isEmailVerified` field to track email verification status:
```dart
class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final bool isEmailVerified;  // NEW
  final PlayerProfile? profile;
}
```

### 3. API Layer (`auth_api.dart`)

New methods added:
- `verifyEmail(VerifyEmailDto)` - Verify email with OTP
- `forgotPassword(ForgotPasswordDto)` - Request password reset
- `resetPassword(ResetPasswordDto)` - Reset password with OTP
- `googleLogin(String idToken)` - Authenticate with Google ID token

### 4. Repository Layer (`auth_repository.dart`)

Wraps API calls and manages local storage:
- `verifyEmail()` - Updates local user state after verification
- `forgotPassword()` - Requests password reset code
- `resetPassword()` - Resets password with OTP
- `googleLogin()` - Handles Google authentication

### 5. ViewModel Layer (`auth_viewmodel.dart`)

Business logic and state management:
- `verifyEmail(email, otp)` - Returns `bool` for success/failure
- `forgotPassword(email)` - Returns `bool` for success/failure
- `resetPassword(email, otp, newPassword)` - Returns `bool` for success/failure
- `signInWithGoogle()` - Handles complete Google sign-in flow

### 6. UI Screens

#### Verify Email Screen
- Accepts 6-digit OTP code
- Validates input
- Shows success/error messages
- Returns to previous screen on success

#### Forgot Password Screen
- Collects user email
- Requests reset code from backend
- Navigates to Reset Password screen

#### Reset Password Screen
- Accepts OTP code and new password
- Validates password match
- Resets password and returns to login

#### Login Screen Updates
- Added "Forgot Password?" link
- Added Google Sign-In button with divider
- Maintains existing email/password login

#### Signup Screen Updates
- Shows verification prompt after registration
- Allows users to verify immediately or skip
- Navigates to VerifyEmailScreen if user chooses to verify

## 🔄 Authentication Flows

### Email Verification Flow
1. User registers → Backend sends OTP email
2. App shows verification dialog
3. User chooses "Verify Email" → Navigate to `VerifyEmailScreen`
4. User enters 6-digit code
5. App calls `authViewModel.verifyEmail(email, otp)`
6. On success → Navigate back to login

### Forgot Password Flow
1. User clicks "Forgot Password?" on login screen
2. Navigate to `ForgotPasswordScreen`
3. User enters email → Backend sends reset code
4. Navigate to `ResetPasswordScreen`
5. User enters code + new password
6. App calls `authViewModel.resetPassword(email, otp, newPassword)`
7. On success → Navigate to login screen

### Google Sign-In Flow
1. User clicks "Continue with Google"
2. Google Sign-In dialog appears
3. User selects account
4. App receives ID token
5. App calls `authViewModel.signInWithGoogle()`
6. Backend validates token and returns auth response
7. On success → Navigate to home screen

## 🔐 Backend Integration

### Required Backend Endpoints

All endpoints should be prefixed with `/feature_auth`:

```
POST /feature_auth/verify-email
Body: { "email": "user@example.com", "otp": "123456" }
Response: 200/201 on success

POST /feature_auth/forgot-password
Body: { "email": "user@example.com" }
Response: 200/201 on success (sends email)

POST /feature_auth/reset-password
Body: { "email": "user@example.com", "otp": "123456", "newPassword": "newpass" }
Response: 200/201 on success

POST /feature_auth/google/mobile
Body: { "idToken": "google_id_token_here" }
Response: { "accessToken": "...", "refreshToken": "...", "user": {...} }
```

### Base URL Configuration

Update in `auth_api.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:3000';  // Android emulator
// For iOS simulator: 'http://localhost:3000'
// For physical device: 'http://YOUR_IP:3000'
```

## 📱 Google Sign-In Setup

### Android Configuration

1. **Get SHA-1 fingerprint:**
```bash
cd android
./gradlew signingReport
```

2. **Add to Google Cloud Console:**
   - Go to Google Cloud Console
   - Select your project
   - Navigate to "Credentials"
   - Create OAuth 2.0 Client ID for Android
   - Add package name and SHA-1

3. **Update `android/app/build.gradle`:**
```gradle
android {
    defaultConfig {
        applicationId "your.package.name"
    }
}
```

### iOS Configuration

1. **Add to Google Cloud Console:**
   - Create OAuth 2.0 Client ID for iOS
   - Add bundle identifier

2. **Update `ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 🧪 Testing

### Test Email Verification
1. Register a new account
2. Check email for OTP code
3. Enter code in verification screen
4. Verify success message

### Test Forgot Password
1. Click "Forgot Password?" on login
2. Enter registered email
3. Check email for reset code
4. Enter code and new password
5. Login with new password

### Test Google Sign-In
1. Click "Continue with Google"
2. Select Google account
3. Verify navigation to home screen
4. Check that user data is stored

## ⚠️ Important Notes

### Backend Requirements
- The backend must have a `/feature_auth/google/mobile` endpoint that accepts `idToken`
- The existing `/feature_auth/google/redirect` is for web browsers only
- Email service must be configured for OTP delivery

### Error Handling
All methods return user-friendly error messages:
- Network errors
- Invalid OTP codes
- Expired tokens
- Server errors

### Security Considerations
- OTP codes should expire after 10-15 minutes
- Limit OTP verification attempts
- Use HTTPS in production
- Store tokens securely using `shared_preferences`

## 🚀 Next Steps

1. **Run Flutter pub get:**
```bash
flutter pub get
```

2. **Configure Google Sign-In:**
   - Set up OAuth credentials in Google Cloud Console
   - Update Android/iOS configuration files

3. **Update Backend:**
   - Ensure all endpoints are implemented
   - Test with Postman/Thunder Client

4. **Test on Device:**
   - Update base URL for physical device
   - Test all authentication flows

## 📞 Support

For issues or questions:
- Check backend logs for API errors
- Verify Google Cloud Console configuration
- Ensure email service is working
- Check network connectivity

---

**Implementation Status:** ✅ Complete
**Last Updated:** 2026-02-06
