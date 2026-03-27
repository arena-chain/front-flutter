# 🔧 Troubleshooting Guide - Authentication Errors

## 📱 Current Errors Identified

### Error 1: Registration Connection Timeout
```
Failed to register: ClientException with SocketException: Connection timed out
(OS Error: Connection timed out, errno = 110), address = 10.0.2.2, port = 40438,
url = http://10.0.2.2:3000/feature_auth/register/player
```

### Error 2: Google Sign-In API Exception
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10 , null, null)
```

---

## 🚨 SOLUTION 1: Backend Connection Issues

### Problem
The app cannot connect to your backend server at `http://10.0.2.2:3000`

### Root Causes & Solutions

#### A. Backend Not Running
**Check if backend is running:**
```bash
# In your backend directory
npm run start:dev
# or
yarn start:dev
```

**Verify backend is accessible:**
```bash
# Test from command line
curl http://localhost:3000/feature_auth/login
# Should return method not allowed or similar (not connection refused)
```

#### B. Wrong IP Address for Physical Device

**Current code uses:** `10.0.2.2:3000` (only works for Android Emulator)

**For Physical Device, you need your computer's IP address:**

**Step 1: Find Your Computer's IP**

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# or
ip addr show
# Look for inet address (not 127.0.0.1)
```

**Step 2: Update the Base URL**

Open `lib/core/api/feature_auth/auth_api.dart` and change:

```dart
// OLD (only works for emulator)
static const String baseUrl = 'http://10.0.2.2:3000';

// NEW (for physical device - replace with YOUR IP)
static const String baseUrl = 'http://192.168.1.100:3000';
```

**Step 3: Allow Network Access in Backend**

Make sure your NestJS backend listens on `0.0.0.0` not just `localhost`:

In `main.ts`:
```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors({
    origin: '*', // For development only
    credentials: true,
  });
  
  // Listen on all network interfaces
  await app.listen(3000, '0.0.0.0');
  console.log(`Application is running on: ${await app.getUrl()}`);
}
```

**Step 4: Check Firewall**

**Windows Firewall:**
```powershell
# Allow Node.js through firewall
New-NetFirewallRule -DisplayName "Node.js Server" -Direction Inbound -Program "C:\Program Files\nodejs\node.exe" -Action Allow
```

**Or manually:**
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find Node.js and check both Private and Public

#### C. Backend Endpoints Not Implemented

**Required Backend Endpoints:**

Create or verify these endpoints exist in your NestJS backend:

**1. Registration Endpoint**
```typescript
// auth.controller.ts
@Post('register/player')
async registerPlayer(@Body() dto: RegisterPlayerDto) {
  const user = await this.authService.registerPlayer(dto);
  const tokens = await this.authService.generateTokens(user);
  
  // Send verification email
  await this.mailService.sendVerificationEmail(user.email, otp);
  
  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    user: {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
    },
  };
}
```

**2. Login Endpoint**
```typescript
@Post('login')
async login(@Body() dto: LoginDto) {
  const user = await this.authService.validateUser(dto.email, dto.password);
  const tokens = await this.authService.generateTokens(user);
  
  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    user: {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
    },
  };
}
```

**3. Email Verification Endpoint**
```typescript
@Post('verify-email')
async verifyEmail(@Body() dto: VerifyEmailDto) {
  await this.authService.verifyEmail(dto.email, dto.otp);
  return { message: 'Email verified successfully' };
}
```

**4. Forgot Password Endpoint**
```typescript
@Post('forgot-password')
async forgotPassword(@Body() dto: ForgotPasswordDto) {
  const otp = await this.authService.generatePasswordResetOTP(dto.email);
  await this.mailService.sendPasswordResetEmail(dto.email, otp);
  return { message: 'Reset code sent to email' };
}
```

**5. Reset Password Endpoint**
```typescript
@Post('reset-password')
async resetPassword(@Body() dto: ResetPasswordDto) {
  await this.authService.resetPassword(dto.email, dto.otp, dto.newPassword);
  return { message: 'Password reset successfully' };
}
```

**6. Google Mobile Login Endpoint**
```typescript
@Post('google/mobile')
async googleMobileLogin(@Body() body: { idToken: string }) {
  // Verify the ID token with Google
  const payload = await this.authService.verifyGoogleToken(body.idToken);
  
  // Find or create user
  let user = await this.userService.findByEmail(payload.email);
  if (!user) {
    user = await this.userService.createFromGoogle({
      email: payload.email,
      nickname: payload.name,
      googleId: payload.sub,
      isEmailVerified: true, // Google emails are pre-verified
    });
  }
  
  const tokens = await this.authService.generateTokens(user);
  
  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    user: {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
    },
  };
}
```

**Backend Service Example for Google Token Verification:**
```typescript
// auth.service.ts
import { OAuth2Client } from 'google-auth-library';

export class AuthService {
  private googleClient: OAuth2Client;

  constructor() {
    this.googleClient = new OAuth2Client(
      process.env.GOOGLE_CLIENT_ID,
    );
  }

  async verifyGoogleToken(idToken: string) {
    const ticket = await this.googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    
    return ticket.getPayload();
  }
}
```

**Install required package:**
```bash
npm install google-auth-library
```

---

## 🚨 SOLUTION 2: Google Sign-In Error (Error Code 10)

### Problem
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

**Error Code 10 = DEVELOPER_ERROR** - This means Google Sign-In is not properly configured.

### Solutions

#### A. Get SHA-1 Fingerprint

**Step 1: Generate Debug SHA-1**
```bash
cd android
./gradlew signingReport
```

**Or on Windows:**
```bash
cd android
gradlew.bat signingReport
```

**Step 2: Find SHA-1 in output**
Look for something like:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
SHA-256: ...
```

Copy the **SHA1** value.

#### B. Configure Google Cloud Console

**Step 1: Go to Google Cloud Console**
- Visit: https://console.cloud.google.com/
- Select your project (or create one)

**Step 2: Enable Google Sign-In API**
- Go to "APIs & Services" → "Library"
- Search for "Google Sign-In API" or "Google+ API"
- Click "Enable"

**Step 3: Create OAuth 2.0 Credentials**

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Select "Android"
4. Fill in:
   - **Name**: "Android Client"
   - **Package name**: `com.example.arena_chain_flutter` (get from `android/app/build.gradle`)
   - **SHA-1**: Paste the SHA-1 from Step A

5. Click "Create"

**Step 4: Create Web Client ID (Required for Android)**

1. Click "Create Credentials" → "OAuth 2.0 Client ID" again
2. Select "Web application"
3. Name it "Web Client"
4. Click "Create"
5. **Copy the Client ID** - you'll need this!

**Step 5: Update Flutter Code**

Open `lib/screens/feature_auth/viewmodel/auth_viewmodel.dart` and update:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Add this line with your Web Client ID
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

#### C. Verify Package Name

**Check `android/app/build.gradle`:**
```gradle
android {
    defaultConfig {
        applicationId "com.example.arena_chain_flutter"  // This must match Google Console
        // ...
    }
}
```

**The package name in Google Cloud Console MUST match this exactly!**

#### D. Update Android Manifest (if needed)

**File: `android/app/src/main/AndroidManifest.xml`**

Make sure you have internet permission:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:label="arena_chain_flutter"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

---

## 🧪 Testing Steps

### 1. Test Backend Connectivity

**Create a test file:** `test_backend.dart`
```dart
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(
      Uri.parse('http://YOUR_IP:3000/feature_auth/login'),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
```

Run: `dart test_backend.dart`

### 2. Test Backend Endpoints with Postman/Thunder Client

**Test Registration:**
```
POST http://YOUR_IP:3000/feature_auth/register/player
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123",
  "nickname": "testuser",
  "isPro": false,
  "isVerified": false
}
```

**Expected Response:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "...",
    "email": "test@example.com",
    "nickname": "testuser",
    "role": "player",
    "isEmailVerified": false
  }
}
```

### 3. Verify Google Sign-In Setup

**Test with this command:**
```bash
# Check if package name matches
cd android
./gradlew app:dependencies | grep applicationId
```

---

## 📋 Quick Checklist

### Backend Issues
- [ ] Backend server is running (`npm run start:dev`)
- [ ] Backend listens on `0.0.0.0:3000` (not just localhost)
- [ ] Firewall allows connections on port 3000
- [ ] CORS is enabled in backend
- [ ] All required endpoints are implemented
- [ ] Base URL in `auth_api.dart` matches your setup:
  - Emulator: `http://10.0.2.2:3000`
  - Physical device: `http://YOUR_IP:3000`

### Google Sign-In Issues
- [ ] SHA-1 fingerprint generated
- [ ] OAuth 2.0 Client ID created in Google Cloud Console
- [ ] Package name matches between app and Google Console
- [ ] Web Client ID added to `GoogleSignIn` configuration
- [ ] Google Sign-In API enabled in Google Cloud Console
- [ ] Internet permission in AndroidManifest.xml

---

## 🔍 Debugging Commands

**Check if backend is accessible from device:**
```bash
# On your computer, find IP
ipconfig  # Windows
ifconfig  # Mac/Linux

# Test from phone browser
# Open: http://YOUR_IP:3000
```

**View Flutter logs:**
```bash
flutter logs
```

**Clear app data and rebuild:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Still Having Issues?

### Check Backend Logs
Look for errors in your NestJS console when the request comes in.

### Check Flutter Logs
```bash
flutter logs | grep -i error
```

### Common Backend Errors

**1. "Cannot POST /feature_auth/register/player"**
→ Endpoint not implemented or wrong route

**2. "CORS error"**
→ Add CORS configuration in `main.ts`

**3. "Unauthorized"**
→ Check JWT configuration

**4. "Email already exists"**
→ Use a different email or check database

---

## 🎯 Recommended Next Steps

1. **Fix Backend Connection First**
   - Update base URL for your device
   - Verify backend is running and accessible

2. **Test Basic Login/Register**
   - Once connection works, test without Google Sign-In

3. **Configure Google Sign-In**
   - Follow Google setup steps carefully
   - Test on physical device (emulator may have issues)

4. **Implement Backend Endpoints**
   - Use the code examples provided above
   - Test each endpoint with Postman first

---

**Last Updated:** 2026-02-06
**Status:** Ready for troubleshooting
