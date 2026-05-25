import 'package:cloud_firestore/cloud_firestore.dart';

/// News Ticker Item model
class NewsTickerItem {
  final String id;
  final String text;
  final String? link;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  NewsTickerItem({
    required this.id,
    required this.text,
    this.link,
    this.priority = 0,
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
  });

  factory NewsTickerItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsTickerItem(
      id: doc.id,
      text: data['text'] as String? ?? '',
      link: data['link'] as String?,
      priority: data['priority'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? data['is_active'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => isActive && !isExpired;
}

/// News Ticker Service - Firestore-based
///
/// Firebase is the single source of truth for all news ticker data
class NewsTickerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final NewsTickerService _instance = NewsTickerService._();
  factory NewsTickerService() => _instance;
  NewsTickerService._();

  /// Get all news items (admin use)
  Future<List<NewsTickerItem>> getAllNewsItems() async {
    try {
      final snapshot = await _db
          .collection('news_ticker')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NewsTickerItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Silently fail - empty list returned
      return [];
    }
  }

  /// Get active news items for display
  Future<List<NewsTickerItem>> getActiveNewsItems({int limit = 20}) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      final snapshot = await _db
          .collection('news_ticker')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: now)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsTickerItem.fromFirestore(doc))
          .where((item) => item.isValid)
          .toList();
    } catch (e) {
      // Silently fail - empty list returned
      return [];
    }
  }

  /// Stream of active news items (real-time updates)
  Stream<List<NewsTickerItem>> watchActiveNewsItems({int limit = 20}) {
    return _db
        .collection('news_ticker')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsTickerItem.fromFirestore(doc))
          .where((item) => item.isValid)
          .toList();
    });
  }

  /// Get single news item by ID
  Future<NewsTickerItem?> getNewsItemById(String id) async {
    try {
      final doc = await _db.collection('news_ticker').doc(id).get();
      if (doc.exists) {
        return NewsTickerItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Silently fail - return null
      return null;
    }
  }
}