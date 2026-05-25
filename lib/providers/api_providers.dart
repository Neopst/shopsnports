import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipping_request.dart';
import '../models/enums.dart';
import '../services/affiliate_api_service.dart';

/// Provider for AffiliateService (Firestore-based)
final affiliateServiceProvider = Provider<AffiliateService>((ref) {
  return AffiliateService();
});

/// Provider for affiliate shipments stream using real Firestore data
final affiliateShipmentsProvider = StreamProvider<List<ShippingRequest>>((ref) {
  final service = ref.watch(affiliateServiceProvider);
  return service.watchShipments();
});

/// Provider for filtered shipments by status
final affiliateShipmentsByStatusProvider =
    StreamProvider.family<List<ShippingRequest>, ShippingStatus?>(
        (ref, status) {
  final service = ref.watch(affiliateServiceProvider);
  return service.watchShipments(status: status);
});

/// Provider for shipment statistics
final affiliateShipmentStatsProvider = Provider<Map<String, int>>((ref) {
  final shipmentsAsync = ref.watch(affiliateShipmentsProvider);
  return shipmentsAsync.when(
    data: (shipments) {
      return {
        'total': shipments.length,
        'pending':
            shipments.where((s) => s.status == ShippingStatus.pending).length,
        'inTransit':
            shipments.where((s) => s.status == ShippingStatus.inTransit).length,
        'delivered':
            shipments.where((s) => s.status == ShippingStatus.delivered).length,
      };
    },
    loading: () => {
      'total': 0,
      'pending': 0,
      'inTransit': 0,
      'delivered': 0,
    },
    error: (_, __) => {
      'total': 0,
      'pending': 0,
      'inTransit': 0,
      'delivered': 0,
    },
  );
});