import 'dart:developer' as developer;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// AnalyticsService forwards events to Firebase Analytics when available.
/// Call `await AnalyticsService.instance.init()` early in app startup
/// (for example, from main()) to initialize Firebase. If initialization is
/// not performed or fails, events will be logged to the console as a
/// fallback.
class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  FirebaseAnalytics? _fa;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _fa = FirebaseAnalytics.instance;
      _initialized = true;
      developer.log('AnalyticsService: Firebase initialized');
    } catch (e, st) {
      developer.log('AnalyticsService: Firebase init failed: $e',
          error: e, stackTrace: st);
      _initialized = false;
    }
  }

  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    final safeParams = params ?? <String, dynamic>{};
    if (_initialized && _fa != null) {
      try {
        final Map<String, Object?> paramsObjNullable =
            safeParams.map((k, v) => MapEntry(k, v as Object?));
        // Remove null values because FirebaseAnalytics expects Map<String, Object>
        final Map<String, Object> paramsObj = Map.fromEntries(paramsObjNullable
            .entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)));
        await _fa!.logEvent(name: name, parameters: paramsObj);
        return;
      } catch (e, st) {
        developer.log('AnalyticsService: send failed: $e',
            error: e, stackTrace: st);
      }
    }

    // Fallback to console log when Firebase Analytics isn't available.
    developer.log('ANALYTICS_EVENT (fallback): $name ${safeParams.toString()}');
  }
}
