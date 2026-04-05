# Quick Start Guide - New Authentication Features

## ✅ What's Been Implemented

### 1. **Email Verification (OTP)**
- ✅ VerifyEmailDto model
- ✅ API endpoint integration (`/feature_auth/verify-email`)
- ✅ Repository method
- ✅ ViewModel method
- ✅ UI Screen (`VerifyEmailScreen`)
- ✅ Integrated into signup flow

### 2. **Forgot Password Flow**
- ✅ ForgotPasswordDto model
- ✅ ResetPasswordDto model
- ✅ API endpoints integration:
  - `/feature_auth/forgot-password`
  - `/feature_auth/reset-password`
- ✅ Repository methods
- ✅ ViewModel methods
- ✅ UI Screens:
  - `ForgotPasswordScreen`
  - `ResetPasswordScreen`
- ✅ Integrated into login screen

### 3. **Google Sign-In**
- ✅ google_sign_in package added
- ✅ GoogleAuthService helper
- ✅ API endpoint integration (`/feature_auth/google/mobile`)
- ✅ Repository method
- ✅ ViewModel method
- ✅ UI button on login screen

### 4. **User Model Updates**
- ✅ Added `isEmailVerified` field
- ✅ Updated fromJson/toJson methods
- ✅ Local storage updates after verification

## 🚀 How to Use

### Email Verification
```dart
// After user registers, navigate to verification screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VerifyEmailScreen(email: userEmail),
  ),
);

// Or call directly from ViewModel
final success = await authViewModel.verifyEmail(email, otpCode);
```

### Forgot Password
```dart
// Navigate to forgot password screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ForgotPasswordScreen(),
  ),
);

// Or call methods directly
await authViewModel.forgotPassword(email);
await authViewModel.resetPassword(email, otp, newPassword);
```

### Google Sign-In
```dart
// Call from ViewModel
await authViewModel.signInWithGoogle();

// The method handles:
// 1. Opening Google Sign-In dialog
// 2. Getting ID token
// 3. Sending to backend
// 4. Storing tokens and user data
```

## 📋 Backend Requirements Checklist

Make sure your NestJS backend has these endpoints:

- [ ] `POST /feature_auth/verify-email`
  ```json
  Request: { "email": "user@example.com", "otp": "123456" }
  Response: 200/201 on success
  ```

- [ ] `POST /feature_auth/forgot-password`
  ```json
  Request: { "email": "user@example.com" }
  Response: 200/201 (sends email with OTP)
  ```

- [ ] `POST /feature_auth/reset-password`
  ```json
  Request: { 
    "email": "user@example.com", 
    "otp": "123456", 
    "newPassword": "newpass123" 
  }
  Response: 200/201 on success
  ```

- [ ] `POST /feature_auth/google/mobile`
  ```json
  Request: { "idToken": "google_id_token_here" }
  Response: { 
    "accessToken": "...", 
    "refreshToken": "...", 
    "user": {...} 
  }
  ```

## ⚙️ Configuration Steps

### 1. Update Base URL
In `lib/core/api/feature_auth/auth_api.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP:3000';
```

### 2. Google Sign-In Setup (Android)

**Step 1:** Get SHA-1 fingerprint
```bash
cd android
./gradlew signingReport
```

**Step 2:** Add to Google Cloud Console
- Create OAuth 2.0 Client ID for Android
- Add package name and SHA-1 fingerprint

**Step 3:** No additional Android configuration needed (handled by package)

### 3. Google Sign-In Setup (iOS)

**Step 1:** Create OAuth 2.0 Client ID for iOS in Google Cloud Console

**Step 2:** Update `ios/Runner/Info.plist`:
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

## 🧪 Testing Checklist

### Email Verification
- [ ] Register new account
- [ ] Receive OTP email
- [ ] Enter correct OTP → Success
- [ ] Enter wrong OTP → Error message
- [ ] Verify `isEmailVerified` is updated

### Forgot Password
- [ ] Click "Forgot Password?" on login
- [ ] Enter email → Receive OTP
- [ ] Enter OTP + new password
- [ ] Login with new password → Success

### Google Sign-In
- [ ] Click "Continue with Google"
- [ ] Select Google account
- [ ] Navigate to home screen
- [ ] User data stored correctly
- [ ] Can logout and login again

## 📱 UI Flow Diagrams

### Signup → Verification Flow
```
SignupScreen
    ↓ (Register)
Success Dialog
    ↓ (Choose "Verify Email")
VerifyEmailScreen
    ↓ (Enter OTP)
LoginScreen
```

### Forgot Password Flow
```
LoginScreen
    ↓ (Click "Forgot Password?")
ForgotPasswordScreen
    ↓ (Enter Email)
ResetPasswordScreen
    ↓ (Enter OTP + New Password)
LoginScreen
```

### Google Sign-In Flow
```
LoginScreen
    ↓ (Click "Continue with Google")
Google Account Picker
    ↓ (Select Account)
PlayerHomeScreen
```

## 🐛 Common Issues & Solutions

### Issue: "Failed to get ID token from Google"
**Solution:** 
- Check Google Cloud Console configuration
- Ensure SHA-1 is correct
- Verify package name matches

### Issue: "Verification failed"
**Solution:**
- Check backend is sending emails
- Verify OTP hasn't expired
- Check email/OTP are correct

### Issue: "Network error"
**Solution:**
- Update base URL for your device
- Check backend is running
- Verify network connectivity

## 📝 Code Examples

### Using in a Custom Screen
```dart
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';

class MyCustomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return ElevatedButton(
      onPressed: () async {
        final success = await authViewModel.verifyEmail(
          'user@example.com',
          '123456',
        );
        
        if (success) {
          // Handle success
        } else {
          // Show error: authViewModel.errorMessage
        }
      },
      child: Text('Verify'),
    );
  }
}
```

### Checking Email Verification Status
```dart
final user = authViewModel.currentUser;
if (user != null && user.isEmailVerified) {
  // User has verified email
} else {
  // Show verification prompt
}
```

## 🔐 Security Notes

- OTP codes should expire after 10-15 minutes on backend
- Limit verification attempts (e.g., 3-5 tries)
- Use HTTPS in production
- Never log sensitive data (passwords, tokens)
- Implement rate limiting on backend

## 📞 Need Help?

1. Check `FLUTTER_AUTH_IMPLEMENTATION.md` for detailed docs
2. Review backend logs for API errors
3. Test endpoints with Postman/Thunder Client
4. Verify Google Cloud Console setup

---

**Status:** ✅ Ready to use
**Dependencies:** ✅ Installed
**Backend Required:** ⚠️ Ensure endpoints are implemented
