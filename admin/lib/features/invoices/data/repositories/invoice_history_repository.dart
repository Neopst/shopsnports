import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_history.dart';

class InvoiceHistoryRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invoice_history';

  InvoiceHistoryRepository(this._firestore);

  // Get all history for an invoice
  Stream<List<InvoiceHistory>> getHistoryForInvoice(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get all history
  Stream<List<InvoiceHistory>> getAllHistory() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get history by action type
  Stream<List<InvoiceHistory>> getHistoryByAction(HistoryAction action) {
    return _firestore
        .collection(_collection)
        .where('action', isEqualTo: action.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get history by user
  Stream<List<InvoiceHistory>> getHistoryByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('performedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get history by date range
  Stream<List<InvoiceHistory>> getHistoryByDateRange(DateTime start, DateTime end) {
    return _firestore
        .collection(_collection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get history entry by ID
  Future<InvoiceHistory?> getHistoryById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceHistory.fromFirestore(doc);
  }

  // Create new history entry
  Future<InvoiceHistory> createHistory(InvoiceHistory history) async {
    final docRef = await _firestore.collection(_collection).add(history.toFirestore());
    final doc = await docRef.get();
    return InvoiceHistory.fromFirestore(doc);
  }

  // Log an action
  Future<void> logAction({
    required String invoiceId,
    required HistoryAction action,
    required String description,
    required String performedBy,
    String? performedByRole,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? ipAddress,
    String? userAgent,
    bool isSystemGenerated = false,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) async {
    final history = InvoiceHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceId: invoiceId,
      action: action,
      description: description,
      oldValue: oldValue ?? {},
      newValue: newValue ?? {},
      createdAt: DateTime.now(),
      performedBy: performedBy,
      performedByRole: performedByRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      isSystemGenerated: isSystemGenerated,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      metadata: metadata ?? {},
    );

    await createHistory(history);
  }

  // Get recent history
  Stream<List<InvoiceHistory>> getRecentHistory({int limit = 50}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get system-generated history only
  Stream<List<InvoiceHistory>> getSystemHistory(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('isSystemGenerated', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get user-generated history only
  Stream<List<InvoiceHistory>> getUserHistory(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .where('isSystemGenerated', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Search history
  Stream<List<InvoiceHistory>> searchHistory(String query) {
    return _firestore
        .collection(_collection)
        .where('description', isGreaterThanOrEqualTo: query)
        .where('description', isLessThanOrEqualTo: '$query')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Get history statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final history = snapshot.docs
        .map((doc) => InvoiceHistory.fromFirestore(doc))
        .toList();

    final totalEntries = history.length;
    final systemEntries = history.where((h) => h.isSystemGenerated).length;
    final userEntries = history.where((h) => !h.isSystemGenerated).length;

    final actionCounts = <HistoryAction, int>{};
    for (final entry in history) {
      actionCounts[entry.action] = (actionCounts[entry.action] ?? 0) + 1;
    }

    final userActivity = <String, int>{};
    for (final entry in history) {
      userActivity[entry.performedBy] = (userActivity[entry.performedBy] ?? 0) + 1;
    }

    return {
      'totalEntries': totalEntries,
      'systemEntries': systemEntries,
      'userEntries': userEntries,
      'actionCounts': actionCounts,
      'userActivity': userActivity,
    };
  }

  // Get history for related entity
  Stream<List<InvoiceHistory>> getHistoryForRelatedEntity(
    String relatedEntityId,
    String relatedEntityType,
  ) {
    return _firestore
        .collection(_collection)
        .where('relatedEntityId', isEqualTo: relatedEntityId)
        .where('relatedEntityType', isEqualTo: relatedEntityType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceHistory.fromFirestore(doc))
            .toList());
  }

  // Delete old history (cleanup)
  Future<void> deleteOldHistory({DateTime? beforeDate}) async {
    final cutoffDate = beforeDate ?? DateTime.now().subtract(const Duration(days: 365));

    final snapshot = await _firestore
        .collection(_collection)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Export history to CSV
  Future<String> exportHistoryToCSV(String invoiceId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .get();

    final history = snapshot.docs
        .map((doc) => InvoiceHistory.fromFirestore(doc))
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('Date,Action,Description,Performed By,Role,IP Address');

    for (final entry in history) {
      buffer.writeln(
        '${entry.createdAt.toIso8601String()},'
        '${entry.action.name},'
        '"${entry.description}",'
        '${entry.performedBy},'
        '${entry.performedByRole ?? ""},'
        '${entry.ipAddress ?? ""}',
      );
    }

    return buffer.toString();
  }
}