import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/affiliate_repository_firestore.dart';
import '../../domain/affiliate_model.dart';

final affiliateRepositoryProvider = Provider<AffiliateRepositoryFirestore>((
  ref,
) {
  return AffiliateRepositoryFirestore();
});

final affiliatesProvider = StreamProvider<List<Affiliate>>((ref) {
  final repository = ref.watch(affiliateRepositoryProvider);
  return repository.getAffiliatesStream();
});

final payoutsProvider = StreamProvider<List<PayoutRecord>>((ref) {
  final repository = ref.watch(affiliateRepositoryProvider);
  return repository.getPayoutsStream();
});

final affiliateStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(affiliateRepositoryProvider);
  return repository.getAffiliateStats();
});
