import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_deep_link.dart';

class NotificationDeepLinkRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'notification_deep_links';

  NotificationDeepLinkRepository(this._firestore);

  // Get all deep links
  Stream<List<NotificationDeepLink>> getAllDeepLinks() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationDeepLink.fromFirestore(doc))
            .toList());
  }

  // Get active deep links only
  Stream<List<NotificationDeepLink>> getActiveDeepLinks() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationDeepLink.fromFirestore(doc))
            .toList());
  }

  // Get deep links by type
  Stream<List<NotificationDeepLink>> getDeepLinksByType(LinkType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationDeepLink.fromFirestore(doc))
            .toList());
  }

  // Get deep link by ID
  Future<NotificationDeepLink?> getDeepLinkById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return NotificationDeepLink.fromFirestore(doc);
  }

  // Create new deep link
  Future<String> createDeepLink(NotificationDeepLink deepLink) async {
    final docRef =
        await _firestore.collection(_collection).add(deepLink.toFirestore());
    return docRef.id;
  }

  // Update deep link
  Future<void> updateDeepLink(NotificationDeepLink deepLink) async {
    await _firestore.collection(_collection).doc(deepLink.id).update({
      ...deepLink.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete deep link
  Future<void> deleteDeepLink(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Increment click count
  Future<void> incrementClickCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'clickCount': FieldValue.increment(1),
    });
  }

  // Reset click count
  Future<void> resetClickCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'clickCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get deep link statistics
  Future<Map<String, dynamic>> getDeepLinkStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalLinks = snapshot.docs.length;
    int activeLinks =
        snapshot.docs.where((doc) => doc['isActive'] == true).length;
    int totalClicks = snapshot.docs.fold<int>(
        0, (sum, doc) => sum + (doc['clickCount'] as int? ?? 0));

    // Count by type
    final typeCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final type = doc['type'] as String? ?? 'default';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return {
      'totalLinks': totalLinks,
      'activeLinks': activeLinks,
      'inactiveLinks': totalLinks - activeLinks,
      'totalClicks': totalClicks,
      'typeCounts': typeCounts,
    };
  }

  // Search deep links
  Stream<List<NotificationDeepLink>> searchDeepLinks(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final links = snapshot.docs
          .map((doc) => NotificationDeepLink.fromFirestore(doc))
          .toList();
      return links
          .where((link) =>
              link.name.toLowerCase().contains(query.toLowerCase()) ||
              link.description.toLowerCase().contains(query.toLowerCase()) ||
              link.linkUrl.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Get most clicked deep links
  Stream<List<NotificationDeepLink>> getMostClickedDeepLinks(int limit) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('clickCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationDeepLink.fromFirestore(doc))
            .toList());
  }
}