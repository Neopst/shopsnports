import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../providers/invoice_providers.dart';
import '../widgets/invoice_stats_cards.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  InvoiceStatus? _statusFilter;
  String _sortBy = 'date_desc';
  final List<String> _selectedIds = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const InvoiceStatsCards(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) => _buildInvoicesList(invoices, formatter),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.receipt_long, size: 32),
            SizedBox(width: 12),
            Text(
              'Invoices',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/dashboard/invoices/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create Invoice'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by invoice # or customer...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<InvoiceStatus?>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...InvoiceStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort by',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'date_desc',
                    child: Text('Date (Newest)'),
                  ),
                  DropdownMenuItem(
                    value: 'date_asc',
                    child: Text('Date (Oldest)'),
                  ),
                  DropdownMenuItem(
                    value: 'amount_desc',
                    child: Text('Amount (High-Low)'),
                  ),
                  DropdownMenuItem(
                    value: 'amount_asc',
                    child: Text('Amount (Low-High)'),
                  ),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ),
            if (_selectedIds.isNotEmpty) ...[
              const SizedBox(width: 16),
              Text('${_selectedIds.length} selected'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _bulkSend(),
                tooltip: 'Send selected',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _bulkDelete(),
                tooltip: 'Delete selected',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList(
    List<Invoice> allInvoices,
    CurrencyFormatter formatter,
  ) {
    // Apply filters
    var filtered = allInvoices.where((inv) {
      final matchesSearch =
          _searchController.text.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          inv.customerName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      final matchesStatus =
          _statusFilter == null || inv.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.total.compareTo(b.total));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
    }

    if (filtered.isEmpty) {
      return const Center(child: Text('No invoices found'));
    }

    return Card(
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildInvoiceRow(filtered[index], formatter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final allSelected = _selectedIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  final invoicesAsync = ref.read(invoicesProvider);
                  invoicesAsync.whenData((invoices) {
                    _selectedIds.clear();
                    _selectedIds.addAll(invoices.map((i) => i.id));
                  });
                } else {
                  _selectedIds.clear();
                }
              });
            },
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Invoice #',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Customer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Due Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            width: 120,
            child: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice, CurrencyFormatter formatter) {
    final isSelected = _selectedIds.contains(invoice.id);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: () => context.push('/dashboard/invoices/${invoice.id}'),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: isSelected ? Colors.blue[50] : null,
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(invoice.id);
                  } else {
                    _selectedIds.remove(invoice.id);
                  }
                });
              },
            ),
            Expanded(
              flex: 2,
              child: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(
                      invoice.customerAvatar ?? 'assets/icons/face1.png',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          invoice.customerEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(dateFormat.format(invoice.invoiceDate)),
            ),
            Expanded(flex: 2, child: Text(dateFormat.format(invoice.dueDate))),
            Expanded(
              flex: 2,
              child: Text(
                formatter.format(invoice.total, decimalDigits: 2),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(flex: 2, child: _buildStatusBadge(invoice.status)),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () =>
                        context.push('/dashboard/invoices/${invoice.id}'),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () =>
                        context.push('/dashboard/invoices/${invoice.id}/edit'),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: () => _sendInvoice(invoice),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoices'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} invoice(s)?',
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

    if (confirmed == true) {
      final repository = ref.read(invoiceRepositoryProvider);
      await repository.bulkDelete(_selectedIds);
      setState(() => _selectedIds.clear());
      ref.invalidate(invoicesProvider);
    }
  }

  Future<void> _bulkSend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invoices'),
        content: Text(
          'Are you sure you want to send ${_selectedIds.length} invoice(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement actual bulk email sending functionality
        // This will be implemented in the Invoice Email Sending task
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} invoice(s) sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedIds.clear());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending invoices: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send invoice ${invoice.invoiceNumber} to:'),
            const SizedBox(height: 8),
            Text(
              invoice.customerEmail,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('The invoice will be sent as a PDF attachment.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement actual email sending functionality
        // This will be implemented in the Invoice Email Sending task
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${invoice.invoiceNumber} sent to ${invoice.customerEmail}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending invoice: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
