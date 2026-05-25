import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shipping_request.dart';
import '../models/enums.dart';
import '../services/affiliate_api_service.dart';

/// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Auth Stream Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Affiliate Service Provider (Firestore-based)
final affiliateServiceProvider = Provider<AffiliateService>((ref) {
  return AffiliateService();
});

/// Shipment repository for affiliate dashboard features
final affiliateShipmentRepositoryProvider = Provider<AffiliateService>((ref) {
  return ref.watch(affiliateServiceProvider);
});

/// Shipment list filtered by status
final affiliateShipmentsByStatusProvider =
    FutureProvider.family<List<ShippingRequest>, ShippingStatus?>(
        (ref, status) async {
  final service = ref.watch(affiliateServiceProvider);
  final shipments = await service.getShipments();
  if (status == null) return shipments;
  return shipments.where((s) => s.status == status).toList();
});

/// Basic stats for shipments in affiliate dashboard (computed quickly)
final affiliateShipmentStatsProvider = Provider<Map<String, int>>((ref) {
  // We can compute from the latest list if needed, or provide defaults.
  // For now use quick defaults for UI when the data is not yet loaded.
  final shipmentsValue = ref.watch(affiliateShipmentsByStatusProvider(null));

  return shipmentsValue.maybeWhen(
    data: (shipments) {
      final total = shipments.length;
      final pending =
          shipments.where((s) => s.status == ShippingStatus.pending).length;
      final inTransit =
          shipments.where((s) => s.status == ShippingStatus.inTransit).length;
      final delivered =
          shipments.where((s) => s.status == ShippingStatus.delivered).length;
      return {
        'total': total,
        'pending': pending,
        'inTransit': inTransit,
        'delivered': delivered,
      };
    },
    orElse: () => {
      'total': 0,
      'pending': 0,
      'inTransit': 0,
      'delivered': 0,
    },
  );
});
