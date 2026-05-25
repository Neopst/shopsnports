import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/invoices_service.dart' show Invoice, InvoicesService;

/// Invoice Detail Screen
/// Shows detailed information about a specific invoice
class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final InvoicesService _invoicesService = InvoicesService();
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final invoice = await _invoicesService.getInvoiceById(widget.invoiceId);
      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          if (_invoice != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareInvoice,
              tooltip: 'Share Invoice',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoice,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_invoice == null) {
      return const Center(child: Text('Invoice not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSection('Bill To', _buildBillTo()),
          const SizedBox(height: 24),
          _buildSection('Notes', _buildNotes()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final invoice = _invoice!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice ${invoice.invoiceNumber}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                _buildStatusChip(invoice.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(invoice.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (invoice.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due: ${_formatDate(invoice.dueDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:'),
                Text(
                  currencyFormat.format(invoice.amount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBillTo() {
    final invoice = _invoice!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.customerName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(invoice.customerEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    final invoice = _invoice!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(invoice.notes ?? 'No notes'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _shareInvoice() async {
    if (_invoice == null) return;

    try {
      final invoice = _invoice!;
      final buffer = StringBuffer();
      final currencyFormat = NumberFormat.currency(symbol: '\$');

      buffer.writeln('INVOICE');
      buffer.writeln('=======');
      buffer.writeln('Invoice #: ${invoice.invoiceNumber}');
      buffer.writeln('Date: ${_formatDate(invoice.createdAt)}');
      buffer.writeln('Status: ${invoice.status}');
      buffer.writeln('');

      buffer.writeln('Bill To:');
      buffer.writeln('  ${invoice.customerName}');
      buffer.writeln('  ${invoice.customerEmail}');
      buffer.writeln('');

      buffer.writeln('Total: ${currencyFormat.format(invoice.amount)}');

      if (invoice.notes != null && invoice.notes!.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Notes:');
        buffer.writeln(invoice.notes);
      }

      await Share.share(buffer.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    }
  }
}