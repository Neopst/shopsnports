import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scheduled_notification.dart';
import '../models/notification_type.dart';
import '../models/notification_category.dart';
import '../models/notification_priority.dart';

class ScheduledNotificationRepository {
  final FirebaseFirestore _firestore;

  ScheduledNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'scheduled_notifications';

  // ==================== CRUD OPERATIONS ====================

  /// Get all scheduled notifications
  Future<List<ScheduledNotification>> getAll({
    ScheduleStatus? status,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .orderBy('scheduledFor', descending: false)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch scheduled notifications: $e');
    }
  }

  /// Get scheduled notifications as stream (real-time)
  Stream<List<ScheduledNotification>> getAllStream({
    ScheduleStatus? status,
    int limit = 100,
  }) {
    var query = _firestore
        .collection(_collection)
        .orderBy('scheduledFor')
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc)).toList(),
    );
  }

  /// Get scheduled notification by ID
  Future<ScheduledNotification?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch scheduled notification: $e');
    }
  }

  /// Get pending notifications that are due
  Future<List<ScheduledNotification>> getPendingDue() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ScheduleStatus.pending.name)
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledFor', descending: false)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending due notifications: $e');
    }
  }

  /// Create scheduled notification
  Future<String> create(ScheduledNotification notification) async {
    try {
      final docRef = _firestore.collection(_collection).doc(notification.id);
      await docRef.set(notification.toMap());
      return notification.id;
    } catch (e) {
      throw Exception('Failed to create scheduled notification: $e');
    }
  }

  /// Update scheduled notification
  Future<void> update(ScheduledNotification notification) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notification.id)
          .update(notification.toMap()..['updatedAt'] = FieldValue.serverTimestamp());
    } catch (e) {
      throw Exception('Failed to update scheduled notification: $e');
    }
  }

  /// Delete scheduled notification
  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete scheduled notification: $e');
    }
  }

  /// Cancel scheduled notification
  Future<void> cancel(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': ScheduleStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel scheduled notification: $e');
    }
  }

  /// Mark as sent
  Future<void> markAsSent(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': ScheduleStatus.sent.name,
        'sentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as sent: $e');
    }
  }

  /// Mark as failed
  Future<void> markAsFailed(String id, String error) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': ScheduleStatus.failed.name,
        'errorMessage': error,
        'retryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as failed: $e');
    }
  }

  /// Retry failed notification
  Future<void> retry(String id) async {
    try {
      final notification = await getById(id);
      if (notification == null) {
        throw Exception('Notification not found');
      }

      if (!notification.canRetry) {
        throw Exception('Max retries exceeded');
      }

      // Reset to pending
      await _firestore.collection(_collection).doc(id).update({
        'status': ScheduleStatus.pending.name,
        'errorMessage': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to retry notification: $e');
    }
  }

  /// Get upcoming notifications (next 24 hours)
  Future<List<ScheduledNotification>> getUpcoming() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ScheduleStatus.pending.name)
          .where('scheduledFor', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.fromDate(tomorrow))
          .orderBy('scheduledFor', descending: false)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming notifications: $e');
    }
  }

  /// Get recurring notifications
  Future<List<ScheduledNotification>> getRecurring() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('frequency', isNotEqualTo: 'once')
          .where('status', isEqualTo: ScheduleStatus.pending.name)
          .orderBy('scheduledFor', descending: false)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recurring notifications: $e');
    }
  }

  /// Search scheduled notifications
  Future<List<ScheduledNotification>> search(
    String query, {
    int limit = 100,
  }) async {
    try {
      final allSnapshot = await _firestore
          .collection(_collection)
          .orderBy('scheduledFor', descending: false)
          .limit(limit * 2)
          .get();

      final lowerQuery = query.toLowerCase();
      return allSnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .where((n) =>
              n.name.toLowerCase().contains(lowerQuery) ||
              n.title.toLowerCase().contains(lowerQuery))
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to search scheduled notifications: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  ScheduledNotification _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledNotification.fromMap(data);
  }

  // ==================== SEEDING ====================

  /// Seed sample scheduled notification data
  Future<void> seedSampleData() async {
    try {
      final existing = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Scheduled notifications already seeded');
        return;
      }

      final now = DateTime.now();
      final sampleNotifications = [
        ScheduledNotification(
          id: 'sched_001',
          name: 'Daily Sales Report',
          description: 'Send daily sales summary to admins',
          type: NotificationType.system,
          category: NotificationCategory.system,
          title: 'Daily Sales Report',
          message: 'Here is your daily sales summary for {{date}}',
          priority: NotificationPriority.normal,
          status: ScheduleStatus.pending,
          frequency: ScheduleFrequency.daily,
          scheduledFor: now.add(const Duration(hours: 2)),
          recurringInterval: 1,
          createdAt: now,
        ),
        ScheduledNotification(
          id: 'sched_002',
          name: 'Weekly Newsletter',
          description: 'Send weekly newsletter to all users',
          type: NotificationType.promotion,
          category: NotificationCategory.sales,
          title: 'Weekly Newsletter',
          message: 'Check out our latest deals and offers!',
          actionUrl: '/promotions',
          priority: NotificationPriority.normal,
          status: ScheduleStatus.pending,
          frequency: ScheduleFrequency.weekly,
          scheduledFor: now.add(const Duration(days: 1)),
          recurringInterval: 7,
          createdAt: now,
        ),
        ScheduledNotification(
          id: 'sched_003',
          name: 'Monthly Invoice Reminder',
          description: 'Send monthly invoice reminders to customers',
          type: NotificationType.invoice,
          category: NotificationCategory.billing,
          title: 'Invoice Reminder',
          message: 'Your invoice {{invoiceNumber}} is due soon.',
          priority: NotificationPriority.high,
          status: ScheduleStatus.pending,
          frequency: ScheduleFrequency.monthly,
          scheduledFor: now.add(const Duration(days: 7)),
          recurringInterval: 30,
          createdAt: now,
        ),
      ];

      for (final notification in sampleNotifications) {
        await _firestore.collection(_collection).doc(notification.id).set(notification.toMap());
      }

      print('✅ Seeded ${sampleNotifications.length} scheduled notifications');
    } catch (e) {
      print('Error seeding scheduled notifications: $e');
      rethrow;
    }
  }
}