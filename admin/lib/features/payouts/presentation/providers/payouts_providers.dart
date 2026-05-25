import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payout_models.dart';
import '../../data/repositories/payout_repository_firestore.dart';

// Firestore repository provider
final payoutRepositoryProvider = Provider((ref) {
  return PayoutRepositoryFirestore();
});

// Helper class for filtering
class PayoutsFilter {
  final String? status;
  final String? recipientType;
  final int page;
  final int limit;

  PayoutsFilter({
    this.status,
    this.recipientType,
    this.page = 1,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayoutsFilter &&
        other.status == status &&
        other.recipientType == recipientType &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(status, recipientType, page, limit);
  }
}

/// Payouts stream provider with filters
final payoutsListProvider = StreamProvider.family<List<Payout>, PayoutsFilter>((
  ref,
  filter,
) {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutsStream(
    status: filter.status,
    recipientType: filter.recipientType,
  );
});

/// Pending payouts provider
final pendingPayoutsProvider = StreamProvider<List<Payout>>((ref) {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutsStream(status: 'pending');
});

/// Approved payouts provider
final approvedPayoutsProvider = StreamProvider<List<Payout>>((ref) {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutsStream(status: 'approved');
});

/// Completed payouts provider
final completedPayoutsProvider = StreamProvider<List<Payout>>((ref) {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutsStream(status: 'completed');
});

/// Payouts by specific affiliate ID provider
final payoutsListByAffiliateProvider =
    StreamProvider.family<List<Payout>, String>((ref, affiliateId) {
      final repo = ref.watch(payoutRepositoryProvider);
      return repo.getPayoutsStream(recipientId: affiliateId);
    });

/// Payout stats provider
final payoutStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutStats();
});

/// Single payout provider
final payoutByIdProvider = FutureProvider.family<Payout?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getPayoutById(id);
});

/// Approve payout provider
final approvePayoutProvider =
    FutureProvider.family<void, ({String payoutId, String approvedBy})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(payoutRepositoryProvider);
      await repo.approvePayout(params.payoutId, params.approvedBy);
      ref.invalidate(payoutsListProvider);
      ref.invalidate(pendingPayoutsProvider);
      ref.invalidate(payoutStatsProvider);
    });

/// Process payout provider
final processPayoutProvider =
    FutureProvider.family<
      void,
      ({String payoutId, String processedBy, String paymentReference})
    >((ref, params) async {
      final repo = ref.watch(payoutRepositoryProvider);
      await repo.processPayout(
        params.payoutId,
        params.processedBy,
        params.paymentReference,
      );
      ref.invalidate(payoutsListProvider);
      ref.invalidate(approvedPayoutsProvider);
      ref.invalidate(payoutStatsProvider);
    });

/// Cancel payout provider
final cancelPayoutProvider =
    FutureProvider.family<void, ({String payoutId, String reason})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(payoutRepositoryProvider);
      await repo.cancelPayout(params.payoutId, params.reason);
      ref.invalidate(payoutsListProvider);
      ref.invalidate(pendingPayoutsProvider);
      ref.invalidate(payoutStatsProvider);
    });

// ========== COMMISSION SETTINGS ==========

/// Commission settings stream provider
final commissionSettingsStreamProvider =
    StreamProvider<List<CommissionSetting>>((ref) {
      final repo = ref.watch(payoutRepositoryProvider);
      return repo.getCommissionSettingsStream();
    });

/// Commission settings provider
final commissionSettingsProvider = FutureProvider<List<CommissionSetting>>((
  ref,
) async {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getCommissionSettings();
});

// ========== TAX SETTINGS ==========

/// Tax settings stream provider
final taxSettingsStreamProvider = StreamProvider<List<TaxSetting>>((ref) {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getTaxSettingsStream();
});

/// Tax settings provider
final taxSettingsProvider = FutureProvider<List<TaxSetting>>((ref) async {
  final repo = ref.watch(payoutRepositoryProvider);
  return repo.getTaxSettings();
});

// ========== DATA SEEDING ==========

/// Seed sample data provider - call this once to populate Firestore
final seedPayoutDataProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(payoutRepositoryProvider);
  await repo.seedSampleData();
});
