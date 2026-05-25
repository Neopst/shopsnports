import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_line_item.dart';

class InvoiceLineItemRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invoice_line_items';

  InvoiceLineItemRepository(this._firestore);

  // Get all line items
  Stream<List<InvoiceLineItem>> getAllLineItems() {
    return _firestore
        .collection(_collection)
        .orderBy('description')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceLineItem.fromFirestore(doc))
            .toList());
  }

  // Get line items by category
  Stream<List<InvoiceLineItem>> getLineItemsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('description')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceLineItem.fromFirestore(doc))
            .toList());
  }

  // Get line item by ID
  Future<InvoiceLineItem?> getLineItemById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceLineItem.fromFirestore(doc);
  }

  // Search line items
  Stream<List<InvoiceLineItem>> searchLineItems(String query) {
    return _firestore
        .collection(_collection)
        .where('description', isGreaterThanOrEqualTo: query)
        .where('description', isLessThanOrEqualTo: '$query')
        .orderBy('description')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceLineItem.fromFirestore(doc))
            .toList());
  }

  // Create new line item
  Future<InvoiceLineItem> createLineItem(InvoiceLineItem lineItem) async {
    final docRef = await _firestore.collection(_collection).add(lineItem.toJson());
    final doc = await docRef.get();
    return InvoiceLineItem.fromFirestore(doc);
  }

  // Update line item
  Future<void> updateLineItem(InvoiceLineItem lineItem) async {
    await _firestore.collection(_collection).doc(lineItem.id).update(lineItem.toJson());
  }

  // Delete line item
  Future<void> deleteLineItem(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Bulk create line items
  Future<List<InvoiceLineItem>> bulkCreateLineItems(List<InvoiceLineItem> lineItems) async {
    final batch = _firestore.batch();
    final createdItems = <InvoiceLineItem>[];

    for (final item in lineItems) {
      final docRef = _firestore.collection(_collection).doc();
      batch.set(docRef, item.toJson());
    }

    await batch.commit();

    for (final item in lineItems) {
      final created = await getLineItemById(item.id);
      if (created != null) {
        createdItems.add(created);
      }
    }

    return createdItems;
  }

  // Bulk update line items
  Future<void> bulkUpdateLineItems(List<InvoiceLineItem> lineItems) async {
    final batch = _firestore.batch();

    for (final item in lineItems) {
      batch.update(_firestore.collection(_collection).doc(item.id), item.toJson());
    }

    await batch.commit();
  }

  // Bulk delete line items
  Future<void> bulkDeleteLineItems(List<String> ids) async {
    final batch = _firestore.batch();

    for (final id in ids) {
      batch.delete(_firestore.collection(_collection).doc(id));
    }

    await batch.commit();
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    final snapshot = await _firestore
        .collection(_collection)
        .get();

    final categories = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String?;
      if (category != null) {
        categories.add(category);
      }
    }

    return categories.toList()..sort();
  }

  // Get line item statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final lineItems = snapshot.docs
        .map((doc) => InvoiceLineItem.fromFirestore(doc))
        .toList();

    final totalItems = lineItems.length;
    final totalValue = lineItems.fold<double>(0, (sum, item) => sum + item.total);
    final averagePrice = lineItems.isEmpty ? 0.0 : totalValue / totalItems;

    final categoryCounts = <String, int>{};
    for (final item in lineItems) {
      final category = (item.toJson()['category'] as String?) ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return {
      'totalItems': totalItems,
      'totalValue': totalValue,
      'averagePrice': averagePrice,
      'categoryCounts': categoryCounts,
    };
  }

  // Duplicate line item
  Future<InvoiceLineItem> duplicateLineItem(String id) async {
    final original = await getLineItemById(id);
    if (original == null) throw Exception('Line item not found');

    final duplicate = InvoiceLineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: '${original.description} (Copy)',
      quantity: original.quantity,
      unitPrice: original.unitPrice,
      imageUrl: original.imageUrl,
    );

    return createLineItem(duplicate);
  }
}