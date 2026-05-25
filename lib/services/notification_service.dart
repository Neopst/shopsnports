import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Unified NotificationService for push notifications.
///
/// Combines functionality from both NotificationService and PushNotificationService:
/// - Permission tracking with SharedPreferences
/// - FCM token management and Firestore storage
/// - Topic subscription management
/// - Foreground message handling with in-app dialogs
/// - Background message handling with navigation
/// - Initial message retrieval for app launch from terminated state
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  // SharedPreferences keys for permission tracking
  static const String _hasAskedPermissionKey = 'has_asked_push_permission';
  static const String _permissionGrantedKey = 'push_permission_granted';

  // Navigator key set by the app so the service can show in-app dialogs
  GlobalKey<NavigatorState>? _navigatorKey;

  // Access the messaging instance lazily to avoid plugin registration timing
  // issues during hot-reload/hot-restart in development.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Check if we have already asked for push notification permission
  Future<bool> hasAskedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasAskedPermissionKey) ?? false;
  }

  /// Mark that we have asked for permission
  Future<void> markAsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAskedPermissionKey, true);
  }

  /// Reset the "asked" flag - typically called on logout
  Future<void> resetAskedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasAskedPermissionKey);
  }

  /// Check if permission was granted
  Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionGrantedKey) ?? false;
  }

  /// Request push notification permission
  /// Returns true if granted, false if denied
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionGrantedKey, granted);
      await markAsAsked();

      if (granted) {
        await registerToken();
      }

      AppLogger.debug('Push notification permission: ${granted ? 'granted' : 'denied'}');

      return granted;
    } catch (e) {
      AppLogger.error('Error requesting push notification permission', e);
      return false;
    }
  }

  /// Register FCM token with Firestore for targeted notifications
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        AppLogger.debug('FCM token is null');
        return;
      }

      AppLogger.debug('FCM token retrieved: ${token.substring(0, 20)}...');

      // Save to Firestore via _saveTokenToFirestore method
      await _saveTokenToFirestore(token);
    } catch (e) {
      AppLogger.error('Error getting FCM token', e);
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Error getting FCM token', e);
      return null;
    }
  }

  /// Unregister FCM token (on logout or disable notifications)
  Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionGrantedKey, false);

      AppLogger.debug('FCM token unregistered');
    } catch (e) {
      AppLogger.error('Error unregistering FCM token', e);
    }
  }

  /// Check if app was opened from terminated state via notification
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _messaging.getInitialMessage();
    } catch (e) {
      AppLogger.error('Error getting initial message', e);
      return null;
    }
  }

  Future<void> init() async {
    try {
      try {
        // Request permissions where necessary
        await _messaging.requestPermission(
            alert: true, badge: true, sound: true);
      } on MissingPluginException catch (e) {
        AppLogger.debug('NotificationService.init MissingPluginException', e);
        // Early return — plugin not available in this environment (e.g. test harness)
        return;
      }

      // 1. Generate and save FCM token to Firestore (for targeted notifications)
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          AppLogger.debug('FCM token generated', token);
          await _saveTokenToFirestore(token);
        }

        // Listen for token refresh and save new tokens
        _messaging.onTokenRefresh.listen((newToken) {
          AppLogger.debug('FCM token refreshed', newToken);
          _saveTokenToFirestore(newToken);
        });
      } catch (tokenError) {
        AppLogger.error('FCM token generation error', tokenError);
      }

      // 2. Handle foreground messages (app in foreground)
      // Listen for foreground messages and show a simple in-app popup
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          try {
            _showForegroundNotification(message);
          } catch (e) {
            AppLogger.error('onMessage handling error', e);
          }
        });
      } catch (e) {
        AppLogger.error('Failed to attach onMessage listener', e);
      }

      // 3. Handle background message opening (user taps notification from system tray)
      // This is critical for deep linking to shipping detail screens
      try {
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          try {
            _handleBackgroundNotificationTap(message);
          } catch (e) {
            AppLogger.error('onMessageOpenedApp handling error', e);
          }
        });
      } catch (e) {
        AppLogger.error('Failed to attach onMessageOpenedApp listener', e);
      }
    } catch (e) {
      AppLogger.error('NotificationService.init error', e);
    }
  }

  /// Save FCM token to Firestore under user's fcmTokens array
  /// This allows Cloud Functions to send targeted notifications to specific users
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // For authenticated users, save to their user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmTokens': FieldValue.arrayUnion([token])
        }).catchError((error) {
          // If document doesn't exist yet, create it
          if (error.code == 'not-found') {
            return FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'fcmTokens': [token],
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          throw error;
        });
        AppLogger.debug('✅ FCM token saved to Firestore', user.uid);
      } else {
        // For guest users, just log the token
        AppLogger.debug('⚠️  Guest user - FCM token not saved', token);
      }
    } catch (e) {
      AppLogger.error('Failed to save FCM token to Firestore', e);
    }
  }

  /// Handle notification tap when app is opened from background
  /// Navigates to the appropriate screen based on notification data
  void _handleBackgroundNotificationTap(RemoteMessage message) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      AppLogger.debug('Background tap: no navigator available');
      return;
    }

    // Extract request ID from notification data
    final requestId = message.data['requestId'];
    final notificationType = message.data['type'];

    AppLogger.info(
        'Notification tapped - Type: $notificationType, RequestId: $requestId');

    // Navigate based on notification type
    if (requestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Navigate to shipping detail screen
          nav.pushNamed(
            '/shipping-detail',
            arguments: requestId,
          );
        } catch (e) {
          AppLogger.error('Failed to navigate on notification tap', e);
        }
      });
    } else {
      // Fallback: navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          nav.pushNamedAndRemoveUntil('/', (route) => false);
        } catch (e) {
          AppLogger.error('Failed to navigate to home', e);
        }
      });
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final nav = _navigatorKey?.currentState;
    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (nav == null) {
      AppLogger.debug(
          'Notification received but no navigatorKey set: $title - $body');
      return;
    }

    // Use the navigator's context to show a dialog. This keeps the UI simple
    // and works across different roles (vendor, affiliate, shipper, customer).
    final ctx = nav.context;
    // Avoid throwing if context is not mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        showDialog<void>(
          context: ctx,
          barrierDismissible: true,
          builder: (c) => AlertDialog(
            title: Text(title ?? 'Notification'),
            content: Text(body ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
      } catch (e) {
        AppLogger.error('Failed to show notification dialog', e);
      }
    });
  }

  Future<void> subscribeToAdminsTopic() async {
    try {
      await _messaging.subscribeToTopic('admins');
      AppLogger.info('Subscribed to admins topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to admins topic', e);
    }
  }

  Future<void> unsubscribeFromAdminsTopic() async {
    try {
      await _messaging.unsubscribeFromTopic('admins');
      AppLogger.info('Unsubscribed from admins topic');
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> subscribeToAffiliateTopic(String affiliateId) async {
    try {
      await _messaging.subscribeToTopic('affiliate-$affiliateId');
      AppLogger.info('Subscribed to affiliate-$affiliateId topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to affiliate-$affiliateId', e);
    }
  }

  Future<void> unsubscribeFromAffiliateTopic(String affiliateId) async {
    try {
      await _messaging.unsubscribeFromTopic('affiliate-$affiliateId');
      AppLogger.info('Unsubscribed from affiliate-$affiliateId topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe affiliate-$affiliateId', e);
    }
  }

  /// Subscribe to a per-user topic so server-side functions can target
  /// notifications to a specific user regardless of their role.
  Future<void> subscribeToUserTopic(String uid) async {
    try {
      await _messaging.subscribeToTopic('user-$uid');
      AppLogger.info('Subscribed to user-$uid topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to user-$uid', e);
    }
  }

  Future<void> unsubscribeFromUserTopic(String uid) async {
    try {
      await _messaging.unsubscribeFromTopic('user-$uid');
      AppLogger.info('Unsubscribed from user-$uid topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe user-$uid', e);
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe topic: $topic', e);
    }
  }
}
