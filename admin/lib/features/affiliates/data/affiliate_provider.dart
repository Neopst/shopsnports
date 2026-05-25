// lib/features/affiliates/data/affiliate_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/affiliates/data/affiliate_repository_firestore.dart';
import 'package:admin_dashboard/features/affiliates/domain/affiliate_model.dart';

final affiliateRepositoryProvider = Provider<AffiliateRepositoryFirestore>((
  ref,
) {
  return AffiliateRepositoryFirestore();
});

final affiliatesProvider = StreamProvider<List<Affiliate>>((ref) {
  final repo = ref.watch(affiliateRepositoryProvider);
  return repo.getAffiliatesStream();
});

// Get single affiliate by ID
final affiliateByIdProvider = StreamProvider.family<Affiliate?, String>((
  ref,
  affiliateId,
) {
  final repo = ref.watch(affiliateRepositoryProvider);
  return repo.getAffiliateById(affiliateId).asStream();
});

// Get affiliate shipments
final affiliateShipmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      affiliateId,
    ) async {
      final repo = ref.watch(affiliateRepositoryProvider);
      return repo.getAffiliateShipments(affiliateId);
    });

// Calculate affiliate earnings
final affiliateEarningsProvider = FutureProvider.family<double, String>((
  ref,
  affiliateId,
) async {
  final repo = ref.watch(affiliateRepositoryProvider);
  return repo.calculateAffiliateEarnings(affiliateId);
});

// Get affiliate payouts
final affiliatePayoutsProvider =
    StreamProvider.family<List<PayoutRecord>, String>((ref, affiliateId) {
      final repo = ref.watch(affiliateRepositoryProvider);
      return Stream.fromFuture(repo.getPayoutsByAffiliate(affiliateId));
    });
