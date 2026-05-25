import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/shipping_repository_firestore.dart';

class ShippingRepository {
  final ShippingRepositoryFirestore _firestore = ShippingRepositoryFirestore();

  Future<List<dynamic>> fetchShippingProfiles() async {
    final result = await _firestore.getShippingRequests(limit: 100);
    final requests = result['shipping_requests'] as List<dynamic>? ?? [];
    return requests;
  }
}