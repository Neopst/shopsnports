// lib/core/utils/app_logger.dart
import 'package:flutter/foundation.dart';

/// Application logger - replaces print() statements
class AppLogger {
  static bool _isDebugMode = kDebugMode;

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (_isDebugMode) {
      _log('DEBUG', message, tag);
    }
  }

  /// Log info messages
  static void info(String message, {String? tag}) {
    _log('INFO', message, tag);
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    _log('WARNING', message, tag);
  }

  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag);
    if (error != null) {
      _log('ERROR', 'Error: $error', tag);
    }
    if (stackTrace != null && _isDebugMode) {
      _log('ERROR', 'StackTrace: $stackTrace', tag);
    }
  }

  /// Log critical messages
  static void critical(String message, {String? tag}) {
    _log('CRITICAL', message, tag);
  }

  /// Firebase-specific logging
  static void firebase(String message, {String? tag}) {
    _log('FIREBASE', message, tag ?? 'Firebase');
  }

  /// Auth logging
  static void auth(String message, {String? tag}) {
    _log('AUTH', message, tag ?? 'Auth');
  }

  /// API logging
  static void api(String message, {String? tag}) {
    _log('API', message, tag ?? 'API');
  }

  static void _log(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final logMessage = '[$timestamp] [$level] $tagStr$message';

    // In debug mode, print to console
    if (_isDebugMode) {
      debugPrint(logMessage);
    }
  }

  /// Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }
}