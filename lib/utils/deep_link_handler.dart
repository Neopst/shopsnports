import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Minimal DeepLinkHandler for ShopsNSports
///
/// This implementation provides a one-shot initial link read via a
/// platform MethodChannel implemented in Android `MainActivity`.
/// It avoids adding heavy deep-link dependencies and handles the
/// common case where the OS opens the app via an app-scheme URL.
///
/// Supported deep link patterns:
/// - myapp://payment-success?provider=X&reference=Y (payment redirects)
/// - myapp://affiliate?code=X (affiliate invitation links)
/// - myapp://product?id=X (product deep links)
///
/// Usage:
/// ```dart
/// final link = await DeepLinkHandler.getInitialLink();
/// if (link != null) {
///   // Handle deep link navigation
/// }
/// ```
class DeepLinkHandler {
  static const MethodChannel _channel = MethodChannel('shopsnports/deeplink');
  static bool _initialized = false;

  /// Return the initial launch link string (or null) if the OS opened the
  /// app via an app-scheme URL. This method does not perform navigation so
  /// callers can safely use their BuildContext to navigate after awaiting.
  ///
  /// This method can only be called once. Subsequent calls will return null.
  static Future<String?> getInitialLink() async {
    if (_initialized) {
      AppLogger.debug('DeepLinkHandler: Already initialized, returning null');
      return null;
    }
    _initialized = true;

    try {
      AppLogger.debug('DeepLinkHandler: Requesting initial link from platform');
      final dynamic result = await _channel.invokeMethod('getInitialLink');
      final String? uriString = result as String?;

      if (uriString == null || uriString.isEmpty) {
        AppLogger.debug('DeepLinkHandler: No initial link found');
        return null;
      }

      AppLogger.info('DeepLinkHandler: Initial link received: $uriString');
      return uriString;
    } on PlatformException catch (e) {
      AppLogger.error(
        'DeepLinkHandler: Platform error while getting initial link',
        e,
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'DeepLinkHandler: Unexpected error getting initial link',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Parse a deep link URI and extract its components
  static Map<String, dynamic>? parseDeepLink(String uriString) {
    try {
      final uri = Uri.parse(uriString);

      if (uri.scheme != 'myapp') {
        AppLogger.debug('DeepLinkHandler: Invalid scheme: ${uri.scheme}');
        return null;
      }

      return {
        'scheme': uri.scheme,
        'host': uri.host,
        'path': uri.path,
        'params': uri.queryParameters,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'DeepLinkHandler: Failed to parse deep link',
        e,
        stackTrace,
      );
      return null;
    }
  }

  static void dispose() {
    // No persistent listeners to remove in this minimal implementation.
    AppLogger.debug('DeepLinkHandler: Disposed');
  }
}
