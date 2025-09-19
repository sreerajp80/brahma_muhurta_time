// File Path: lib/services/app_logger.dart

import 'package:flutter/foundation.dart';

class AppLogger {
  // Only log in debug mode
  static const bool _isLoggingEnabled = kDebugMode;

  // Optional: Add a tag to identify where the log is coming from
  static void log(String message, [String? tag]) {
    if (_isLoggingEnabled) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('${tagPrefix}LOG: $message');
    }
  }

  static void debug(String message, [String? tag]) {
    if (_isLoggingEnabled) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('${tagPrefix}DEBUG: $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (_isLoggingEnabled) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('${tagPrefix}WARNING: $message');
    }
  }

  static void error(String message, [dynamic error, String? tag]) {
    if (_isLoggingEnabled) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final errorInfo = error != null ? ' - Error: $error' : '';
      debugPrint('${tagPrefix}ERROR: $message$errorInfo');
    }
  }

  static void info(String message, [String? tag]) {
    if (_isLoggingEnabled) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('${tagPrefix}INFO: $message');
    }
  }
}
