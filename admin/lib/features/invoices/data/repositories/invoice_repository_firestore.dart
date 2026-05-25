import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import 'invoice_repository.dart';

/// Firestore implementation of InvoiceRepository
class InvoiceRepositoryFirestore implements InvoiceRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'invoices';

  InvoiceRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _invoicesRef => _firestore.collection(_collection);

  /// Get all invoices as stream (real-time updates)
  Stream<List<Invoice>> getAllInvoicesStream() {
    return _invoicesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<List<Invoice>> getAllInvoices() async {
    final snapshot = await _invoicesRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  @override
  Future<Invoice?> getInvoiceById(String id) async {
    final doc = await _invoicesRef.doc(id).get();
    if (!doc.exists) return null;
    return Invoice.fromFirestore(doc);
  }

  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    final docRef = _invoicesRef.doc();
    final newInvoice = invoice.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newInvoice.toJson());
    return newInvoice;
  }

  @override
  Future<Invoice> updateInvoice(Invoice invoice) async {
    final updated = invoice.copyWith(updatedAt: DateTime.now());
    await _invoicesRef.doc(invoice.id).update(updated.toJson());
    return updated;
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await _invoicesRef.doc(id).delete();
  }

  @override
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    final snapshot = await _invoicesRef
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Invoice>> getInvoicesByCustomer(String customerId) async {
    final snapshot = await _invoicesRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  @override
  Future<Invoice> markAsPaid(String id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) throw Exception('Invoice not found');
    return updateInvoice(invoice.copyWith(status: InvoiceStatus.paid));
  }

  @override
  Future<Invoice> recordPayment(
    String id, {
    required String paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
    required double amountPaid,
    String? paymentNotes,
  }) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) throw Exception('Invoice not found');

    // Check if payment amount matches total
    final isFullPayment = amountPaid >= invoice.total;

    return updateInvoice(
      invoice.copyWith(
        status: isFullPayment ? InvoiceStatus.paid : InvoiceStatus.pending,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        paymentDate: paymentDate ?? DateTime.now(),
        amountPaid: amountPaid,
        paymentNotes: paymentNotes,
      ),
    );
  }

  @override
  Future<Invoice> markAsCancelled(String id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) throw Exception('Invoice not found');
    return updateInvoice(invoice.copyWith(status: InvoiceStatus.cancelled));
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final allInvoices = await getAllInvoices();

    final totalInvoices = allInvoices.length;
    final paidInvoices = allInvoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .length;
    final pendingInvoices = allInvoices
        .where((inv) => inv.status == InvoiceStatus.pending)
        .length;
    final overdueInvoices = allInvoices
        .where((inv) => inv.status == InvoiceStatus.overdue)
        .length;

    final totalRevenue = allInvoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .fold(0.0, (sum, inv) => sum + inv.total);

    final pendingAmount = allInvoices
        .where((inv) => inv.status == InvoiceStatus.pending)
        .fold(0.0, (sum, inv) => sum + inv.total);

    return {
      'totalInvoices': totalInvoices,
      'paidInvoices': paidInvoices,
      'pendingInvoices': pendingInvoices,
      'overdueInvoices': overdueInvoices,
      'totalRevenue': totalRevenue,
      'pendingAmount': pendingAmount,
    };
  }

  @override
  Future<void> bulkDelete(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_invoicesRef.doc(id));
    }
    await batch.commit();
  }

  /// Seed sample invoice data
  Future<void> seedSampleData() async {
    final existing = await _invoicesRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final now = DateTime.now();

    final sampleInvoices = [
      {
        'id': 'inv_001',
        'invoiceNumber': 'INV-2024-001',
        'customerId': 'cust_001',
        'customerName': 'James Wilson',
        'status': InvoiceStatus.paid.name,
        'items': [
          {
            'description': 'Shipping Service - Express Delivery',
            'quantity': 1,
            'unitPrice': 25000.0,
            'total': 25000.0,
          },
        ],
        'subtotal': 25000.0,
        'tax': 1875.0,
        'discount': 0.0,
        'total': 26875.0,
        'dueDate': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'paidDate': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'notes': 'Payment received - Thank you',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'inv_002',
        'invoiceNumber': 'INV-2024-002',
        'customerId': 'cust_002',
        'customerName': 'Sarah Johnson',
        'status': InvoiceStatus.pending.name,
        'items': [
          {
            'description': 'Affiliate Commission Payment',
            'quantity': 1,
            'unitPrice': 15000.0,
            'total': 15000.0,
          },
        ],
        'subtotal': 15000.0,
        'tax': 1125.0,
        'discount': 0.0,
        'total': 16125.0,
        'dueDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'paidDate': null,
        'notes': 'Payment due in 7 days',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'inv_003',
        'invoiceNumber': 'INV-2024-003',
        'customerId': 'cust_003',
        'customerName': 'Michael Brown',
        'status': InvoiceStatus.overdue.name,
        'items': [
          {
            'description': 'Shipping Service - Standard',
            'quantity': 2,
            'unitPrice': 12000.0,
            'total': 24000.0,
          },
        ],
        'subtotal': 24000.0,
        'tax': 1800.0,
        'discount': 2000.0,
        'total': 23800.0,
        'dueDate': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        'paidDate': null,
        'notes': 'OVERDUE - Follow up required',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 45))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final invoice in sampleInvoices) {
      batch.set(_invoicesRef.doc(invoice['id'] as String), invoice);
    }

    await batch.commit();
  }
}
