import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/shipping_request_model.dart';

class ShippingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ShippingRequest>> getShippingRequests() {
    return _firestore
        .collection('shippingRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShippingRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ShippingRequest>> getShippingRequestsByStatus(
    ShippingStatus status,
  ) {
    return _firestore
        .collection('shippingRequests')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShippingRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateShippingStatus({
    required String requestId,
    required ShippingStatus newStatus,
    String? trackingNumber,
  }) async {
    await _firestore
        .collection('shippingRequests')
        .doc(requestId)
        .update({
      'status': newStatus.name,
      'trackingNumber': trackingNumber,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<Map<String, dynamic>> getShippingStats() async {
    final snapshot =
        await _firestore.collection('shippingRequests').get();
    final requests = snapshot.docs
        .map((doc) => ShippingRequest.fromFirestore(doc))
        .toList();

    return {
      'total': requests.length,
      'pending': requests
          .where((r) => r.status == ShippingStatus.pending)
          .length,
      'inTransit': requests
          .where((r) => r.status == ShippingStatus.inTransit)
          .length,
      'delivered': requests
          .where((r) => r.status == ShippingStatus.delivered)
          .length,
      'airCount': requests.where((r) => r.type == ShippingType.air).length,
      'seaCount': requests.where((r) => r.type == ShippingType.sea).length,
      'totalRevenue': requests.fold(0.0, (total, r) => total + r.estimatedCost),
    };
  }
}
