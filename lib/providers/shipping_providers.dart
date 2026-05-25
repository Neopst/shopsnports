import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/models/shipping_request_simplified.dart';
import 'package:shopsnports/repositories/shipping_request_repository.dart';

/// Provider for ShippingRequestRepository
final shippingRequestRepositoryProvider = Provider((ref) {
  return ShippingRequestRepository(
    firestore: FirebaseFirestore.instance,
  );
});

/// Provider to look up shipping request by tracking number
/// Usage: ref.watch(trackingLookupProvider(trackingNumber))
final trackingLookupProvider =
    FutureProvider.family<ShippingRequestSimplified?, String>(
        (ref, trackingNumber) async {
  final repo = ref.watch(shippingRequestRepositoryProvider);
  if (trackingNumber.isEmpty) return null;
  return repo.getByTrackingNumber(trackingNumber);
});

/// Provider for user's shipping requests (one-time fetch)
final userShippingRequestsProvider =
    FutureProvider.family<List<ShippingRequestSimplified>, String>(
        (ref, userId) async {
  final repo = ref.watch(shippingRequestRepositoryProvider);
  return repo.getUserRequests(userId);
});

/// Provider for streaming user's shipping requests (real-time)
final watchUserShippingRequestsProvider =
    StreamProvider.family<List<ShippingRequestSimplified>, String>(
        (ref, userId) {
  final repo = ref.watch(shippingRequestRepositoryProvider);
  return repo.watchUserRequests(userId);
});

/// Provider for streaming single request by ID
final watchShippingRequestProvider =
    StreamProvider.family<ShippingRequestSimplified?, String>((ref, requestId) {
  final repo = ref.watch(shippingRequestRepositoryProvider);
  return repo.watchRequest(requestId);
});

/// Provider for affiliate's referral requests
final affiliateShippingRequestsProvider =
    FutureProvider.family<List<ShippingRequestSimplified>, String>(
        (ref, affiliateId) async {
  final repo = ref.watch(shippingRequestRepositoryProvider);
  return repo.getAffiliateRequests(affiliateId);
});
