import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/invoice_repository_firestore.dart';
// import '../../data/repositories/invoice_repository_mock.dart';

/// Provider for invoice repository (using Firestore)
final invoiceRepositoryProvider = Provider<InvoiceRepositoryFirestore>((ref) {
  return InvoiceRepositoryFirestore();
});

/// Provider for all invoices (real-time stream)
final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getAllInvoicesStream();
});

/// Provider for invoice statistics
final invoiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getStats();
});

/// Provider for a single invoice by ID
final invoiceByIdProvider = FutureProvider.family<Invoice?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoiceById(id);
});

/// Provider for invoices filtered by status
final invoicesByStatusProvider =
    FutureProvider.family<List<Invoice>, InvoiceStatus>((ref, status) async {
      final repository = ref.watch(invoiceRepositoryProvider);
      return repository.getInvoicesByStatus(status);
    });
