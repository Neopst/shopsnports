import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_sound.dart';

class NotificationSoundRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'notification_sounds';

  NotificationSoundRepository(this._firestore);

  // Get all sounds
  Stream<List<NotificationSound>> getAllSounds() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationSound.fromFirestore(doc)).toList());
  }

  // Get active sounds only
  Stream<List<NotificationSound>> getActiveSounds() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationSound.fromFirestore(doc)).toList());
  }

  // Get sounds by category
  Stream<List<NotificationSound>> getSoundsByCategory(SoundCategory category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationSound.fromFirestore(doc)).toList());
  }

  // Get default sound
  Future<NotificationSound?> getDefaultSound() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return NotificationSound.fromFirestore(snapshot.docs.first);
  }

  // Get sound by ID
  Future<NotificationSound?> getSoundById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return NotificationSound.fromFirestore(doc);
  }

  // Create new sound
  Future<String> createSound(NotificationSound sound) async {
    final docRef = await _firestore.collection(_collection).add(sound.toFirestore());
    return docRef.id;
  }

  // Update sound
  Future<void> updateSound(NotificationSound sound) async {
    await _firestore.collection(_collection).doc(sound.id).update({
      ...sound.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete sound
  Future<void> deleteSound(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Increment usage count
  Future<void> incrementUsageCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  // Set as default (only one default per category)
  Future<void> setAsDefault(String id) async {
    final sound = await getSoundById(id);
    if (sound == null) return;

    // Remove default from other sounds in same category
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_collection)
        .where('category', isEqualTo: sound.category.value)
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(_firestore.collection(_collection).doc(id), {
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get sound statistics
  Future<Map<String, dynamic>> getSoundStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalSounds = snapshot.docs.length;
    int activeSounds = snapshot.docs.where((doc) => doc['isActive'] == true).length;
    int totalUsage = snapshot.docs.fold<int>(
        0, (sum, doc) => sum + (doc['usageCount'] as int? ?? 0));

    // Count by category
    final categoryCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final category = doc['category'] as String? ?? 'default';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return {
      'totalSounds': totalSounds,
      'activeSounds': activeSounds,
      'inactiveSounds': totalSounds - activeSounds,
      'totalUsage': totalUsage,
      'categoryCounts': categoryCounts,
    };
  }

  // Search sounds
  Stream<List<NotificationSound>> searchSounds(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final sounds = snapshot.docs
          .map((doc) => NotificationSound.fromFirestore(doc))
          .toList();
      return sounds
          .where((sound) =>
              sound.name.toLowerCase().contains(query.toLowerCase()) ||
              sound.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
}