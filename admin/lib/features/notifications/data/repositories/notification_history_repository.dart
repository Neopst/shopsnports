import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_history.dart';
import '../models/notification_type.dart';
import '../models/notification_category.dart';
import '../models/notification_priority.dart';

class NotificationHistoryRepository {
  final FirebaseFirestore _firestore;

  NotificationHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'notification_history';

  // ==================== CRUD OPERATIONS ====================

  /// Get all notification history records
  Future<List<NotificationHistory>> getAll({
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notification history: $e');
    }
  }

  /// Get notification history as stream (real-time)
  Stream<List<NotificationHistory>> getAllStream({
    int limit = 100,
  }) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _fromFirestore(doc)).toList());
  }

  /// Get notification history for a specific user
  Future<List<NotificationHistory>> getByUserId(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notification history for user: $e');
    }
  }

  /// Get notification history by ID
  Future<NotificationHistory?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch notification history: $e');
    }
  }

  /// Create notification history record
  Future<String> create(NotificationHistory history) async {
    try {
      final docRef = _firestore.collection(_collection).doc(history.id);
      await docRef.set(history.toMap());
      return history.id;
    } catch (e) {
      throw Exception('Failed to create notification history: $e');
    }
  }

  /// Update notification history record
  Future<void> update(NotificationHistory history) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(history.id)
          .update(history.toMap()..['updatedAt'] = FieldValue.serverTimestamp());
    } catch (e) {
      throw Exception('Failed to update notification history: $e');
    }
  }

  /// Delete notification history record
  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete notification history: $e');
    }
  }

  // ==================== FILTERING ====================

  /// Get by delivery status
  Future<List<NotificationHistory>> getByDeliveryStatus(
    DeliveryStatus status, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('deliveryStatus', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch by delivery status: $e');
    }
  }

  /// Get by type
  Future<List<NotificationHistory>> getByType(
    NotificationType type, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch by type: $e');
    }
  }

  /// Get by category
  Future<List<NotificationHistory>> getByCategory(
    NotificationCategory category, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch by category: $e');
    }
  }

  /// Get by date range
  Future<List<NotificationHistory>> getByDateRange(
    DateTime start,
    DateTime end, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch by date range: $e');
    }
  }

  /// Search notifications by title or message
  Future<List<NotificationHistory>> search(
    String query, {
    int limit = 100,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple implementation that searches in memory
      final allSnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final lowerQuery = query.toLowerCase();
      return allSnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .where((h) =>
              h.title.toLowerCase().contains(lowerQuery) ||
              h.message.toLowerCase().contains(lowerQuery))
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to search notification history: $e');
    }
  }

  // ==================== TRACKING ====================

  /// Mark as sent
  Future<void> markAsSent(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'deliveryStatus': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as sent: $e');
    }
  }

  /// Mark as delivered
  Future<void> markAsDelivered(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'deliveryStatus': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as delivered: $e');
    }
  }

  /// Mark as opened
  Future<void> markAsOpened(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'deliveryStatus': 'opened',
        'openedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as opened: $e');
    }
  }

  /// Mark as clicked
  Future<void> markAsClicked(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'deliveryStatus': 'clicked',
        'clickedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as clicked: $e');
    }
  }

  /// Mark as failed with error
  Future<void> markAsFailed(String id, String error) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'deliveryStatus': 'failed',
        'deliveryError': error,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark as failed: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'sent': 0,
        'delivered': 0,
        'failed': 0,
        'opened': 0,
        'clicked': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['deliveryStatus'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Get statistics stream
  Stream<Map<String, int>> getStatisticsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'sent': 0,
        'delivered': 0,
        'failed': 0,
        'opened': 0,
        'clicked': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['deliveryStatus'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    });
  }

  // ==================== HELPER METHODS ====================

  NotificationHistory _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationHistory.fromMap(data);
  }

  // ==================== SEEDING ====================

  /// Seed sample notification history data for testing
  Future<void> seedSampleData() async {
    try {
      // Check if already seeded
      final existing = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Notification history already seeded');
        return;
      }

      final now = DateTime.now();
      final historyItems = [
        NotificationHistory(
          id: 'HIST-001',
          userId: 'user_001',
          type: NotificationType.system,
          category: NotificationCategory.system,
          title: 'Welcome to ShopsNPorts',
          message: 'Your account has been created successfully.',
          deliveryStatus: DeliveryStatus.delivered,
          sentAt: now.subtract(const Duration(days: 7)),
          deliveredAt: now.subtract(const Duration(days: 7)),
          priority: NotificationPriority.normal,
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        NotificationHistory(
          id: 'HIST-002',
          userId: 'user_002',
          type: NotificationType.order,
          category: NotificationCategory.order,
          title: 'Order Confirmed',
          message: 'Your order #ORD-001 has been confirmed.',
          actionUrl: '/orders/ORD-001',
          deliveryStatus: DeliveryStatus.opened,
          sentAt: now.subtract(const Duration(days: 5)),
          deliveredAt: now.subtract(const Duration(days: 5)),
          openedAt: now.subtract(const Duration(days: 4)),
          priority: NotificationPriority.high,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        NotificationHistory(
          id: 'HIST-003',
          userId: 'user_003',
          type: NotificationType.shipping,
          category: NotificationCategory.shipping,
          title: 'Shipment Delivered',
          message: 'Your shipment #SHIP-001 has been delivered.',
          actionUrl: '/shipping/SHIP-001',
          deliveryStatus: DeliveryStatus.clicked,
          sentAt: now.subtract(const Duration(days: 3)),
          deliveredAt: now.subtract(const Duration(days: 3)),
          openedAt: now.subtract(const Duration(days: 2)),
          clickedAt: now.subtract(const Duration(days: 2)),
          priority: NotificationPriority.normal,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        NotificationHistory(
          id: 'HIST-004',
          userId: 'user_004',
          type: NotificationType.payment,
          category: NotificationCategory.billing,
          title: 'Payment Received',
          message: 'Your payment of ₦5,000 has been received.',
          deliveryStatus: DeliveryStatus.failed,
          sentAt: now.subtract(const Duration(days: 2)),
          deliveryError: 'Invalid email address',
          priority: NotificationPriority.high,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        NotificationHistory(
          id: 'HIST-005',
          userId: 'user_005',
          type: NotificationType.promotion,
          category: NotificationCategory.sales,
          title: 'Special Offer!',
          message: 'Get 20% off on your next order.',
          actionUrl: '/promotions/special',
          deliveryStatus: DeliveryStatus.sent,
          sentAt: now.subtract(const Duration(hours: 12)),
          priority: NotificationPriority.normal,
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
      ];

      for (final item in historyItems) {
        await _firestore.collection(_collection).doc(item.id).set(item.toMap());
      }

      print('✅ Seeded ${historyItems.length} notification history items');
    } catch (e) {
      print('Error seeding notification history: $e');
      rethrow;
    }
  }
}