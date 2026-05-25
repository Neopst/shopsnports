import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerRepositoryFirestore {
  final FirebaseFirestore _firestore;

  CustomerRepositoryFirestore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _customersCollection = 'customers';

  /// Get all customers as stream (real-time updates)
  Stream<List<Customer>> getCustomersStream() {
    return _firestore
        .collection(_customersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromFirestore(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      throw Exception('Failed to fetch customers: $error');
    });
  }

  /// Get all customers
  Future<List<Customer>> getCustomers() async {
    final snapshot = await _firestore
        .collection(_customersCollection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return Customer.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final doc =
        await _firestore.collection(_customersCollection).doc(id).get();
    if (!doc.exists) return null;
    return Customer.fromFirestore(doc.data()!, doc.id);
  }

  /// Update customer status
  Future<void> updateCustomerStatus(String customerId, String newStatus) async {
    await _firestore.collection(_customersCollection).doc(customerId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update customer profile
  Future<void> updateCustomer(String customerId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(_customersCollection)
        .doc(customerId)
        .update(data);
  }

  /// Activate customer
  Future<void> activateCustomer(String customerId) async {
    await updateCustomerStatus(customerId, 'active');
  }

  /// Suspend customer
  Future<void> suspendCustomer(String customerId) async {
    await updateCustomerStatus(customerId, 'suspended');
  }

  /// Ban customer
  Future<void> banCustomer(String customerId) async {
    await updateCustomerStatus(customerId, 'banned');
  }

  /// Add/update notes
  Future<void> updateCustomerNotes(String customerId, String notes) async {
    await _firestore.collection(_customersCollection).doc(customerId).update({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create new customer
  Future<String> createCustomer(Customer customer) async {
    final docRef =
        await _firestore.collection(_customersCollection).add(customer.toFirestore());
    return docRef.id;
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _firestore.collection(_customersCollection).doc(id).delete();
  }

  /// Search customers by name or email
  Future<List<Customer>> searchCustomers(String query) async {
    final snapshot = await _firestore
        .collection(_customersCollection)
        .orderBy('name')
        .startAt([query])
        .endAt(['${query}\uf8ff'])
        .get();

    return snapshot.docs.map((doc) {
      return Customer.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// Get customers by status
  Future<List<Customer>> getCustomersByStatus(String status) async {
    final snapshot = await _firestore
        .collection(_customersCollection)
        .where('status', isEqualTo: status)
        .get();
    return snapshot.docs.map((doc) {
      return Customer.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats() async {
    final snapshot = await _firestore.collection(_customersCollection).get();
    final customers = snapshot.docs.map((doc) {
      return Customer.fromFirestore(doc.data(), doc.id);
    }).toList();

    return {
      'total': customers.length,
      'active': customers.where((c) => c.status == 'active').length,
      'suspended': customers.where((c) => c.status == 'suspended').length,
      'banned': customers.where((c) => c.status == 'banned').length,
      'totalRevenue': customers.fold(0.0, (sum, c) => sum + c.totalSpent),
      'totalOrders': customers.fold(0, (sum, c) => sum + c.totalOrders),
    };
  }
}