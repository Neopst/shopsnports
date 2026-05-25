import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_discount.dart';

class InvoiceDiscountRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_discounts';

  InvoiceDiscountRepository(this._firestore);

  // Get all discounts
  Stream<List<InvoiceDiscount>> getAllDiscounts() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceDiscount.fromFirestore(doc))
            .toList());
  }

  // Get active discounts only
  Stream<List<InvoiceDiscount>> getActiveDiscounts() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceDiscount.fromFirestore(doc))
            .toList());
  }

  // Get valid discounts (active and within validity period)
  Stream<List<InvoiceDiscount>> getValidDiscounts() {
    final now = Timestamp.fromDate(DateTime.now());
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('validFrom', isLessThanOrEqualTo: now)
        .where('validUntil', isGreaterThanOrEqualTo: now)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceDiscount.fromFirestore(doc))
            .toList());
  }

  // Get discount by ID
  Future<InvoiceDiscount?> getDiscountById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceDiscount.fromFirestore(doc);
  }

  // Create new discount
  Future<String> createDiscount(InvoiceDiscount discount) async {
    final docRef = await _firestore.collection(_collection).add(discount.toFirestore());
    return docRef.id;
  }

  // Update discount
  Future<void> updateDiscount(InvoiceDiscount discount) async {
    await _firestore.collection(_collection).doc(discount.id).update({
      ...discount.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete discount
  Future<void> deleteDiscount(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Increment usage count
  Future<void> incrementUsageCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'usageCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reset usage count
  Future<void> resetUsageCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'usageCount': 0,
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

  // Get discount statistics
  Future<Map<String, dynamic>> getDiscountStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalDiscounts = snapshot.docs.length;
    int activeDiscounts =
        snapshot.docs.where((doc) => doc['isActive'] == true).length;
    int validDiscounts = snapshot.docs.where((doc) {
      final discount = InvoiceDiscount.fromFirestore(doc);
      return discount.isValid;
    }).length;
    int expiredDiscounts = snapshot.docs.where((doc) {
      final discount = InvoiceDiscount.fromFirestore(doc);
      return discount.isExpired;
    }).length;
    int totalUsage = snapshot.docs.fold<int>(
        0, (sum, doc) => sum + (doc['usageCount'] as int? ?? 0));

    // Count by type
    final typeCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final type = doc['type'] as String? ?? 'fixed';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return {
      'totalDiscounts': totalDiscounts,
      'activeDiscounts': activeDiscounts,
      'inactiveDiscounts': totalDiscounts - activeDiscounts,
      'validDiscounts': validDiscounts,
      'expiredDiscounts': expiredDiscounts,
      'totalUsage': totalUsage,
      'typeCounts': typeCounts,
    };
  }

  // Search discounts
  Stream<List<InvoiceDiscount>> searchDiscounts(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final discounts = snapshot.docs
          .map((doc) => InvoiceDiscount.fromFirestore(doc))
          .toList();
      return discounts
          .where((discount) =>
              discount.name.toLowerCase().contains(query.toLowerCase()) ||
              discount.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Get discounts by type
  Stream<List<InvoiceDiscount>> getDiscountsByType(DiscountType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceDiscount.fromFirestore(doc))
            .toList());
  }

  // Get discounts expiring soon
  Stream<List<InvoiceDiscount>> getDiscountsExpiringSoon(int days) {
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: days));

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
        .where('validUntil', isLessThanOrEqualTo: Timestamp.fromDate(expiryDate))
        .orderBy('validUntil')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceDiscount.fromFirestore(doc))
            .toList());
  }
}