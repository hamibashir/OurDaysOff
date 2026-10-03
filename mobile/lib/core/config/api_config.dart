import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String apiVersion = 'v1';

  /// Resolves the default base URL based on platform and environment
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/$apiVersion';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine loopback in standard Android emulator
      return 'http://10.0.2.2:8000/api/$apiVersion';
    }
    // iOS Simulator, macOS, Windows
    return 'http://127.0.0.1:8000/api/$apiVersion';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
