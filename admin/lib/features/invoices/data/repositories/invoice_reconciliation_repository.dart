import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_reconciliation.dart';

class InvoiceReconciliationRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_reconciliations';

  InvoiceReconciliationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new reconciliation record
  Future<InvoiceReconciliation> create(InvoiceReconciliation reconciliation) async {
    final docRef = _firestore.collection(_collection).doc();
    final newReconciliation = reconciliation.copyWith(id: docRef.id);

    await docRef.set(newReconciliation.toJson());
    return newReconciliation;
  }

  // Get reconciliation by ID
  Future<InvoiceReconciliation?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    return InvoiceReconciliation.fromJson(doc.data()!);
  }

  // Get reconciliation by invoice ID
  Future<InvoiceReconciliation?> getByInvoiceId(String invoiceId) async {
    final query = await _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return InvoiceReconciliation.fromJson(query.docs.first.data());
  }

  // Get all reconciliations
  Future<List<InvoiceReconciliation>> getAll() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
        .toList();
  }

  // Get reconciliations by status
  Future<List<InvoiceReconciliation>> getByStatus(ReconciliationStatus status) async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
        .toList();
  }

  // Get overdue reconciliations
  Future<List<InvoiceReconciliation>> getOverdue() async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReconciliationStatus.overdue.name)
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
        .toList();
  }

  // Get pending reconciliations
  Future<List<InvoiceReconciliation>> getPending() async {
    final query = await _firestore
        .collection(_collection)
        .where('status', whereIn: [
          ReconciliationStatus.pending.name,
          ReconciliationStatus.partiallyPaid.name,
        ])
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
        .toList();
  }

  // Update reconciliation
  Future<void> update(InvoiceReconciliation reconciliation) async {
    await _firestore
        .collection(_collection)
        .doc(reconciliation.id)
        .update(reconciliation.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Add payment to reconciliation
  Future<InvoiceReconciliation> addPayment(
    String reconciliationId,
    PaymentRecord payment,
  ) async {
    final reconciliation = await getById(reconciliationId);
    if (reconciliation == null) {
      throw Exception('Reconciliation not found');
    }

    final updatedPayments = [...reconciliation.payments, payment];
    final totalPaid = updatedPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final outstanding = reconciliation.invoiceAmount - totalPaid;

    ReconciliationStatus newStatus;
    if (outstanding <= 0.01) {
      newStatus = ReconciliationStatus.fullyPaid;
    } else if (totalPaid > 0) {
      newStatus = ReconciliationStatus.partiallyPaid;
    } else {
      newStatus = reconciliation.status;
    }

    final updated = reconciliation.copyWith(
      payments: updatedPayments,
      paidAmount: totalPaid,
      outstandingAmount: outstanding,
      status: newStatus,
      lastPaymentDate: payment.paymentDate,
      updatedAt: DateTime.now(),
    );

    await update(updated);
    return updated;
  }

  // Mark as reconciled
  Future<void> markAsReconciled(
    String reconciliationId,
    String userId,
  ) async {
    final reconciliation = await getById(reconciliationId);
    if (reconciliation == null) {
      throw Exception('Reconciliation not found');
    }

    await update(reconciliation.copyWith(
      reconciledBy: userId,
      reconciledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  // Mark as disputed
  Future<void> markAsDisputed(
    String reconciliationId,
    String notes,
  ) async {
    final reconciliation = await getById(reconciliationId);
    if (reconciliation == null) {
      throw Exception('Reconciliation not found');
    }

    await update(reconciliation.copyWith(
      status: ReconciliationStatus.disputed,
      notes: notes,
      updatedAt: DateTime.now(),
    ));
  }

  // Write off invoice
  Future<void> writeOff(
    String reconciliationId,
    String notes,
  ) async {
    final reconciliation = await getById(reconciliationId);
    if (reconciliation == null) {
      throw Exception('Reconciliation not found');
    }

    await update(reconciliation.copyWith(
      status: ReconciliationStatus.writtenOff,
      notes: notes,
      updatedAt: DateTime.now(),
    ));
  }

  // Delete reconciliation
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Stream all reconciliations
  Stream<List<InvoiceReconciliation>> streamAll() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
            .toList());
  }

  // Stream by status
  Stream<List<InvoiceReconciliation>> streamByStatus(ReconciliationStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceReconciliation.fromJson(doc.data()))
            .toList());
  }

  // Get reconciliation statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final all = await getAll();

    final totalInvoices = all.length;
    final totalAmount = all.fold<double>(0, (sum, r) => sum + r.invoiceAmount);
    final totalPaid = all.fold<double>(0, (sum, r) => sum + r.paidAmount);
    final totalOutstanding = all.fold<double>(0, (sum, r) => sum + r.outstandingAmount);

    final pending = all.where((r) => r.status == ReconciliationStatus.pending).length;
    final partiallyPaid = all.where((r) => r.status == ReconciliationStatus.partiallyPaid).length;
    final fullyPaid = all.where((r) => r.status == ReconciliationStatus.fullyPaid).length;
    final overdue = all.where((r) => r.status == ReconciliationStatus.overdue).length;
    final disputed = all.where((r) => r.status == ReconciliationStatus.disputed).length;
    final writtenOff = all.where((r) => r.status == ReconciliationStatus.writtenOff).length;

    return {
      'totalInvoices': totalInvoices,
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalOutstanding': totalOutstanding,
      'collectionRate': totalAmount > 0 ? (totalPaid / totalAmount) * 100 : 0,
      'pending': pending,
      'partiallyPaid': partiallyPaid,
      'fullyPaid': fullyPaid,
      'overdue': overdue,
      'disputed': disputed,
      'writtenOff': writtenOff,
    };
  }
}