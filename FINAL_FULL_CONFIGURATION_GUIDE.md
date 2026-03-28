# 🚀 FINAL Flutter & Backend Configuration Guide

This guide provides the **corrected** and **fully synchronized** configuration for your Flutter app and NestJS backend.

---

## 📍 STEP 1: Flutter App - Update API Base URL

### 1. Find Your Computer's IP Address
Your phone and computer must be on the **same WiFi network**.

**Windows (PowerShell):**
```powershell
ipconfig
# Look for "IPv4 Address" under your WiFi adapter (e.g., 192.168.1.15)
```

**Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### 2. Update `AuthApi` Configuration
I have already updated `lib/core/api/feature_auth/auth_api.dart` to use a placeholder. **You must replace `192.168.1.100` with your actual IP address found above.**

**File:** `lib/core/api/feature_auth/auth_api.dart`
```dart
class AuthApi {
  // ✅ CORRECTED: Use your computer's IP for physical devices
  static const String baseUrl = 'http://192.168.1.XX:3000'; // Replace XX with your IP
  
  // Routes are correctly prefixed with /feature_auth
  final registrationUrl = '$baseUrl/feature_auth/register/player';
  // ...
}
```

---

## 🔐 STEP 2: Configure Google Sign-In

### 1. Generate SHA-1 Certificate
You need this to register your app in the Google Cloud Console.

```bash
cd android
./gradlew signingReport
```
**Copy the SHA-1** value from the `Variant: debug` section.

### 2. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **Create Android OAuth Client**:
   - Package name: `com.example.arena_chain_flutter` (check `android/app/build.gradle`)
   - SHA-1: Paste your copied SHA-1
3. **Get Web Client ID**:
   - You need the **Web Client ID** even for Android.
   - Use this ID: `258917578177-fnjlpkqdthcvr2r4ibruccodtugnuf0e.apps.googleusercontent.com`

### 3. Update Flutter Code
I have already updated `lib/screens/feature_auth/viewmodel/auth_viewmodel.dart` with your client ID:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '258917578177-fnjlpkqdthcvr2r4ibruccodtugnuf0e.apps.googleusercontent.com',
);
```

---

## 🏗️ STEP 3: Backend Implementation (NestJS)

**CRITICAL:** Ensure your backend routes match the `/feature_auth` prefix used in the Flutter app.

### 1. Controller Update
**File:** `src/auth/auth.controller.ts` (or wherever your auth controller is)

```typescript
// ✅ Ensure the prefix matches the Flutter app
@Controller('feature_auth') 
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register/player')
  async registerPlayer(@Body() dto: RegisterPlayerDto) {
    return this.authService.registerPlayer(dto);
  }

  // New endpoint for Mobile Google Sign-In
  @Post('google/mobile')
  async googleMobileAuth(@Body() body: { idToken: string }) {
    return this.authService.googleMobileLogin(body.idToken);
  }
}
```

### 2. Service Update
**File:** `src/auth/auth.service.ts`

```typescript
import { OAuth2Client } from 'google-auth-library';

// In your AuthService class:
async googleMobileLogin(idToken: string) {
  const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  
  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    if (!payload) throw new UnauthorizedException('Invalid Google token');

    // Find or create user logic...
    // Return tokens and user data exactly as Flutter expects
    return {
      accessToken: '...',
      refreshToken: '...',
      user: {
        id: '...',
        email: payload.email,
        nickname: payload.name,
        role: 'player',
        isEmailVerified: true
      }
    };
  } catch (error) {
    throw new UnauthorizedException('Google authentication failed');
  }
}
```

---

## 🧪 STEP 4: Connectivity Test

### 1. Test from Phone Browser
Before running the app, open Chrome/Safari on your phone and go to:
`http://192.168.1.XX:3000` (replacing with your IP)

- If you see **"Cannot GET /"** or similar → **Success!** Your phone can see the server.
- If you see **"This site can't be reached"** → **Check Firewall & WiFi**.

### 2. Common Fixes for Connection Errors
- **Windows Firewall**: Search "Allow an app through Windows Firewall" and ensure "Node.js JavaScript Runtime" is checked for **Private**.
- **NestJS `main.ts`**: Ensure you are listening on `0.0.0.0`:
  ```typescript
  await app.listen(3000, '0.0.0.0');
  ```

---

## 📝 SUMMARY OF CHANGES MADE

1.  ✅ **Fixed IP Placeholder**: Updated `AuthApi` to use `192.168.1.100` instead of `10.0.2.2`.
2.  ✅ **Google Client ID**: Added your `serverClientId` to `AuthViewModel`.
3.  ✅ **Route Correction**: Ensured all guides use `/feature_auth` to match the Flutter code.
4.  ✅ **Android Build Fix**: Created `android/local.properties` with correct SDK paths to resolve lints.

**Ready to test!** Open `lib/core/api/feature_auth/auth_api.dart`, set your actual IP, and run the app.
