import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../../../settings/presentation/providers/company_details_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final Invoice invoice;
  final VoidCallback? onSend;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onCancel;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    this.onSend,
    this.onSaveDraft,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyDetailsAsync = ref.watch(companyDetailsProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final currencyFormatter = CurrencyFormatter(
      currencyService,
      selectedCurrency,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancel ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    elevation: 4,
                    child: companyDetailsAsync.when(
                      data: (companyDetails) {
                        return Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Logo and Company Details
                              _buildHeader(companyDetails, currencyFormatter),
                              const Divider(height: 48, thickness: 2),
                              // Invoice Details and Customer Info
                              _buildInvoiceInfo(),
                              const SizedBox(height: 32),
                              // Line Items Table
                              _buildLineItemsTable(currencyFormatter),
                              const SizedBox(height: 32),
                              // Totals
                              _buildTotals(currencyFormatter),
                              if (invoice.notes != null &&
                                  invoice.notes!.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                _buildNotes(),
                              ],
                              const SizedBox(height: 48),
                              // Footer with Company Banking Details
                              _buildFooter(companyDetails),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Text('Error loading company details: $error'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic companyDetails, CurrencyFormatter formatter) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        if (companyDetails.logoUrl.isNotEmpty)
          Image.asset(
            companyDetails.logoUrl,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stack) {
              return Image.asset(
                'assets/icons/logo.png',
                width: 120,
                height: 120,
              );
            },
          )
        else
          Image.asset('assets/icons/logo.png', width: 120, height: 120),
        const SizedBox(width: 32),
        // Company Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyDetails.companyName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (companyDetails.companyAddress.isNotEmpty)
                Text(
                  companyDetails.companyAddress,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              if (companyDetails.city.isNotEmpty ||
                  companyDetails.state.isNotEmpty)
                Text(
                  '${companyDetails.city}${companyDetails.city.isNotEmpty && companyDetails.state.isNotEmpty ? ', ' : ''}${companyDetails.state} ${companyDetails.zipCode}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              if (companyDetails.country.isNotEmpty)
                Text(
                  companyDetails.country,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              const SizedBox(height: 8),
              if (companyDetails.phoneNumber.isNotEmpty)
                Text(
                  'Phone: ${companyDetails.phoneNumber}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              if (companyDetails.email.isNotEmpty)
                Text(
                  'Email: ${companyDetails.email}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              if (companyDetails.website.isNotEmpty)
                Text(
                  'Web: ${companyDetails.website}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              if (companyDetails.taxId.isNotEmpty)
                Text(
                  'Tax ID: ${companyDetails.taxId}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
            ],
          ),
        ),
        // Invoice Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text(
                'INVOICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getStatusText(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bill To
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                invoice.customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                invoice.customerEmail,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        // Invoice Details
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildInfoRow('Invoice Number:', invoice.invoiceNumber),
            const SizedBox(height: 4),
            _buildInfoRow(
              'Invoice Date:',
              dateFormat.format(invoice.invoiceDate),
            ),
            const SizedBox(height: 4),
            _buildInfoRow('Due Date:', dateFormat.format(invoice.dueDate)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLineItemsTable(CurrencyFormatter formatter) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey[300]!),
        top: BorderSide(color: Colors.grey[400]!, width: 2),
        bottom: BorderSide(color: Colors.grey[400]!, width: 2),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            _buildTableCell('DESCRIPTION', isHeader: true),
            _buildTableCell('QTY', isHeader: true, align: TextAlign.center),
            _buildTableCell(
              'UNIT PRICE',
              isHeader: true,
              align: TextAlign.right,
            ),
            _buildTableCell('TOTAL', isHeader: true, align: TextAlign.right),
          ],
        ),
        // Items
        ...invoice.lineItems.map((item) {
          return TableRow(
            children: [
              _buildTableCell(item.description),
              _buildTableCell(
                item.quantity.toString(),
                align: TextAlign.center,
              ),
              _buildTableCell(
                formatter.format(item.unitPrice),
                align: TextAlign.right,
              ),
              _buildTableCell(
                formatter.format(item.quantity * item.unitPrice),
                align: TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 14,
          color: isHeader ? Colors.grey[700] : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTotals(CurrencyFormatter formatter) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  _buildTotalRow(
                    'Subtotal:',
                    formatter.format(invoice.subtotal),
                  ),
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'Tax (${invoice.taxRate}%):',
                    formatter.format(invoice.taxAmount),
                  ),
                  const Divider(thickness: 2),
                  _buildTotalRow(
                    'TOTAL:',
                    formatter.format(invoice.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(invoice.notes!, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildFooter(dynamic companyDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (companyDetails.bankName.isNotEmpty)
            Text(
              'Bank: ${companyDetails.bankName}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          if (companyDetails.accountName.isNotEmpty)
            Text(
              'Account Name: ${companyDetails.accountName}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          if (companyDetails.accountNumber.isNotEmpty)
            Text(
              'Account Number: ${companyDetails.accountNumber}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          const SizedBox(height: 12),
          const Text(
            'Payment Methods: Stripe, Paystack, Flutterwave',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your business!',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onCancel != null)
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          if (onCancel != null) const SizedBox(width: 16),
          if (onSaveDraft != null)
            OutlinedButton.icon(
              onPressed: onSaveDraft,
              icon: const Icon(Icons.save),
              label: const Text('Save as Draft'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          if (onSaveDraft != null) const SizedBox(width: 16),
          if (onSend != null)
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              label: Text(
                invoice.status == InvoiceStatus.draft
                    ? 'Send Invoice'
                    : 'Update & Send',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
      case InvoiceStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
