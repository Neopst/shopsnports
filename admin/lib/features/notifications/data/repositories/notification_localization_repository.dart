import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_localization.dart';

class NotificationLocalizationRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'notification_localizations';

  NotificationLocalizationRepository(this._firestore);

  // Get all localizations
  Stream<List<NotificationLocalization>> getAllLocalizations() {
    return _firestore
        .collection(_collection)
        .orderBy('key')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationLocalization.fromFirestore(doc))
            .toList());
  }

  // Get active localizations only
  Stream<List<NotificationLocalization>> getActiveLocalizations() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('key')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationLocalization.fromFirestore(doc))
            .toList());
  }

  // Get localization by key
  Future<NotificationLocalization?> getLocalizationByKey(String key) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('key', isEqualTo: key)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return NotificationLocalization.fromFirestore(snapshot.docs.first);
  }

  // Get localization by ID
  Future<NotificationLocalization?> getLocalizationById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return NotificationLocalization.fromFirestore(doc);
  }

  // Create new localization
  Future<String> createLocalization(
      NotificationLocalization localization) async {
    final docRef =
        await _firestore.collection(_collection).add(localization.toFirestore());
    return docRef.id;
  }

  // Update localization
  Future<void> updateLocalization(
      NotificationLocalization localization) async {
    await _firestore.collection(_collection).doc(localization.id).update({
      ...localization.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete localization
  Future<void> deleteLocalization(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Add or update translation for a specific language
  Future<void> updateTranslation(
      String id, String languageCode, String translatedText) async {
    await _firestore.collection(_collection).doc(id).update({
      'translations.$languageCode': translatedText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove translation for a specific language
  Future<void> removeTranslation(String id, String languageCode) async {
    await _firestore.collection(_collection).doc(id).update({
      'translations.$languageCode': FieldValue.delete(),
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

  // Get localization statistics
  Future<Map<String, dynamic>> getLocalizationStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalLocalizations = snapshot.docs.length;
    int activeLocalizations =
        snapshot.docs.where((doc) => doc['isActive'] == true).length;

    // Count translations by language
    final languageCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final translations =
          doc['translations'] as Map<String, dynamic>? ?? {};
      for (final langCode in translations.keys) {
        languageCounts[langCode] = (languageCounts[langCode] ?? 0) + 1;
      }
    }

    // Calculate completion percentage for each language
    final languageCompletion = <String, double>{};
    for (final lang in SupportedLanguage.all) {
      final count = languageCounts[lang.code] ?? 0;
      final completion = totalLocalizations > 0
          ? (count / totalLocalizations * 100).roundToDouble()
          : 0.0;
      languageCompletion[lang.code] = completion;
    }

    return {
      'totalLocalizations': totalLocalizations,
      'activeLocalizations': activeLocalizations,
      'inactiveLocalizations': totalLocalizations - activeLocalizations,
      'languageCounts': languageCounts,
      'languageCompletion': languageCompletion,
    };
  }

  // Search localizations by key
  Stream<List<NotificationLocalization>> searchLocalizations(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('key')
        .snapshots()
        .map((snapshot) {
      final localizations = snapshot.docs
          .map((doc) => NotificationLocalization.fromFirestore(doc))
          .toList();
      return localizations
          .where((loc) => loc.key.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Get localizations missing translations for a specific language
  Stream<List<NotificationLocalization>>
      getLocalizationsMissingTranslation(String languageCode) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final localizations = snapshot.docs
          .map((doc) => NotificationLocalization.fromFirestore(doc))
          .toList();
      return localizations
          .where((loc) => !loc.translations.containsKey(languageCode))
          .toList();
    });
  }

  // Batch import localizations
  Future<void> batchImportLocalizations(
      List<NotificationLocalization> localizations) async {
    final batch = _firestore.batch();
    for (final localization in localizations) {
      final docRef = _firestore.collection(_collection).doc();
      batch.set(docRef, localization.toFirestore());
    }
    await batch.commit();
  }

  // Export localizations
  Future<Map<String, Map<String, String>>> exportLocalizations() async {
    final snapshot = await _firestore.collection(_collection).get();
    final export = <String, Map<String, String>>{};

    for (final doc in snapshot.docs) {
      final loc = NotificationLocalization.fromFirestore(doc);
      export[loc.key] = loc.translations;
    }

    return export;
  }
}