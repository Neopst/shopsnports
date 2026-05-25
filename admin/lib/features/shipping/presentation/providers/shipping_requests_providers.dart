import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/shipping_repository_firestore.dart';
// OLD API imports commented out - now using Firestore
// import 'package:dio/dio.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../data/api/shipping_requests_api_client.dart';

// Firestore Repository Provider (replaces API client)
final shippingRepositoryProvider = Provider<ShippingRepositoryFirestore>((ref) {
  return ShippingRepositoryFirestore();
});

// Filter configuration
class ShippingRequestsFilter {
  final int page;
  final int limit;
  final String? status;
  final String? shippingType;

  ShippingRequestsFilter({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.shippingType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingRequestsFilter &&
          page == other.page &&
          limit == other.limit &&
          status == other.status &&
          shippingType == other.shippingType;

  @override
  int get hashCode =>
      page.hashCode ^
      limit.hashCode ^
      (status?.hashCode ?? 0) ^
      (shippingType?.hashCode ?? 0);
}

// Shipping requests list provider with filters (now using Firestore)
final shippingRequestsListProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ShippingRequestsFilter>((ref, filter) async {
      final repository = ref.watch(shippingRepositoryProvider);
      return await repository.getShippingRequests(
        page: filter.page,
        limit: filter.limit,
        status: filter.status,
        shippingType: filter.shippingType,
      );
    });

// Single shipping request provider (now using Firestore)
final shippingRequestByIdProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      final repository = ref.watch(shippingRepositoryProvider);
      return repository.getShippingRequestById(id);
    });

// Shipping statistics provider (now using Firestore)
final shippingStatsProviderNew =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repository = ref.watch(shippingRepositoryProvider);
      return await repository.getStats();
    });

// Assign carrier provider (simplified - carrier assignment removed for now)
class AssignCarrierData {
  final String requestId;
  final String carrierName;
  final String estimatedCost;

  AssignCarrierData({
    required this.requestId,
    required this.carrierName,
    required this.estimatedCost,
  });
}

// Note: Carrier assignment functionality simplified for Firestore
// Just updates the shipping request with carrier details
final assignCarrierProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, AssignCarrierData>((ref, data) async {
      final repository = ref.watch(shippingRepositoryProvider);

      // Update the request with carrier info
      await repository.updateShippingRequest(data.requestId, {
        'carrier_name': data.carrierName,
        'estimated_cost': data.estimatedCost,
        'status': 'carrier_assigned',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Invalidate list to refresh
      ref.invalidate(shippingRequestsListProvider);
      ref.invalidate(shippingStatsProviderNew);

      return {'success': true};
    });

// Sample data removed - now using Firestore data seeded in ShippingRepositoryFirestore
