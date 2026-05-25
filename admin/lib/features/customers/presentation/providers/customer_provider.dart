import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository_firestore.dart';

final customerRepositoryProvider = Provider<CustomerRepositoryFirestore>((ref) {
  return CustomerRepositoryFirestore();
});

/// Provider for all customers (real-time stream)
final customersProvider = StreamProvider<List<Customer>>((ref) {
  final repository = ref.read(customerRepositoryProvider);
  return repository.getCustomersStream();
});

/// Provider for customer statistics (real-time stream)
/// Firebase is the only source of truth - streams live updates
final customerStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final repository = ref.read(customerRepositoryProvider);
  // Listen to customer changes and recalculate stats
  await for (final _ in repository.getCustomersStream()) {
    yield await repository.getCustomerStats();
  }
});

/// Provider for a single customer by ID
final customerByIdProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final repository = ref.read(customerRepositoryProvider);
  return repository.getCustomerById(id);
});

/// Provider for customers filtered by status
final customersByStatusProvider = FutureProvider.family<List<Customer>, String>(
    (ref, status) async {
  final repository = ref.read(customerRepositoryProvider);
  return repository.getCustomersByStatus(status);
});

/// Provider for customer search
final customerSearchProvider = FutureProvider.family<List<Customer>, String>(
    (ref, query) async {
  final repository = ref.read(customerRepositoryProvider);
  return repository.searchCustomers(query);
});

/// Search query state
class CustomerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final customerSearchQueryProvider = NotifierProvider<CustomerSearchQueryNotifier, String>(
  CustomerSearchQueryNotifier.new,
);

/// Status filter state
class CustomerStatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final customerStatusFilterProvider = NotifierProvider<CustomerStatusFilterNotifier, String?>(
  CustomerStatusFilterNotifier.new,
);