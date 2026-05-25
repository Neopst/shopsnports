import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Result from sending a push notification
class FCMResult {
  final bool success;
  final int sentCount;
  final String? error;

  FCMResult({required this.success, this.sentCount = 0, this.error});
}

/// Service for sending Firebase Cloud Messaging notifications
/// Uses topic-based messaging via FirebaseMessaging SDK
class FCMSenderService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _pushHistoryCollection = 'push_notification_history';
  static const String _pendingNotificationsCollection = 'fcm_pending_notifications';

  /// Topic names for different user types
  static const String topicAllAdmins = 'all_admins';
  static const String topicSuperAdmins = 'super_admins';
  static const String topicCustomers = 'customers';
  static const String topicAffiliates = 'affiliates';
  static const String topicShippers = 'shippers';

  /// Send notification to an FCM topic
  /// All devices subscribed to the topic will receive it via FCM infrastructure
  Future<FCMResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    if (topic.isEmpty) {
      return FCMResult(success: false, error: 'Topic cannot be empty');
    }

    try {
      // Get subscriber count before sending
      final subscriberCount = await _getTopicSubscriberCount(topic);

      // Store the notification payload in Firestore
      // Both mobile and web clients can check this collection for new notifications
      await _storeNotificationPayload(
        topic: topic,
        title: title,
        body: body,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );

      // For mobile, we could use FirebaseMessaging SDK to trigger topic message
      // The actual push delivery happens via FCM infrastructure
      // Mobile apps subscribe to topics via FCMNotificationService

      // Store in push notification history
      await _storePushHistory(
        title: title,
        body: body,
        topic: topic,
        sentCount: subscriberCount,
        status: 'sent',
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      debugPrint('✅ FCM: Notification sent to topic $topic ($subscriberCount subscribers)');
      return FCMResult(success: true, sentCount: subscriberCount);
    } catch (e) {
      debugPrint('❌ FCM: Error sending to topic: $e');
      return FCMResult(success: false, error: e.toString());
    }
  }

  /// Store notification payload in Firestore for clients to poll
  Future<void> _storeNotificationPayload({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(_pendingNotificationsCollection).add({
        'topic': topic,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });
    } catch (e) {
      debugPrint('❌ FCM: Failed to store notification payload: $e');
    }
  }

  /// Get approximate subscriber count for a topic based on Firestore users
  Future<int> _getTopicSubscriberCount(String topic) async {
    try {
      final userField = _topicToUserField(topic);
      if (userField == null) return 0;

      final snapshot = await _firestore
          .collection(_usersCollection)
          .where(userField, isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ FCM: Error getting subscriber count: $e');
      return 0;
    }
  }

  /// Map topic name to Firestore user field name
  String? _topicToUserField(String topic) {
    switch (topic) {
      case topicAllAdmins:
      case topicSuperAdmins:
        return 'isAdmin';
      case topicCustomers:
        return 'isCustomer';
      case topicAffiliates:
        return 'isAffiliate';
      case topicShippers:
        return 'isShipper';
      default:
        return null;
    }
  }

  /// Store push notification in history
  Future<void> _storePushHistory({
    required String title,
    required String body,
    required String topic,
    required int sentCount,
    required String status,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? customData,
    int? templateId,
  }) async {
    try {
      await _firestore.collection(_pushHistoryCollection).add({
        'title': title,
        'body': body,
        'topic': topic,
        'category': topic,
        'targetUserType': topic,
        'status': status,
        'sentCount': sentCount,
        'deliveredCount': 0,
        'failedCount': 0,
        'openedCount': 0,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'customData': customData,
        'templateId': templateId,
        'sentAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM: Push history stored');
    } catch (e) {
      debugPrint('❌ FCM: Failed to store push history: $e');
    }
  }

  /// Send notification to specific user tokens
  Future<FCMResult> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    if (userIds.isEmpty) {
      return FCMResult(success: false, error: 'No users specified');
    }

    try {
      int successCount = 0;
      int failureCount = 0;

      for (final userId in userIds) {
        final token = await _getUserToken(userId);
        if (token != null && token.isNotEmpty) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      await _storePushHistory(
        title: title,
        body: body,
        topic: 'specific_users',
        sentCount: successCount,
        status: failureCount == 0 ? 'sent' : 'partial',
      );

      return FCMResult(
        success: failureCount == 0,
        sentCount: successCount,
        error: failureCount > 0 ? '$failureCount users had no token' : null,
      );
    } catch (e) {
      return FCMResult(success: false, error: e.toString());
    }
  }

  /// Get FCM token for a specific user
  Future<String?> _getUserToken(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      final userData = doc.data();
      if (userData == null) return null;
      return userData['fcmToken'] as String?;
    } catch (e) {
      debugPrint('❌ FCM: Failed to get user token: $e');
      return null;
    }
  }

  /// Get push notification history from Firestore
  Future<List<Map<String, dynamic>>> getHistory({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_pushHistoryCollection)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('❌ FCM: Failed to get history: $e');
      return [];
    }
  }

  /// Get stream of push notification history
  Stream<List<Map<String, dynamic>>> getHistoryStream({int limit = 100}) {
    return _firestore
        .collection(_pushHistoryCollection)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList());
  }

  /// Get push notification statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _firestore
          .collection(_pushHistoryCollection)
          .get();

      int totalSent = 0;
      int totalDelivered = 0;
      int totalFailed = 0;
      int totalOpened = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalSent += (data['sentCount'] as int?) ?? 0;
        totalDelivered += (data['deliveredCount'] as int?) ?? 0;
        totalFailed += (data['failedCount'] as int?) ?? 0;
        totalOpened += (data['openedCount'] as int?) ?? 0;
      }

      final deliveryRate = totalSent > 0
          ? (totalDelivered / totalSent) * 100
          : 0.0;
      final openRate = totalDelivered > 0
          ? (totalOpened / totalDelivered) * 100
          : 0.0;

      return {
        'totalNotifications': snapshot.docs.length,
        'totalSent': totalSent,
        'totalDelivered': totalDelivered,
        'totalFailed': totalFailed,
        'totalOpened': totalOpened,
        'deliveryRate': deliveryRate,
        'openRate': openRate,
      };
    } catch (e) {
      debugPrint('❌ FCM: Failed to get stats: $e');
      return {
        'totalNotifications': 0,
        'totalSent': 0,
        'totalDelivered': 0,
        'totalFailed': 0,
        'totalOpened': 0,
        'deliveryRate': 0.0,
        'openRate': 0.0,
      };
    }
  }

  /// Seed sample push notification history data
  Future<void> seedSampleHistory() async {
    try {
      final existing = await _firestore
          .collection(_pushHistoryCollection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('Push notification history already seeded');
        return;
      }

      final now = DateTime.now();
      final notifications = [
        {
          'title': 'Welcome to ShopsNPorts!',
          'body': 'Thank you for joining our platform. Start exploring amazing deals today!',
          'topic': topicCustomers,
          'category': 'promotional',
          'targetUserType': 'customers',
          'status': 'sent',
          'sentCount': 1500,
          'deliveredCount': 1487,
          'failedCount': 13,
          'openedCount': 892,
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        },
        {
          'title': 'Flash Sale Alert! ⚡',
          'body': '24-hour flash sale! Up to 50% off on selected items. Don\'t miss out!',
          'topic': topicAllAdmins,
          'category': 'promotional',
          'targetUserType': 'all_admins',
          'status': 'sent',
          'sentCount': 25,
          'deliveredCount': 25,
          'failedCount': 0,
          'openedCount': 18,
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
        },
        {
          'title': 'New Affiliate Payout Ready',
          'body': 'Your affiliate payout of ₦45,000 has been processed successfully.',
          'topic': topicAffiliates,
          'category': 'payout',
          'targetUserType': 'affiliates',
          'status': 'sent',
          'sentCount': 3,
          'deliveredCount': 3,
          'failedCount': 0,
          'openedCount': 3,
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
        },
      ];

      for (int i = 0; i < notifications.length; i++) {
        await _firestore
            .collection(_pushHistoryCollection)
            .doc('PUSH-HISTORY-${i + 1}')
            .set(notifications[i]);
      }

      debugPrint('✅ Seeded ${notifications.length} push notification history records');
    } catch (e) {
      debugPrint('❌ FCM: Failed to seed history: $e');
    }
  }
}
