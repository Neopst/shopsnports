// FILE: lib/features/shipping/presentation/providers/shipping_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/shipping_repository_firestore.dart';
import '../../domain/shipping_request_model.dart';

// Firestore Repository Provider
final shippingRepositoryProvider = Provider<ShippingRepositoryFirestore>((ref) {
  return ShippingRepositoryFirestore();
});

// Single shipping request provider using Firestore
final shippingRequestProvider = StreamProvider.family<ShippingRequest?, String>(
  (ref, requestId) {
    return FirebaseFirestore.instance
        .collection('shippingRequests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return ShippingRequest.fromFirestore(snapshot);
        });
  },
);
