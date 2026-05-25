import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/order_model.dart';

class OrderRepositoryFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _ordersCollection = 'orders';

  Future<List<OrderModel>> fetchOrders() async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap({...doc.data()!, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<OrderModel?> fetchOrderById(String id) async {
    try {
      final doc = await _firestore.collection(_ordersCollection).doc(id).get();
      if (!doc.exists) return null;
      return OrderModel.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _firestore.collection(_ordersCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection(_ordersCollection).doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Stream<List<OrderModel>> streamOrders() {
    return _firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap({...doc.data()!, 'id': doc.id}))
              .toList(),
        );
  }
}