import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore repository for push notification history tracking
/// Stores sent push notifications and their delivery statistics
class PushNotificationRepositoryFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('push_notifications');

  /// Get stream of notification history
  Stream<List<Map<String, dynamic>>> getNotificationHistoryStream() {
    return _notificationsCollection
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList(),
        );
  }

  /// Get notification history (one-time fetch)
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 100,
  }) async {
    final snapshot = await _notificationsCollection
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotificationById(String id) async {
    final doc = await _notificationsCollection.doc(id).get();
    if (!doc.exists) return null;
    return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
  }

  /// Create notification history record
  Future<String> createNotificationHistory({
    required String title,
    required String body,
    required String category,
    required String targetUserType,
    String status = 'sent',
    int? templateId,
    List<int>? userIds,
    DateTime? scheduledAt,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? customData,
    required String sentBy,
  }) async {
    final now = DateTime.now();
    final doc = await _notificationsCollection.add({
      'title': title,
      'body': body,
      'category': category,
      'targetUserType': targetUserType,
      'status': status,
      'templateId': templateId,
      'userIds': userIds,
      'scheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt)
          : null,
      'sentAt': Timestamp.fromDate(now),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'customData': customData,
      'sentBy': sentBy,
      'sentCount': 0,
      'deliveredCount': 0,
      'failedCount': 0,
      'openedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Update notification statistics
  Future<void> updateNotificationStats(
    String id, {
    int? sentCount,
    int? deliveredCount,
    int? failedCount,
    int? openedCount,
  }) async {
    final updates = <String, dynamic>{};
    if (sentCount != null) updates['sentCount'] = sentCount;
    if (deliveredCount != null) updates['deliveredCount'] = deliveredCount;
    if (failedCount != null) updates['failedCount'] = failedCount;
    if (openedCount != null) updates['openedCount'] = openedCount;

    if (updates.isNotEmpty) {
      await _notificationsCollection.doc(id).update(updates);
    }
  }

  /// Increment opened count
  Future<void> incrementOpenedCount(String id) async {
    await _notificationsCollection.doc(id).update({
      'openedCount': FieldValue.increment(1),
    });
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    final snapshot = await _notificationsCollection.get();

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
  }

  /// Get recent notifications (last 7 days)
  Future<List<Map<String, dynamic>>> getRecentNotifications() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _notificationsCollection
        .where(
          'sentAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('sentAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  /// Seed sample push notification data
  Future<void> seedSampleData() async {
    try {
      // Check if already seeded
      final existing = await _notificationsCollection.limit(1).get();
      if (existing.docs.isNotEmpty) {
        print('Push notifications already seeded');
        return;
      }

      final now = DateTime.now();
      final notifications = [
        {
          'title': 'Welcome to ShopsNPorts!',
          'body':
              'Thank you for joining our platform. Start exploring amazing deals today!',
          'category': 'promotional',
          'targetUserType': 'all',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
          'sentCount': 1500,
          'deliveredCount': 1487,
          'failedCount': 13,
          'openedCount': 892,
          'imageUrl': 'https://example.com/welcome.jpg',
        },
        {
          'title': 'New Products Available!',
          'body':
              'Check out our latest collection of premium products. Limited time offer!',
          'category': 'promotional',
          'targetUserType': 'customers',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
          'sentCount': 850,
          'deliveredCount': 843,
          'failedCount': 7,
          'openedCount': 456,
          'actionUrl': '/products/new',
        },
        {
          'title': 'Affiliate Program Update',
          'body':
              'New commission rates are now live! Check your dashboard for details.',
          'category': 'affiliate',
          'targetUserType': 'affiliates',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
          'sentCount': 45,
          'deliveredCount': 45,
          'failedCount': 0,
          'openedCount': 38,
          'actionUrl': '/affiliate/dashboard',
        },
        {
          'title': 'System Maintenance Notice',
          'body':
              'Scheduled maintenance on Sunday 2AM-4AM. Services may be unavailable.',
          'category': 'system',
          'targetUserType': 'all',
          'status': 'sent',
          'sentBy': 'system',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
          'sentCount': 1650,
          'deliveredCount': 1645,
          'failedCount': 5,
          'openedCount': 1120,
        },
        {
          'title': 'Your Order Has Shipped!',
          'body':
              'Great news! Your order #ORD-12345 is on its way. Track your shipment now.',
          'category': 'order',
          'targetUserType': 'customers',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'sentCount': 28,
          'deliveredCount': 28,
          'failedCount': 0,
          'openedCount': 24,
          'actionUrl': '/orders/ORD-12345',
        },
        {
          'title': 'Flash Sale Alert! ⚡',
          'body':
              '24-hour flash sale! Up to 50% off on selected items. Don\'t miss out!',
          'category': 'promotional',
          'targetUserType': 'all',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
          'sentCount': 1800,
          'deliveredCount': 1792,
          'failedCount': 8,
          'openedCount': 1345,
          'imageUrl': 'https://example.com/flash-sale.jpg',
          'actionUrl': '/sale',
        },
        {
          'title': 'Payout Processed',
          'body':
              'Your affiliate payout of ₦45,000 has been processed successfully.',
          'category': 'payout',
          'targetUserType': 'affiliates',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
          'sentCount': 3,
          'deliveredCount': 3,
          'failedCount': 0,
          'openedCount': 3,
        },
        {
          'title': 'New FAQ Section Added',
          'body':
              'We\'ve added a new FAQ section to help you get answers faster. Check it out!',
          'category': 'update',
          'targetUserType': 'all',
          'status': 'sent',
          'sentBy': 'admin_001',
          'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
          'sentCount': 1600,
          'deliveredCount': 1595,
          'failedCount': 5,
          'openedCount': 234,
          'actionUrl': '/faq',
        },
      ];

      for (int i = 0; i < notifications.length; i++) {
        await _notificationsCollection
            .doc('PUSH-${i + 1}')
            .set(notifications[i]);
      }

      print('✅ Seeded ${notifications.length} push notifications');
    } catch (e) {
      print('Error seeding push notifications: $e');
      rethrow;
    }
  }
}
