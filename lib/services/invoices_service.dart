import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Invoice model
class Invoice {
  final String id;
  final String invoiceNumber;
  final String shippingRequestId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.shippingRequestId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      shippingRequestId: data['shippingRequestId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'] as String?,
      notes: data['notes'] as String?,
    );
  }
}

/// Invoices Service - Firestore-based
///
/// Firebase is the single source of truth for all invoice data
class InvoicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final InvoicesService _instance = InvoicesService._();
  factory InvoicesService() => _instance;
  InvoicesService._();

  /// Get all invoices for current user
  Future<List<Invoice>> getUserInvoices({String? status}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('invoices')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
    } catch (e) {
      // Silently fail - empty list returned
      return [];
    }
  }

  /// Stream of user invoices (real-time updates)
  Stream<List<Invoice>> watchUserInvoices({String? status}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _db
        .collection('invoices')
        .where('customerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
    });
  }

  /// Get single invoice by ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _db.collection('invoices').doc(invoiceId).get();
      if (doc.exists) {
        return Invoice.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Silently fail - return null
      return null;
    }
  }

  /// Get invoice statistics for user
  Future<Map<String, dynamic>> getUserInvoiceStats() async {
    final user = _auth.currentUser;
    if (user == null) return {'total': 0, 'pending': 0, 'paid': 0, 'totalAmount': 0.0};

    try {
      final snapshot = await _db
          .collection('invoices')
          .where('customerId', isEqualTo: user.uid)
          .get();

      int total = snapshot.docs.length;
      int pending = 0;
      int paid = 0;
      double totalAmount = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'pending') pending++;
        if (data['status'] == 'paid') {
          paid++;
          totalAmount += (data['amount'] as num).toDouble();
        }
      }

      return {
        'total': total,
        'pending': pending,
        'paid': paid,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      // Silently fail - return empty stats
      return {'total': 0, 'pending': 0, 'paid': 0, 'totalAmount': 0.0};
    }
  }
}