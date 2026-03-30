import 'package:flutter/foundation.dart';

class ApiConfig {
  // Set to your machine's Wi-Fi IP for physical device testing.
  // Use 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find it.
  static const String _lanIp = '192.168.1.12';

  // Set to true when running on an Android emulator, false for a physical device.
  static const bool _isEmulator = true;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulators reach the host machine via 10.0.2.2; physical devices use the LAN IP.
      return _isEmulator ? 'http://10.0.2.2:3000' : 'http://$_lanIp:3000';
    }
    return 'http://localhost:3000';
  }

  static void printDebugInfo() {
    debugPrint('ApiConfig: kIsWeb=$kIsWeb, platform=$defaultTargetPlatform, baseUrl=$baseUrl');
  }
}
