import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics event types
enum AnalyticsEventType {
  // Screen events
  screenView,
  screenLeave,

  // User events
  userLogin,
  userLogout,
  userSignup,

  // Action events
  buttonClick,
  formSubmit,
  search,

  // Business events
  orderCreated,
  orderUpdated,
  paymentProcessed,
  payoutRequested,

  // Shipping events
  shippingRequestCreated,
  shippingStatusChanged,
  trackingGenerated,

  // Error events
  error,
  exception,
}

/// Analytics event
class AnalyticsEvent {
  final String name;
  final AnalyticsEventType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  AnalyticsEvent({
    required this.name,
    required this.type,
    required this.parameters,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.name,
        'parameters': parameters,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'sessionId': sessionId,
        'platform': kIsWeb ? 'web' : 'mobile',
      };
}

/// Analytics service - tracks user events
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _sessionId;
  static String? _currentUserId;

  static const String _collection = 'analytics_events';

  /// Initialize analytics with user session
  static void initialize({String? userId}) {
    _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
    _currentUserId = userId;
  }

  /// Set current user
  static void setUser(String? userId) {
    _currentUserId = userId;
  }

  /// Track an event
  static Future<void> trackEvent(AnalyticsEvent event) async {
    try {
      await _firestore.collection(_collection).add(event.toMap());

      // Also log in debug mode
      if (kDebugMode) {
        debugPrint(
            '[Analytics] ${event.name}: ${event.parameters}');
      }
    } catch (e) {
      debugPrint('[Analytics] Failed to track event: $e');
    }
  }

  /// Track screen view
  static Future<void> trackScreenView(String screenName,
      {String? routeName}) async {
    await trackEvent(AnalyticsEvent(
      name: screenName,
      type: AnalyticsEventType.screenView,
      parameters: {
        if (routeName != null) 'routeName': routeName,
      },
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }

  /// Track button click
  static Future<void> trackButtonClick(String buttonName,
      {String? screen}) async {
    await trackEvent(AnalyticsEvent(
      name: 'button_click_$buttonName',
      type: AnalyticsEventType.buttonClick,
      parameters: {
        'buttonName': buttonName,
        if (screen != null) 'screen': screen,
      },
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }

  /// Track user login
  static Future<void> trackLogin(String method) async {
    await trackEvent(AnalyticsEvent(
      name: 'user_login',
      type: AnalyticsEventType.userLogin,
      parameters: {'method': method},
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }

  /// Track user logout
  static Future<void> trackLogout() async {
    await trackEvent(AnalyticsEvent(
      name: 'user_logout',
      type: AnalyticsEventType.userLogout,
      parameters: {},
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }

  /// Track shipping request
  static Future<void> trackShippingRequestCreated(String requestId) async {
    await trackEvent(AnalyticsEvent(
      name: 'shipping_request_created',
      type: AnalyticsEventType.shippingRequestCreated,
      parameters: {'requestId': requestId},
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }

  /// Track error
  static Future<void> trackError(String error, String stackTrace) async {
    await trackEvent(AnalyticsEvent(
      name: 'error',
      type: AnalyticsEventType.error,
      parameters: {'error': error, 'stackTrace': stackTrace},
      timestamp: DateTime.now(),
      userId: _currentUserId,
      sessionId: _sessionId,
    ));
  }
}

/// Feature flags configuration
class FeatureFlags {
  static final Map<String, bool> _flags = {
    // Enable/disable features
    'enable_dark_mode': false,
    'enable_notifications': true,
    'enable_analytics': true,
    'enable_offline_mode': true,
    'enable_2fa': false,
    'enable_affiliates': true,
    'enable_payouts': true,
    'enable_invoices': true,
    'enable_content_management': true,
    'enable_news_ticker': true,

    // Beta features
    'beta_ai_predictions': false,
    'beta_advanced_reports': false,
    'beta_api_access': false,
  };

  /// Get feature flag value
  static bool isEnabled(String flag) => _flags[flag] ?? false;

  /// Enable a feature flag
  static void enable(String flag) {
    _flags[flag] = true;
  }

  /// Disable a feature flag
  static void disable(String flag) {
    _flags[flag] = false;
  }

  /// Toggle a feature flag
  static void toggle(String flag) {
    _flags[flag] = !(_flags[flag] ?? false);
  }

  /// Get all feature flags
  static Map<String, bool> get all => Map.unmodifiable(_flags);
}

/// Feature flag provider for Riverpod
final featureFlagProvider = Provider.family<bool, String>((ref, flag) {
  return FeatureFlags.isEnabled(flag);
});

/// Feature flag notifier for enabling/disabling
class FeatureFlagNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return FeatureFlags.all;
  }

  void enable(String flag) {
    FeatureFlags.enable(flag);
    state = FeatureFlags.all;
  }

  void disable(String flag) {
    FeatureFlags.disable(flag);
    state = FeatureFlags.all;
  }

  void toggle(String flag) {
    FeatureFlags.toggle(flag);
    state = FeatureFlags.all;
  }
}

final featureFlagNotifierProvider =
    NotifierProvider<FeatureFlagNotifier, Map<String, bool>>(
      FeatureFlagNotifier.new,
    );