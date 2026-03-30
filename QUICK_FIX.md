# 🚨 QUICK FIX - Authentication Errors

## Your Current Errors

### ❌ Error 1: Connection Timeout
```
Failed to register: ClientException with SocketException: Connection timed out
url = http://10.0.2.2:3000/feature_auth/register/player
```

### ❌ Error 2: Google Sign-In Failed
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

---

## ⚡ IMMEDIATE FIXES

### Fix 1: Update Base URL for Physical Device

**You're using a physical device, so `10.0.2.2` won't work!**

**Step 1: Find your computer's IP address**

Windows PowerShell:
```powershell
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100`)

**Step 2: Update Flutter code**

Open: `lib/core/api/feature_auth/auth_api.dart`

Change line 13:
```dart
// OLD - Only works for Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000';

// NEW - Replace with YOUR computer's IP
static const String baseUrl = 'http://192.168.1.19:3000';  // Use YOUR IP!
```

**Step 3: Make sure backend allows external connections**

In your NestJS `main.ts`:
```typescript
await app.listen(3000, '0.0.0.0');  // Not just 'localhost'!
```

**Step 4: Restart app**
```bash
flutter run
```

---

### Fix 2: Configure Google Sign-In

**The error code 10 means Google Sign-In is not configured.**

**Quick Steps:**

1. **Get SHA-1 fingerprint:**
```bash
cd android
./gradlew signingReport
```
Copy the SHA1 value.

2. **Go to Google Cloud Console:**
   - https://console.cloud.google.com/
   - Create/Select project
   - Go to "Credentials"

3. **Create Android OAuth Client:**
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Type: Android
   - Package name: `com.example.arena_chain_flutter` (from `android/app/build.gradle`)
   - SHA-1: Paste your SHA-1
   - Click "Create"

4. **Create Web OAuth Client (Required!):**
   - Click "Create Credentials" → "OAuth 2.0 Client ID" again
   - Type: Web application
   - Name: "Web Client"
   - Click "Create"
   - **Copy the Client ID!**

5. **Update Flutter code:**

Open: `lib/screens/feature_auth/viewmodel/auth_viewmodel.dart`

Find line ~17 and update:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',  // ADD THIS!
);
```

6. **Rebuild app:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Verify Backend is Running

**Test from your phone's browser:**
1. Open browser on your phone
2. Go to: `http://YOUR_IP:3000`
3. You should see something (not "can't connect")

**Test from computer:**
```bash
curl http://localhost:3000/feature_auth/login
# Should return error (not connection refused)
```

---

## 📋 Quick Checklist

### Backend Connection
- [ ] Backend is running (`npm run start:dev`)
- [ ] Backend listens on `0.0.0.0:3000`
- [ ] Found computer's IP address
- [ ] Updated `baseUrl` in `auth_api.dart` with YOUR IP
- [ ] Phone and computer on same WiFi network
- [ ] Firewall allows port 3000

### Google Sign-In
- [ ] Generated SHA-1 fingerprint
- [ ] Created Android OAuth Client in Google Console
- [ ] Created Web OAuth Client in Google Console
- [ ] Added `serverClientId` to `GoogleSignIn` in code
- [ ] Package name matches in Google Console and `build.gradle`
- [ ] Rebuilt app after changes

---

## 🎯 Test Order

1. **Fix backend connection first**
   - Update IP address
   - Test basic registration without Google

2. **Then fix Google Sign-In**
   - Configure Google Console
   - Add serverClientId
   - Test Google login

---

## 📞 Still Not Working?

### Backend Connection Issues
- Check if backend is actually running
- Try accessing `http://YOUR_IP:3000` from phone browser
- Check Windows Firewall settings
- Make sure phone and computer are on same network

### Google Sign-In Issues
- Double-check package name matches exactly
- Verify SHA-1 is correct
- Make sure you created BOTH Android AND Web OAuth clients
- Try on a different Google account

---

## 📚 Full Documentation

For detailed guides, see:
- `TROUBLESHOOTING_AUTH.md` - Complete troubleshooting guide
- `BACKEND_IMPLEMENTATION.md` - Full backend code
- `FLUTTER_AUTH_IMPLEMENTATION.md` - Architecture details
- `QUICK_START_AUTH.md` - Feature usage guide

---

## 🔧 Most Common Mistake

**Using `10.0.2.2` on a physical device!**

This IP only works for Android Emulator. For physical devices, you MUST use your computer's actual IP address (like `192.168.1.100`).

---

**Priority:** Fix backend connection first, then Google Sign-In!
