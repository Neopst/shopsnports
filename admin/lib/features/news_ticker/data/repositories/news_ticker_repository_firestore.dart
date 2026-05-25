import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_ticker.dart';

class NewsTickerRepositoryFirestore {
  final FirebaseFirestore _firestore;

  NewsTickerRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _newsTickerCollection = 'news_ticker';

  // Get all news items
  Future<List<NewsTicker>> getAllNewsItems({
    bool? filterByActive,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(_newsTickerCollection);

      if (filterByActive != null) {
        query = query.where('isActive', isEqualTo: filterByActive);
      }

      query = query.orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => NewsTicker.fromJson({...doc.data() as Map, 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch news items: $e');
    }
  }

  // Get active news items only
  Future<List<NewsTicker>> getActiveNewsItems({int? limit}) async {
    try {
      Query query = _firestore
          .collection(_newsTickerCollection)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => NewsTicker.fromJson({...doc.data() as Map, 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active news items: $e');
    }
  }

  // Get single news item by ID
  Future<NewsTicker?> getNewsItemById(String id) async {
    try {
      final doc = await _firestore
          .collection(_newsTickerCollection)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return NewsTicker.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch news item: $e');
    }
  }

  // Create new news item
  Future<NewsTicker> createNewsItem(NewsTicker newsItem) async {
    try {
      // Check for duplicate text to prevent duplication
      final existingQuery = await _firestore
          .collection(_newsTickerCollection)
          .where('text', isEqualTo: newsItem.text)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('A news item with this text already exists');
      }

      final docRef = _firestore.collection(_newsTickerCollection).doc();
      final newItem = newsItem.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newItem.toJson());
      return newItem;
    } catch (e) {
      throw Exception('Failed to create news item: $e');
    }
  }

  // Update existing news item
  Future<NewsTicker> updateNewsItem(NewsTicker newsItem) async {
    try {
      final updatedItem = newsItem.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_newsTickerCollection)
          .doc(newsItem.id)
          .update(updatedItem.toJson());
      return updatedItem;
    } catch (e) {
      throw Exception('Failed to update news item: $e');
    }
  }

  // Delete news item
  Future<void> deleteNewsItem(String id) async {
    try {
      await _firestore.collection(_newsTickerCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete news item: $e');
    }
  }

  // Archive news item (deactivate)
  Future<NewsTicker> archiveNewsItem(String id) async {
    try {
      final item = await getNewsItemById(id);
      if (item == null) throw Exception('News item not found');

      final archived = item.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(_newsTickerCollection)
          .doc(id)
          .update(archived.toJson());
      return archived;
    } catch (e) {
      throw Exception('Failed to archive news item: $e');
    }
  }

  // Publish news item (activate)
  Future<NewsTicker> publishNewsItem(String id) async {
    try {
      final item = await getNewsItemById(id);
      if (item == null) throw Exception('News item not found');

      final published = item.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(_newsTickerCollection)
          .doc(id)
          .update(published.toJson());
      return published;
    } catch (e) {
      throw Exception('Failed to publish news item: $e');
    }
  }

  // Toggle active status
  Future<NewsTicker> toggleActive(String id, bool isActive) async {
    try {
      final item = await getNewsItemById(id);
      if (item == null) throw Exception('News item not found');

      final updated = item.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(_newsTickerCollection)
          .doc(id)
          .update(updated.toJson());
      return updated;
    } catch (e) {
      throw Exception('Failed to toggle active status: $e');
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    try {
      await _firestore.collection(_newsTickerCollection).doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  // Search news items
  Future<List<NewsTicker>> searchNewsItems(String query) async {
    try {
      // Firestore doesn't support full-text search natively
      // This fetches all and filters client-side
      // For production, use Elasticsearch or Algolia
      final snapshot = await _firestore.collection(_newsTickerCollection).get();
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => NewsTicker.fromJson({...doc.data(), 'id': doc.id}))
          .where((item) {
            return item.text.toLowerCase().contains(lowerQuery) ||
                (item.link?.toLowerCase().contains(lowerQuery) ?? false);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search news items: $e');
    }
  }

  // Get news statistics
  Future<Map<String, dynamic>> getNewsStatistics() async {
    try {
      final allSnapshot = await _firestore
          .collection(_newsTickerCollection)
          .get();
      final activeSnapshot = await _firestore
          .collection(_newsTickerCollection)
          .where('isActive', isEqualTo: true)
          .get();
      final inactiveSnapshot = await _firestore
          .collection(_newsTickerCollection)
          .where('isActive', isEqualTo: false)
          .get();

      final totalViews = allSnapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc['viewCount'] as int?) ?? 0),
      );

      return {
        'total': allSnapshot.size,
        'active': activeSnapshot.size,
        'inactive': inactiveSnapshot.size,
        'totalViews': totalViews,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  // Stream all news items for real-time updates
  Stream<List<NewsTicker>> streamNewsItems() {
    return _firestore
        .collection(_newsTickerCollection)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NewsTicker.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Stream active news items for real-time updates
  Stream<List<NewsTicker>> streamActiveNewsItems() {
    return _firestore
        .collection(_newsTickerCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NewsTicker.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Get published news items (alias for getActiveNewsItems)
  Future<List<NewsTicker>> getPublishedNewsItems({int? limit}) async {
    return getActiveNewsItems(limit: limit);
  }

  // Stream published news items (alias for streamActiveNewsItems)
  Stream<List<NewsTicker>> streamPublishedNewsItems() {
    return streamActiveNewsItems();
  }

  // Schedule a news item for future publication
  Future<NewsTicker> scheduleNewsItem({
    required String text,
    String? link,
    required int priority,
    required DateTime scheduledFor,
    required String createdBy,
    Duration? expiresIn,
  }) async {
    try {
      final docRef = _firestore.collection(_newsTickerCollection).doc();
      final now = DateTime.now();
      final expiresAt = expiresIn != null ? now.add(expiresIn) : null;

      final scheduledItem = NewsTicker(
        id: docRef.id,
        text: text,
        link: link,
        isActive: false,
        priority: priority,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
        createdBy: createdBy,
        viewCount: 0,
        scheduledFor: scheduledFor,
      );

      await docRef.set(scheduledItem.toJson());
      return scheduledItem;
    } catch (e) {
      throw Exception('Failed to schedule news item: $e');
    }
  }

  // ==================== SEEDING ====================

  /// Seed sample news ticker data
  Future<void> seedSampleData() async {
    try {
      // Check if already seeded
      final existing = await _firestore
          .collection(_newsTickerCollection)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('News ticker already seeded');
        return;
      }

      final now = DateTime.now();
      final newsItems = [
        {
          'text': 'Welcome to ShopsNPorts Admin Dashboard - Your admin dashboard is now live. Manage all platform operations from here.',
          'link': null,
          'isActive': true,
          'priority': 9,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 7)),
          ),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 23))),
          'createdBy': 'system',
          'updatedAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
        },
        {
          'text': 'New Feature: Real-time Analytics - Track your business metrics in real-time with our new analytics dashboard.',
          'link': null,
          'isActive': true,
          'priority': 8,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 25))),
          'createdBy': 'admin_001',
          'updatedAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
        },
        {
          'text': 'System Maintenance Scheduled - Planned maintenance on Sunday 2AM-4AM (WAT). Services will be briefly unavailable.',
          'link': null,
          'isActive': true,
          'priority': 10,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 2)),
          ),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 5))),
          'createdBy': 'system',
          'updatedAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
        },
        {
          'text': 'Affiliate Commission Rate Increase - Great news! Premium affiliates now earn 12% commission on all sales.',
          'link': null,
          'isActive': true,
          'priority': 7,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 3)),
          ),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 27))),
          'createdBy': 'admin_001',
          'updatedAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
        },
        {
          'text': 'New Payment Gateway Integrated - Flutterwave payment gateway is now available for all transactions.',
          'link': null,
          'isActive': true,
          'priority': 6,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(hours: 18)),
          ),
          'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 14))),
          'createdBy': 'admin_001',
          'updatedAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
        },
      ];

      for (int i = 0; i < newsItems.length; i++) {
        await _firestore
            .collection(_newsTickerCollection)
            .doc('NEWS-${i + 1}')
            .set(newsItems[i]);
      }

      print('✅ Seeded ${newsItems.length} news ticker items');
    } catch (e) {
      print('Error seeding news ticker: $e');
      rethrow;
    }
  }
}
