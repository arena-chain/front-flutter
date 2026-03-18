import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // Android emulator cannot access localhost directly, needs 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // iOS simulator, Windows, macOS, Linux can use localhost
    return 'http://localhost:3000';
  }

  static void printDebugInfo() {
    print('ApiConfig: kIsWeb=$kIsWeb, defaultTargetPlatform=$defaultTargetPlatform, baseUrl=$baseUrl');
  }
}
