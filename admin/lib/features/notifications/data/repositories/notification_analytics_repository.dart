import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_analytics.dart';
import '../models/notification_history.dart';

class NotificationAnalyticsRepository {
  final FirebaseFirestore _firestore;

  NotificationAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'notification_analytics';
  static const String _historyCollection = 'notification_history';

  /// Get analytics for a date range
  Future<List<NotificationAnalytics>> getAnalyticsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationAnalytics.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  /// Get analytics as stream (real-time)
  Stream<List<NotificationAnalytics>> getAnalyticsStream({
    int days = 30,
  }) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _firestore
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => NotificationAnalytics.fromMap(doc.data())).toList(),
        );
  }

  /// Get overall metrics
  Future<NotificationMetrics> getOverallMetrics({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final analytics = await getAnalyticsForDateRange(startDate, DateTime.now());
      return NotificationMetrics.fromAnalytics(analytics);
    } catch (e) {
      throw Exception('Failed to fetch overall metrics: $e');
    }
  }

  /// Get metrics by type
  Future<Map<String, dynamic>> getMetricsByType({int days = 30}) async {
    try {
      final metrics = await getOverallMetrics(days: days);
      return {
        'byType': metrics.byType,
        'total': metrics.totalSent,
      };
    } catch (e) {
      throw Exception('Failed to fetch metrics by type: $e');
    }
  }

  /// Get metrics by category
  Future<Map<String, dynamic>> getMetricsByCategory({int days = 30}) async {
    try {
      final metrics = await getOverallMetrics(days: days);
      return {
        'byCategory': metrics.byCategory,
        'total': metrics.totalSent,
      };
    } catch (e) {
      throw Exception('Failed to fetch metrics by category: $e');
    }
  }

  /// Calculate analytics from notification history
  Future<void> calculateDailyAnalytics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_historyCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final byType = <String, int>{};
      final byCategory = <String, int>{};

      int totalSent = 0;
      int delivered = 0;
      int opened = 0;
      int clicked = 0;
      int failed = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'system';
        final category = data['category'] as String? ?? 'system';
        final status = data['deliveryStatus'] as String? ?? 'pending';

        totalSent++;
        byType[type] = (byType[type] ?? 0) + 1;
        byCategory[category] = (byCategory[category] ?? 0) + 1;

        switch (status) {
          case 'delivered':
            delivered++;
            break;
          case 'opened':
            delivered++;
            opened++;
            break;
          case 'clicked':
            delivered++;
            opened++;
            clicked++;
            break;
          case 'failed':
            failed++;
            break;
          default:
            // pending or sent
            break;
        }
      }

      final analyticsId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final analytics = NotificationAnalytics(
        id: analyticsId,
        date: date,
        totalSent: totalSent,
        delivered: delivered,
        opened: opened,
        clicked: clicked,
        failed: failed,
        byType: byType,
        byCategory: byCategory,
      );

      await _firestore.collection(_collection).doc(analyticsId).set(analytics.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to calculate daily analytics: $e');
    }
  }

  /// Get real-time statistics stream
  Stream<Map<String, dynamic>> getRealTimeStats() {
    return _firestore.collection(_historyCollection).snapshots().map((snapshot) {
      int totalSent = 0;
      int delivered = 0;
      int opened = 0;
      int clicked = 0;
      int failed = 0;

      final byType = <String, int>{};
      final byCategory = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'system';
        final category = data['category'] as String? ?? 'system';
        final status = data['deliveryStatus'] as String? ?? 'pending';

        totalSent++;
        byType[type] = (byType[type] ?? 0) + 1;
        byCategory[category] = (byCategory[category] ?? 0) + 1;

        switch (status) {
          case 'delivered':
            delivered++;
            break;
          case 'opened':
            delivered++;
            opened++;
            break;
          case 'clicked':
            delivered++;
            opened++;
            clicked++;
            break;
          case 'failed':
            failed++;
            break;
          default:
            break;
        }
      }

      return {
        'totalSent': totalSent,
        'delivered': delivered,
        'opened': opened,
        'clicked': clicked,
        'failed': failed,
        'deliveryRate': totalSent > 0 ? (delivered / totalSent) * 100 : 0,
        'openRate': delivered > 0 ? (opened / delivered) * 100 : 0,
        'clickRate': opened > 0 ? (clicked / opened) * 100 : 0,
        'failureRate': totalSent > 0 ? (failed / totalSent) * 100 : 0,
        'byType': byType,
        'byCategory': byCategory,
      };
    });
  }

  /// Seed sample analytics data
  Future<void> seedSampleData() async {
    try {
      final existing = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Analytics data already seeded');
        return;
      }

      final now = DateTime.now();
      final sampleData = <NotificationAnalytics>[];

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final random = date.millisecondsSinceEpoch % 100;

        sampleData.add(NotificationAnalytics(
          id: 'analytics_${date.millisecondsSinceEpoch}',
          date: date,
          totalSent: 50 + (random % 100),
          delivered: 40 + (random % 80),
          opened: 30 + (random % 60),
          clicked: 20 + (random % 40),
          failed: (random % 10),
          byType: {
            'system': 10 + (random % 20),
            'order': 15 + (random % 25),
            'shipping': 10 + (random % 20),
            'payment': 5 + (random % 15),
            'promotion': 10 + (random % 20),
          },
          byCategory: {
            'system': 10 + (random % 20),
            'order': 15 + (random % 25),
            'shipping': 10 + (random % 20),
            'billing': 5 + (random % 15),
            'sales': 10 + (random % 20),
          },
        ));
      }

      for (final analytics in sampleData) {
        await _firestore.collection(_collection).doc(analytics.id).set(analytics.toMap());
      }

      print('✅ Seeded ${sampleData.length} analytics records');
    } catch (e) {
      print('Error seeding analytics data: $e');
      rethrow;
    }
  }
}