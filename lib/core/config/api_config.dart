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
  static const String _lanIp = '192.168.1.47';

  // Set to true when running on an Android emulator, false for a physical device.
  static const bool _isEmulator = false;

  static String _normalizeBaseUrl(String value) =>
      value.replaceAll(RegExp(r'/$'), '');

  static String _ensureApiSuffix(String value) {
    final normalized = _normalizeBaseUrl(value);
    return normalized.endsWith('/api') ? normalized : '$normalized/api';
  }

  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      var normalized = override.replaceAll(RegExp(r'/$'), '');
      // Prevent real devices from trying localhost by mistake via --dart-define.
      if (!kIsWeb) {
        final replacementHost =
            (defaultTargetPlatform == TargetPlatform.android && _isEmulator)
            ? '10.0.2.2'
            : _lanIp;
        normalized = normalized
            .replaceAll('localhost', replacementHost)
            .replaceAll('127.0.0.1', replacementHost);
      }
      return normalized;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulators reach the host machine via 10.0.2.2; physical devices use the LAN IP.
      return _isEmulator ? 'http://10.0.2.2:3000/api' : 'http://$_lanIp:3000/api';
    }
    // iOS/other mobile targets on a physical device also need LAN IP.
    return 'http://$_lanIp:3000/api';
  }

  static String get socketOrigin {
    final normalized = _normalizeBaseUrl(baseUrl);
    return normalized.endsWith('/api')
        ? normalized.substring(0, normalized.length - 4)
        : normalized;
  }

  static void printDebugInfo() {
    debugPrint(
      'ApiConfig: kIsWeb=$kIsWeb, platform=$defaultTargetPlatform, baseUrl=$baseUrl',
    );
  }
}
