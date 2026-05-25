// lib/features/shipping/data/shipping_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/shipping/data/shipping_repository.dart';

final shippingRepositoryProvider = Provider<ShippingRepository>((ref) {
  return ShippingRepository();
});

final shippingProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(shippingRepositoryProvider);
  return repo.fetchShippingProfiles();
});
