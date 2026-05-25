import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_badge.dart';

class NotificationBadgeRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'notification_badges';

  NotificationBadgeRepository(this._firestore);

  // Get all badges
  Stream<List<NotificationBadge>> getAllBadges() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationBadge.fromFirestore(doc)).toList());
  }

  // Get active badges only
  Stream<List<NotificationBadge>> getActiveBadges() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationBadge.fromFirestore(doc)).toList());
  }

  // Get badges by type
  Stream<List<NotificationBadge>> getBadgesByType(BadgeType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationBadge.fromFirestore(doc)).toList());
  }

  // Get badge by ID
  Future<NotificationBadge?> getBadgeById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return NotificationBadge.fromFirestore(doc);
  }

  // Create new badge
  Future<String> createBadge(NotificationBadge badge) async {
    final docRef = await _firestore.collection(_collection).add(badge.toFirestore());
    return docRef.id;
  }

  // Update badge
  Future<void> updateBadge(NotificationBadge badge) async {
    await _firestore.collection(_collection).doc(badge.id).update({
      ...badge.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete badge
  Future<void> deleteBadge(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Update display count
  Future<void> updateDisplayCount(String id, int count) async {
    await _firestore.collection(_collection).doc(id).update({
      'displayCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment display count
  Future<void> incrementDisplayCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'displayCount': FieldValue.increment(1),
    });
  }

  // Reset display count
  Future<void> resetDisplayCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'displayCount': 0,
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

  // Get badge statistics
  Future<Map<String, dynamic>> getBadgeStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalBadges = snapshot.docs.length;
    int activeBadges = snapshot.docs.where((doc) => doc['isActive'] == true).length;
    int totalDisplayCount = snapshot.docs.fold<int>(
        0, (sum, doc) => sum + (doc['displayCount'] as int? ?? 0));

    // Count by type
    final typeCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final type = doc['type'] as String? ?? 'default';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return {
      'totalBadges': totalBadges,
      'activeBadges': activeBadges,
      'inactiveBadges': totalBadges - activeBadges,
      'totalDisplayCount': totalDisplayCount,
      'typeCounts': typeCounts,
    };
  }

  // Search badges
  Stream<List<NotificationBadge>> searchBadges(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final badges = snapshot.docs
          .map((doc) => NotificationBadge.fromFirestore(doc))
          .toList();
      return badges
          .where((badge) =>
              badge.name.toLowerCase().contains(query.toLowerCase()) ||
              badge.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Get badges with high display count
  Stream<List<NotificationBadge>> getHighDisplayBadges(int threshold) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('displayCount', isGreaterThan: threshold)
        .orderBy('displayCount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationBadge.fromFirestore(doc)).toList());
  }
}