import '../models/invoice.dart';

/// Abstract repository for invoice operations
abstract class InvoiceRepository {
  /// Get all invoices
  Future<List<Invoice>> getAllInvoices();

  /// Get invoice by ID
  Future<Invoice?> getInvoiceById(String id);

  /// Create new invoice
  Future<Invoice> createInvoice(Invoice invoice);

  /// Update existing invoice
  Future<Invoice> updateInvoice(Invoice invoice);

  /// Delete invoice
  Future<void> deleteInvoice(String id);

  /// Get invoices by status
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status);

  /// Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(String customerId);

  /// Mark invoice as paid
  Future<Invoice> markAsPaid(String id);

  /// Record payment with details
  Future<Invoice> recordPayment(
    String id, {
    required String paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
    required double amountPaid,
    String? paymentNotes,
  });

  /// Mark invoice as cancelled
  Future<Invoice> markAsCancelled(String id);

  /// Get invoice statistics
  Future<Map<String, dynamic>> getStats();

  /// Bulk delete invoices
  Future<void> bulkDelete(List<String> ids);
}
