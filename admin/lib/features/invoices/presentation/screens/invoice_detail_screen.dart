import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../../services/invoice_pdf_service.dart';
import '../providers/invoice_providers.dart';
import '../widgets/payment_dialog.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/email_service.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceByIdProvider(invoiceId));
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/dashboard/invoices/$invoiceId/edit'),
            tooltip: 'Edit Invoice',
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }
          return _buildInvoiceDetails(context, ref, invoice, formatter);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInvoiceDetails(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
    CurrencyFormatter formatter,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with invoice number and status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${dateFormat.format(invoice.createdAt)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  _buildStatusBadge(invoice.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill To',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(
                          invoice.customerAvatar ?? 'assets/icons/face1.png',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.customerEmail,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Date',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(invoice.invoiceDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(invoice.dueDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Qty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Price',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...invoice.lineItems.map((item) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  if (item.imageUrl != null) ...[
                                    Image.asset(
                                      item.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(child: Text(item.description)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${item.quantity}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                formatter.format(
                                  item.unitPrice,
                                  decimalDigits: 2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                formatter.format(item.total, decimalDigits: 2),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  const Divider(height: 32),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            _buildTotalRow(
                              'Subtotal',
                              formatter.format(
                                invoice.subtotal,
                                decimalDigits: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTotalRow(
                              'Tax (${invoice.taxRate}%)',
                              formatter.format(
                                invoice.taxAmount,
                                decimalDigits: 2,
                              ),
                            ),
                            const Divider(height: 24),
                            _buildTotalRow(
                              'Total',
                              formatter.format(invoice.total, decimalDigits: 2),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes (if any)
          if (invoice.notes != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(invoice.notes!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Email tracking (if email sent)
          if (invoice.emailSent)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invoice Email Sent',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (invoice.lastEmailSentAt != null)
                            Text(
                              'Last sent: ${DateFormat('MMM dd, yyyy HH:mm').format(invoice.lastEmailSentAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          Text(
                            'Sent ${invoice.emailSentCount} time(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (invoice.emailSent) const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              // Copy Invoice Link
              ElevatedButton.icon(
                onPressed: () => _copyInvoiceLink(context, invoice.accessToken),
                icon: const Icon(Icons.link),
                label: const Text('Copy Link'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Send/Resend Email
              ElevatedButton.icon(
                onPressed: () => _sendInvoiceEmail(context, ref, invoice),
                icon: const Icon(Icons.email),
                label: Text(invoice.emailSent ? 'Resend Email' : 'Send Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (invoice.status == InvoiceStatus.pending) ...[
                ElevatedButton.icon(
                  onPressed: () => _markAsPaid(context, ref, invoice.id),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final pdfService = InvoicePdfService();
                    await pdfService.generateAndPrintInvoice(invoice);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _deleteInvoice(context, ref, invoice.id),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = Colors.green;
        break;
      case InvoiceStatus.pending:
        color = Colors.orange;
        break;
      case InvoiceStatus.overdue:
        color = Colors.red;
        break;
      case InvoiceStatus.cancelled:
        color = Colors.grey;
        break;
      case InvoiceStatus.draft:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _markAsPaid(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final invoice = await ref.read(invoiceByIdProvider(id).future);

    if (invoice == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice not found')),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaymentDialog(invoice: invoice),
      );
    }
  }

  Future<void> _deleteInvoice(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(invoiceRepositoryProvider);
      await repository.deleteInvoice(id);
      ref.invalidate(invoicesProvider);

      if (context.mounted) {
        context.go('/dashboard/invoices');
      }
    }
  }

  /// Copy invoice public view link to clipboard
  void _copyInvoiceLink(BuildContext context, String accessToken) {
    final invoiceUrl = 'https://admin.shopsnports.com/invoice/$accessToken';
    Clipboard.setData(ClipboardData(text: invoiceUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Send or resend invoice email
  Future<void> _sendInvoiceEmail(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          invoice.emailSent ? 'Resend Invoice Email' : 'Send Invoice Email',
        ),
        content: Text(
          invoice.emailSent
              ? 'Send invoice email again to ${invoice.customerEmail}?'
              : 'Send invoice email to ${invoice.customerEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final emailService = EmailService();
        await emailService.sendInvoiceEmail(
          invoiceId: invoice.id,
          customerEmail: invoice.customerEmail,
          customerName: invoice.customerName,
          invoiceNumber: invoice.invoiceNumber,
          accessToken: invoice.accessToken,
          amount: invoice.total,
          dueDate: invoice.dueDate,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice email sent to ${invoice.customerEmail}'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(invoiceByIdProvider(invoice.id));
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send email: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
