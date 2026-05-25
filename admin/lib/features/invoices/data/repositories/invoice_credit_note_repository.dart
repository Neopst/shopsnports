import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_credit_note.dart';

class InvoiceCreditNoteRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invoice_credit_notes';

  InvoiceCreditNoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new credit note
  Future<String> createCreditNote(InvoiceCreditNote creditNote) async {
    final docRef = _firestore.collection(_collection).doc();
    final newCreditNote = creditNote.copyWith(id: docRef.id);
    await docRef.set(newCreditNote.toFirestore());
    return docRef.id;
  }

  // Get a credit note by ID
  Future<InvoiceCreditNote?> getCreditNoteById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceCreditNote.fromFirestore(doc);
  }

  // Get credit note by number
  Future<InvoiceCreditNote?> getCreditNoteByNumber(String number) async {
    final query = await _firestore
        .collection(_collection)
        .where('creditNoteNumber', isEqualTo: number)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return InvoiceCreditNote.fromFirestore(query.docs.first);
  }

  // Get all credit notes
  Future<List<InvoiceCreditNote>> getAllCreditNotes() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get credit notes by invoice ID
  Future<List<InvoiceCreditNote>> getCreditNotesByInvoiceId(String invoiceId) async {
    final query = await _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get credit notes by customer ID
  Future<List<InvoiceCreditNote>> getCreditNotesByCustomerId(String customerId) async {
    final query = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get credit notes by status
  Future<List<InvoiceCreditNote>> getCreditNotesByStatus(CreditNoteStatus status) async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get pending credit notes
  Future<List<InvoiceCreditNote>> getPendingCreditNotes() async {
    return getCreditNotesByStatus(CreditNoteStatus.pending);
  }

  // Get approved but not applied credit notes
  Future<List<InvoiceCreditNote>> getApprovedUnappliedCreditNotes() async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: CreditNoteStatus.approved.value)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => InvoiceCreditNote.fromFirestore(doc))
        .where((note) => !note.isApplied)
        .toList();
  }

  // Update a credit note
  Future<void> updateCreditNote(InvoiceCreditNote creditNote) async {
    await _firestore
        .collection(_collection)
        .doc(creditNote.id)
        .update(creditNote.toFirestore()..['updatedAt'] = FieldValue.serverTimestamp());
  }

  // Delete a credit note
  Future<void> deleteCreditNote(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Approve a credit note
  Future<void> approveCreditNote(String id, String approvedBy) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': CreditNoteStatus.approved.value,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Apply a credit note to an invoice
  Future<void> applyCreditNote(String id, String appliedToInvoiceId) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': CreditNoteStatus.applied.value,
      'appliedToInvoiceId': appliedToInvoiceId,
      'appliedDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Void a credit note
  Future<void> voidCreditNote(String id, String? reason) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': CreditNoteStatus.voided.value,
      'updatedAt': FieldValue.serverTimestamp(),
      if (reason != null) 'voidReason': reason,
    });
  }

  // Get credit notes by date range
  Future<List<InvoiceCreditNote>> getCreditNotesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final query = await _firestore
        .collection(_collection)
        .where('issueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('issueDate', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get credit notes by reason
  Future<List<InvoiceCreditNote>> getCreditNotesByReason(CreditNoteReason reason) async {
    final query = await _firestore
        .collection(_collection)
        .where('reason', isEqualTo: reason.value)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList();
  }

  // Get credit notes statistics
  Future<Map<String, dynamic>> getCreditNotesStatistics() async {
    final allNotes = await getAllCreditNotes();

    final totalAmount = allNotes.fold<double>(
      0,
      (sum, note) => sum + note.totalAmount,
    );

    final appliedAmount = allNotes
        .where((note) => note.isApplied)
        .fold<double>(0, (sum, note) => sum + note.totalAmount);

    final pendingAmount = allNotes
        .where((note) => note.isPending)
        .fold<double>(0, (sum, note) => sum + note.totalAmount);

    final statusCounts = <String, int>{};
    for (final note in allNotes) {
      statusCounts[note.status.value] = (statusCounts[note.status.value] ?? 0) + 1;
    }

    final reasonCounts = <String, int>{};
    for (final note in allNotes) {
      reasonCounts[note.reason.value] = (reasonCounts[note.reason.value] ?? 0) + 1;
    }

    return {
      'totalCreditNotes': allNotes.length,
      'totalAmount': totalAmount,
      'appliedAmount': appliedAmount,
      'pendingAmount': pendingAmount,
      'unappliedAmount': totalAmount - appliedAmount,
      'statusCounts': statusCounts,
      'reasonCounts': reasonCounts,
    };
  }

  // Search credit notes
  Future<List<InvoiceCreditNote>> searchCreditNotes(String query) async {
    final numberResults = await _firestore
        .collection(_collection)
        .where('creditNoteNumber', isGreaterThanOrEqualTo: query)
        .where('creditNoteNumber', isLessThanOrEqualTo: query + '')
        .get();

    final results = <InvoiceCreditNote>{};
    for (final doc in numberResults.docs) {
      results.add(InvoiceCreditNote.fromFirestore(doc));
    }

    return results.toList();
  }

  // Get next credit note number
  Future<String> getNextCreditNoteNumber() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('creditNoteNumber', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return 'CN-000001';
    }

    final lastNumber = query.docs.first.data()['creditNoteNumber'] as String;
    final numberPart = lastNumber.split('-').last;
    final nextNumber = int.parse(numberPart) + 1;
    return 'CN-${nextNumber.toString().padLeft(6, '0')}';
  }

  // Stream credit notes by invoice ID
  Stream<List<InvoiceCreditNote>> streamCreditNotesByInvoiceId(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList());
  }

  // Stream all credit notes
  Stream<List<InvoiceCreditNote>> streamAllCreditNotes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => InvoiceCreditNote.fromFirestore(doc)).toList());
  }
}