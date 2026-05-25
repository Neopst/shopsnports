import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Firebase Cloud Messaging Service for Admin Dashboard
class FCMNotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Streams for UI to listen to incoming messages and taps
  final StreamController<Map<String, dynamic>> _onMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _onTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Firebase listener subscriptions for proper cleanup
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  /// Initialize FCM and setup listeners
  Future<bool> initialize(String userId) async {
    if (userId.isEmpty) {
      debugPrint('❌ FCM: Invalid userId provided');
      return false;
    }

    try {
      // Request permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ FCM: Permission granted');

        // Get and store FCM token
        await _updateFCMToken(userId);

        // Listen for token refresh
        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
          (newToken) => _storeFCMToken(userId, newToken),
          onError: (e) => debugPrint('❌ FCM: Token refresh error: $e'),
        );

        // Setup foreground message handler
        _foregroundSubscription = FirebaseMessaging.onMessage.listen(
          _handleForegroundMessage,
          onError: (e) => debugPrint('❌ FCM: Foreground listener error: $e'),
        );

        // Setup notification tap handler (when app in background/terminated)
        _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
          _handleNotificationTap,
          onError: (e) => debugPrint('❌ FCM: onMessageOpenedApp error: $e'),
        );

        debugPrint('✅ FCM: Initialized for user $userId');
        return true;
      } else {
        debugPrint('⚠️ FCM: Permission denied or not determined');
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ FCM: Platform error during initialization: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('❌ FCM: Failed to initialize: $e');
      return false;
    }
  }

  /// Get FCM token and store in Firestore
  Future<void> _updateFCMToken(String userId) async {
    try {
      final vapidKey = _getVapidKey();
      final token = await _messaging.getToken(vapidKey: vapidKey);

      if (token != null && token.isNotEmpty) {
        await _storeFCMToken(userId, token);
      }
    } catch (e) {
      debugPrint('❌ FCM: Failed to get token: $e');
    }
  }

  /// Get VAPID key from environment or return null for non-web
  String? _getVapidKey() {
    if (!kIsWeb) return null;

    // For web, you should set this via firebase options or environment
    // In production, use: FirebaseMessaging.instance.getToken(vapidKey: 'your-vapid-key')
    // The vapid key should be configured in your firebase_options.dart
    return null;
  }

  /// Store FCM token in Firestore
  Future<void> _storeFCMToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) {
      debugPrint('❌ FCM: Invalid userId or token for storage');
      return;
    }

    try {
      await _firestore.collection(_usersCollection).doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ FCM: Token stored for user $userId');
    } catch (e) {
      debugPrint('❌ FCM: Failed to store token: $e');
    }
  }

  /// Handle foreground notifications (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 FCM: Foreground message received');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    try {
      final payload = {
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
      };

      // Broadcast to any UI listeners
      _onMessageController.add(payload);

      // Persist in Firestore if a target userId is supplied in data
      _persistNotificationFromFcm(message, payload, isRead: false);
    } catch (e) {
      debugPrint('❌ FCM: Error handling foreground message: $e');
    }
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 FCM: Notification tapped');
    debugPrint('  Data: ${message.data}');

    try {
      final payload = {
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
      };

      // Broadcast tap event for the app to handle navigation
      _onTapController.add(payload);

      // Persist tap event for analytics
      _persistNotificationFromFcm(message, payload, isRead: true, event: 'tapped');
    } catch (e) {
      debugPrint('❌ FCM: Error handling notification tap: $e');
    }
  }

  /// Persist notification from FCM to Firestore with correct field names
  Future<void> _persistNotificationFromFcm(
    RemoteMessage message,
    Map<String, dynamic> payload, {
    required bool isRead,
    String? event,
  }) async {
    final targetUser = message.data['userId'] ?? message.data['uid'];
    if (targetUser == null || targetUser.toString().isEmpty) {
      debugPrint('⚠️ FCM: No target user for persistence');
      return;
    }

    try {
      final notificationData = {
        'userId': targetUser.toString(),
        'type': message.data['type'] ?? 'system',
        'category': message.data['category'] ?? 'system',
        'title': payload['title'],
        'message': payload['body'],
        'actionUrl': message.data['actionUrl'],
        'metadata': message.data, // Use 'metadata' to match Notification model
        'isRead': isRead,
        'priority': message.data['priority'] ?? 'normal',
        if (event != null) 'event': event,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_notificationsCollection).add(notificationData);
      debugPrint('✅ FCM: Notification persisted for user $targetUser');
    } catch (e) {
      debugPrint('❌ FCM: Failed to persist notification: $e');
    }
  }

  /// Stream of incoming foreground message payloads
  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;

  /// Stream of notification tap payloads
  Stream<Map<String, dynamic>> get onTap => _onTapController.stream;

  /// Dispose streams and cancel listeners when no longer needed
  void dispose() {
    debugPrint('🔄 FCM: Disposing service and canceling listeners');

    try {
      _foregroundSubscription?.cancel();
      _foregroundSubscription = null;

      _onMessageOpenedAppSubscription?.cancel();
      _onMessageOpenedAppSubscription = null;

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      _onMessageController.close();
      _onTapController.close();

      debugPrint('✅ FCM: Service disposed successfully');
    } catch (e) {
      debugPrint('❌ FCM: Error disposing service: $e');
    }
  }

  /// Subscribe to topic (e.g., 'admins', 'super_admins')
  Future<bool> subscribeToTopic(String topic) async {
    if (topic.isEmpty) {
      debugPrint('❌ FCM: Empty topic provided');
      return false;
    }

    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ FCM: Subscribed to topic: $topic');
      return true;
    } catch (e) {
      debugPrint('❌ FCM: Failed to subscribe to topic $topic: $e');
      return false;
    }
  }

  /// Unsubscribe from topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (topic.isEmpty) {
      debugPrint('❌ FCM: Empty topic provided');
      return false;
    }

    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ FCM: Unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      debugPrint('❌ FCM: Failed to unsubscribe from topic $topic: $e');
      return false;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ FCM: Failed to get token: $e');
      return null;
    }
  }

  /// Delete FCM token (on logout)
  Future<bool> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('✅ FCM: Token deleted');
      return true;
    } catch (e) {
      debugPrint('❌ FCM: Failed to delete token: $e');
      return false;
    }
  }
}
