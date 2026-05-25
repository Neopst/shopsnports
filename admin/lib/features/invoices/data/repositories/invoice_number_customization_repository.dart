import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_number_customization.dart';

class InvoiceNumberCustomizationRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_number_customizations';

  InvoiceNumberCustomizationRepository(this._firestore);

  // Get all customizations
  Stream<List<InvoiceNumberCustomization>> getAllCustomizations() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNumberCustomization.fromFirestore(doc))
            .toList());
  }

  // Get active customizations only
  Stream<List<InvoiceNumberCustomization>> getActiveCustomizations() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceNumberCustomization.fromFirestore(doc))
            .toList());
  }

  // Get customization by ID
  Future<InvoiceNumberCustomization?> getCustomizationById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceNumberCustomization.fromFirestore(doc);
  }

  // Get default customization
  Future<InvoiceNumberCustomization?> getDefaultCustomization() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InvoiceNumberCustomization.fromFirestore(snapshot.docs.first);
  }

  // Create new customization
  Future<String> createCustomization(
      InvoiceNumberCustomization customization) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(customization.toFirestore());
    return docRef.id;
  }

  // Update customization
  Future<void> updateCustomization(
      InvoiceNumberCustomization customization) async {
    await _firestore.collection(_collection).doc(customization.id).update({
      ...customization.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete customization
  Future<void> deleteCustomization(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Generate next invoice number
  Future<String> generateNextNumber(String id) async {
    final customization = await getCustomizationById(id);
    if (customization == null) throw Exception('Customization not found');

    final nextNumber = customization.generateNextNumber();

    // Update current number
    await _firestore.collection(_collection).doc(id).update({
      'currentNumber': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return nextNumber;
  }

  // Preview next number without incrementing
  Future<String> previewNextNumber(String id) async {
    final customization = await getCustomizationById(id);
    if (customization == null) throw Exception('Customization not found');
    return customization.generateNextNumber();
  }

  // Reset number to start
  Future<void> resetNumber(String id) async {
    final customization = await getCustomizationById(id);
    if (customization == null) throw Exception('Customization not found');

    await _firestore.collection(_collection).doc(id).update({
      'currentNumber': customization.startNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Set custom number
  Future<void> setCustomNumber(String id, int number) async {
    await _firestore.collection(_collection).doc(id).update({
      'currentNumber': number,
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

  // Get customization statistics
  Future<Map<String, dynamic>> getCustomizationStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalCustomizations = snapshot.docs.length;
    int activeCustomizations =
        snapshot.docs.where((doc) => doc['isActive'] == true).length;

    // Count by format
    final formatCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final format = doc['format'] as String? ?? 'numeric';
      formatCounts[format] = (formatCounts[format] ?? 0) + 1;
    }

    return {
      'totalCustomizations': totalCustomizations,
      'activeCustomizations': activeCustomizations,
      'inactiveCustomizations': totalCustomizations - activeCustomizations,
      'formatCounts': formatCounts,
    };
  }

  // Search customizations
  Stream<List<InvoiceNumberCustomization>> searchCustomizations(
      String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final customizations = snapshot.docs
          .map((doc) => InvoiceNumberCustomization.fromFirestore(doc))
          .toList();
      return customizations
          .where((customization) =>
              customization.name.toLowerCase().contains(query.toLowerCase()) ||
              customization.description
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }
}