// lib/features/orders/data/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/orders/data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final ordersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchOrders();
});
