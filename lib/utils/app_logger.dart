import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized logging utility for the app
///
/// Usage:
/// - Development: All logs shown
/// - Production: Only errors shown
class AppLogger {
  static const bool _enableDebugLogs = kDebugMode;
  static const bool _enableInfoLogs = kDebugMode;
  static const bool _enableErrorLogs = true; // Always log errors

  /// Log debug information (development only)
  static void debug(String message, [dynamic data]) {
    if (_enableDebugLogs) {
      debugPrint('🔍 DEBUG: $message${data != null ? '\n   Data: $data' : ''}');
    }
  }

  /// Log general information (development only)
  static void info(String message, [dynamic data]) {
    if (_enableInfoLogs) {
      debugPrint('ℹ️ INFO: $message${data != null ? '\n   Data: $data' : ''}');
    }
  }

  /// Log errors (always shown)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_enableErrorLogs) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace:\n$stackTrace');
      }
    }

    // Send to Firebase Crashlytics in production
    if (!kDebugMode && error != null) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      } catch (_) {
        // Fail silently if Crashlytics isn't initialized
      }
    }
  }

  /// Log API requests (development only)
  static void api(String method, String endpoint, [dynamic data]) {
    if (_enableDebugLogs) {
      debugPrint(
          '🌐 API: $method $endpoint${data != null ? '\n   Payload: $data' : ''}');
    }
  }

  /// Log navigation events (development only)
  static void navigation(String route, [Map<String, dynamic>? args]) {
    if (_enableDebugLogs) {
      debugPrint('🧭 NAV: $route${args != null ? '\n   Args: $args' : ''}');
    }
  }

  /// Log analytics events (development only)
  static void analytics(String event, [Map<String, dynamic>? params]) {
    if (_enableDebugLogs) {
      debugPrint(
          '📊 ANALYTICS: $event${params != null ? '\n   Params: $params' : ''}');
    }
  }
}
