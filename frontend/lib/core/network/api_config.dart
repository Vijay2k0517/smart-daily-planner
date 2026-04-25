import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  // Physical device uses the PC LAN IP to reach the backend.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    return 'http://10.137.200.250:8000/api/v1';
  }
}
