import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  // Android emulator uses 10.0.2.2 to reach host machine localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api/v1'
        : 'http://127.0.0.1:8000/api/v1';
  }
}
