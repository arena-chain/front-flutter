import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Optional override for every platform (especially Flutter Web).
  ///
  /// Run with:
  /// `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000`
  ///
  /// Use this when port 3000 is used by another process (e.g. a WebSocket relay)
  /// or when your REST API listens on a different host/port.
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Set to your machine's Wi-Fi IP for physical device testing.
  // Use 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find it.
  static const String _lanIp = '192.168.1.12';

  // Set to true when running on an Android emulator, false for a physical device.
  static const bool _isEmulator = true;

  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/$'), '');
    }
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
