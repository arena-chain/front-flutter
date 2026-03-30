import 'package:flutter/foundation.dart';

class ApiConfig {
  // Set to your machine's Wi-Fi IP for physical device testing.
  // Use 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find it.
  static const String _lanIp = '192.168.1.12';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Physical devices need the LAN IP; emulators use 10.0.2.2.
      // Using LAN IP works for both, as long as the server binds to 0.0.0.0.
      return 'http://$_lanIp:3000';
    }
    return 'http://localhost:3000';
  }

  static void printDebugInfo() {
    debugPrint('ApiConfig: kIsWeb=$kIsWeb, platform=$defaultTargetPlatform, baseUrl=$baseUrl');
  }
}
