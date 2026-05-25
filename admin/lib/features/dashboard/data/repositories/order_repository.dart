// lib/features/dashboard/data/repositories/order_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _db = FirebaseFirestore.instance;
  final _collection = 'orders';

  /// Create a new order (product or shipping)
  Future<void> createOrder(OrderModel order) async {
    await _db.collection(_collection).doc(order.orderId).set(order.toMap());
  }

  /// Stream all orders (admin view)
  Stream<List<OrderModel>> getAllOrders() {
    return _db.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromDoc(doc)).toList();
    });
  }

  /// Stream orders for a specific user
  Stream<List<OrderModel>> getOrdersByUser(String userId) {
    return _db
        .collection(_collection)
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => OrderModel.fromDoc(doc)).toList();
        });
  }

  /// Get a single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db.collection(_collection).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromDoc(doc);
  }

  /// Update order status
  Future<void> updateStatus(String orderId, String status) async {
    await _db.collection(_collection).doc(orderId).update({'status': status});
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    await _db.collection(_collection).doc(orderId).delete();
  }
}
