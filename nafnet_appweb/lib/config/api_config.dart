import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // Set useLocalhostOrEmulator to false and change customBackendUrl 
  // to your computer's LAN IP (e.g. 'http://192.168.1.5:8000') 
  // if you want to test on a physical Android/iOS device.
  static const bool useLocalhostOrEmulator = false;
  static const String customBackendUrl = 'https://duyy435-nafnet.hf.space';

  /// Get base URL dynamically based on platform and emulator/host loopback requirements.
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8000';
      }
      return customBackendUrl.endsWith('/') 
          ? customBackendUrl.substring(0, customBackendUrl.length - 1) 
          : customBackendUrl;
    }

    if (!useLocalhostOrEmulator) {
      return customBackendUrl.endsWith('/') 
          ? customBackendUrl.substring(0, customBackendUrl.length - 1) 
          : customBackendUrl;
    }
    
    try {
      if (Platform.isAndroid) {
        // Android emulator connects to host machine via 10.0.2.2
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Platform check may throw if running in unsupported platform contexts
    }
    
    // Default to localhost for iOS simulator, desktop, and fallback
    return 'http://localhost:8000';
  }

  /// Endpoint for image denoising
  static String get denoiseUrl => '$baseUrl/denoise';
  
  /// Endpoint for server health check
  static String get healthUrl => '$baseUrl/health';

  /// Timeout duration for network requests
  static const Duration timeout = Duration(minutes: 5);
}
