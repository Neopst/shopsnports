import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/invoices_service.dart';
import '../../widgets/main_scaffold.dart';
import 'invoice_detail_screen.dart';

/// User's Invoices List Screen
/// Shows all invoices sent to the current user
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoicesService _invoicesService = InvoicesService();
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invoices = await _invoicesService.getUserInvoices(
        status: _filterStatus,
      );
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3, // Profile section
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('My Invoices'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(
                            value: 'overdue', child: Text('Overdue')),
                        DropdownMenuItem(
                            value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterStatus = value);
                        _loadInvoices();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadInvoices,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadInvoices,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_invoices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Invoices Found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filterStatus == null
                          ? 'You don\'t have any invoices yet'
                          : 'No $_filterStatus invoices found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final invoice = _invoices[index];
                  final invoiceNumber = invoice.invoiceNumber.isNotEmpty
                      ? invoice.invoiceNumber
                      : 'N/A';
                  final orderNumber = invoice.shippingRequestId ?? 'N/A';
                  final totalAmount = invoice.amount;
                  final status = invoice.status;
                  final invoiceDate = invoice.createdAt;
                  final dueDate = invoice.dueDate;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getStatusColor(status).withValues(alpha: 0.2),
                        child: Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                        ),
                      ),
                      title: Text(
                        'Invoice #$invoiceNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order: $orderNumber'),
                          Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(invoiceDate)}',
                          ),
                          if (dueDate != null)
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                              style: TextStyle(
                                color: DateTime.now().isAfter(dueDate)
                                    ? Colors.red
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceDetailScreen(
                              invoiceId: invoice.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _invoices.length,
              ),
            ),
        ],
      ),
    );
  }
}
