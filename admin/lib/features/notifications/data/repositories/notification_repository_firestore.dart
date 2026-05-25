import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart' as model;
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import '../models/notification_category.dart';
import '../models/notification_priority.dart';

class NotificationRepositoryFirestore {
  final FirebaseFirestore _firestore;

  NotificationRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _notificationsCollection = 'notifications';
  static const String _preferencesCollection = 'notification_preferences';

  // ==================== NOTIFICATION METHODS ====================

  /// Get notifications as stream (real-time)
  Stream<List<model.Notification>> getNotificationsStream({
    required String userId,
    String? category,
    int limit = 100,
  }) {
    var query = _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => _notificationFromFirestore(doc)).toList(),
    );
  }

  /// Get notifications (one-time fetch)
  Future<List<model.Notification>> getNotifications({
    required String userId,
    String? category,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _notificationFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Get unread notifications count
  Stream<int> getUnreadCountStream({required String userId}) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get notification by ID
  Future<model.Notification?> getNotificationById(String notificationId) async {
    try {
      final doc = await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .get();
      if (!doc.exists) return null;
      return _notificationFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch notification: $e');
    }
  }

  /// Create notification
  Future<String> createNotification(model.Notification notification) async {
    try {
      final docRef = _firestore
          .collection(_notificationsCollection)
          .doc(notification.id);
      await docRef.set(notification.toMap());
      return notification.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
            'isRead': false,
            'readAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as unread: $e');
    }
  }

  /// Save notification preferences
  Future<void> savePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .set(preferences.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save notification preferences: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // ==================== NOTIFICATION SENDING ====================

  /// Send notification to single user
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required NotificationCategory category,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notification = model.Notification(
      id: _firestore.collection(_notificationsCollection).doc().id,
      userId: userId,
      type: type,
      category: category,
      title: title,
      message: message,
      actionUrl: actionUrl,
      metadata: metadata,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send notification to multiple users
  Future<void> sendBulkNotification({
    required List<String> userIds,
    required NotificationType type,
    required NotificationCategory category,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final docRef = _firestore.collection(_notificationsCollection).doc();
        final notification = model.Notification(
          id: docRef.id,
          userId: userId,
          type: type,
          category: category,
          title: title,
          message: message,
          actionUrl: actionUrl,
          metadata: metadata,
          priority: priority,
          createdAt: DateTime.now(),
        );
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send bulk notification: $e');
    }
  }

  // ==================== PREFERENCES METHODS ====================

  /// Get notification preferences
  Future<NotificationPreferences?> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return NotificationPreferences.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch preferences: $e');
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .set(preferences.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // ==================== RETRY METHODS ====================

  /// Mark notification as failed
  Future<void> markAsFailed(String notificationId, String error) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
            'status': 'failed',
            'errorMessage': error,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as failed: $e');
    }
  }

  /// Retry a failed notification
  Future<void> retryNotification(String notificationId) async {
    try {
      final doc = await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        throw Exception('Notification not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final retryCount = (data['retryCount'] ?? 0) as int;

      if (retryCount >= 3) {
        throw Exception('Max retries exceeded');
      }

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
            'status': 'pending',
            'retryCount': FieldValue.increment(1),
            'lastRetryAt': FieldValue.serverTimestamp(),
            'errorMessage': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to retry notification: $e');
    }
  }

  /// Get failed notifications that can be retried
  Future<List<model.Notification>> getRetryableNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['failed', 'permanently_failed'])
          .where('retryCount', isLessThan: 3)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _notificationFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch retryable notifications: $e');
    }
  }

  /// Get notification retry statistics
  Future<Map<String, dynamic>> getRetryStats(String notificationId) async {
    try {
      final doc = await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        return {};
      }

      final data = doc.data() as Map<String, dynamic>;
      final retryCount = (data['retryCount'] ?? 0) as int;
      final lastRetryAt = data['lastRetryAt'] as Timestamp?;

      return {
        'retryCount': retryCount,
        'maxRetries': 3,
        'canRetry': retryCount < 3,
        'lastRetryAt': lastRetryAt?.toDate(),
      };
    } catch (e) {
      throw Exception('Failed to get retry stats: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Convert Firestore document to Notification model
  model.Notification _notificationFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return model.Notification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => NotificationCategory.system,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      actionUrl: data['actionUrl'],
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: model.NotificationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => model.NotificationStatus.pending,
      ),
      retryCount: data['retryCount'] ?? 0,
      lastRetryAt: data['lastRetryAt'] != null
          ? (data['lastRetryAt'] as Timestamp).toDate()
          : null,
      errorMessage: data['errorMessage'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ==================== SEEDING ====================

  /// Seed sample notification data for testing
  Future<void> seedSampleData() async {
    try {
      // Check if already seeded
      final existing = await _firestore
          .collection(_notificationsCollection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Notifications already seeded');
        return;
      }

      final now = DateTime.now();
      final notifications = [
        {
          'userId': 'admin_001',
          'type': 'system',
          'category': 'system',
          'title': 'Welcome to ShopsNPorts Admin',
          'message':
              'Your admin dashboard is now active. You have full access to all features.',
          'actionUrl': '/dashboard/overview',
          'isRead': true,
          'readAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
          'priority': 'high',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 7)),
          ),
          'updatedAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 2)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'customer',
          'category': 'customer',
          'title': 'New Customer Registration',
          'message': 'James Wilson has registered as a new customer.',
          'actionUrl': '/dashboard/customers/CUS-2024-001',
          'isRead': true,
          'readAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
          'priority': 'normal',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
          'updatedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 3)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'affiliate',
          'category': 'affiliate',
          'title': 'New Affiliate Pending Approval',
          'message':
              'Sarah Williams has applied to become an affiliate. Review required.',
          'actionUrl': '/dashboard/affiliates',
          'isRead': false,
          'priority': 'high',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 2)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'payout',
          'category': 'payout',
          'title': 'Payout Request Submitted',
          'message': 'John Doe has requested a payout of ₦45,000.',
          'actionUrl': '/dashboard/payouts/PAYOUT-2024-001',
          'isRead': false,
          'priority': 'high',
          'metadata': {'payoutId': 'PAYOUT-2024-001', 'amount': 45000},
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 1)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'invoice',
          'category': 'billing',
          'title': 'Invoice Overdue',
          'message': 'Invoice INV-2024-003 is now overdue. Amount: ₦23,800',
          'actionUrl': '/dashboard/invoices/INV-2024-003',
          'isRead': false,
          'priority': 'urgent',
          'metadata': {'invoiceId': 'INV-2024-003', 'amount': 23800},
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 12)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'shipping',
          'category': 'shipping',
          'title': 'Shipment Delivered',
          'message': 'Shipment SHIP-2024-001 has been delivered successfully.',
          'actionUrl': '/dashboard/shipping-request/SHIP-2024-001',
          'isRead': false,
          'priority': 'normal',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 5)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'system',
          'category': 'system',
          'title': 'New Admin Created',
          'message': 'Administrator "Jane Smith" has been added to the system.',
          'actionUrl': '/dashboard/super-admin',
          'isRead': false,
          'priority': 'normal',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 3)),
          ),
        },
        {
          'userId': 'admin_001',
          'type': 'content',
          'category': 'content',
          'title': 'FAQ Updated',
          'message': 'The "Payment Methods" FAQ has been updated.',
          'actionUrl': '/dashboard/content',
          'isRead': false,
          'priority': 'low',
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 1)),
          ),
        },
      ];

      for (int i = 0; i < notifications.length; i++) {
        await _firestore
            .collection(_notificationsCollection)
            .doc('NOTIF-${i + 1}')
            .set(notifications[i]);
      }

      print('✅ Seeded ${notifications.length} notifications');
    } catch (e) {
      print('Error seeding notifications: $e');
      rethrow;
    }
  }
}
