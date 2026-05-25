import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/invoice_reconciliation.dart';
import '../../data/repositories/invoice_reconciliation_repository.dart';

final reconciliationRepositoryProvider =
    Provider<InvoiceReconciliationRepository>((ref) {
  return InvoiceReconciliationRepository();
});

final reconciliationsProvider =
    FutureProvider.family<List<InvoiceReconciliation>, ReconciliationStatus?>(
  (ref, status) async {
    final repository = ref.read(reconciliationRepositoryProvider);
    if (status == null) {
      return repository.getAll();
    }
    return repository.getByStatus(status);
  },
);

final reconciliationStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(reconciliationRepositoryProvider);
  return repository.getStatistics();
});

class InvoiceReconciliationScreen extends ConsumerStatefulWidget {
  const InvoiceReconciliationScreen({super.key});

  @override
  ConsumerState<InvoiceReconciliationScreen> createState() =>
      _InvoiceReconciliationScreenState();
}

class _InvoiceReconciliationScreenState
    extends ConsumerState<InvoiceReconciliationScreen> {
  ReconciliationStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final reconciliationsAsync =
        ref.watch(reconciliationsProvider(_selectedStatus));
    final statsAsync = ref.watch(reconciliationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Reconciliation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(reconciliationsProvider(_selectedStatus));
              ref.invalidate(reconciliationStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          _buildFilterChips(),
          Expanded(
            child: reconciliationsAsync.when(
              data: (reconciliations) {
                if (reconciliations.isEmpty) {
                  return const Center(
                    child: Text('No reconciliations found'),
                  );
                }
                return ListView.builder(
                  itemCount: reconciliations.length,
                  itemBuilder: (context, index) {
                    return _buildReconciliationCard(
                      reconciliations[index],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: statsAsync.when(
        data: (stats) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reconciliation Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('Total', stats['totalInvoices'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Paid',
                    '\$${stats['totalPaid'].toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Outstanding',
                    '\$${stats['totalOutstanding'].toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip('Pending', stats['pending'] ?? 0, Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatusChip('Partial', stats['partiallyPaid'] ?? 0, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatusChip('Paid', stats['fullyPaid'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusChip('Overdue', stats['overdue'] ?? 0, Colors.red),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.2),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = selected ? null : _selectedStatus;
              });
            },
          ),
          ...ReconciliationStatus.values.map((status) {
            return FilterChip(
              label: Text(_getStatusLabel(status)),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  String _getStatusLabel(ReconciliationStatus status) {
    switch (status) {
      case ReconciliationStatus.pending:
        return 'Pending';
      case ReconciliationStatus.partiallyPaid:
        return 'Partial';
      case ReconciliationStatus.fullyPaid:
        return 'Paid';
      case ReconciliationStatus.overdue:
        return 'Overdue';
      case ReconciliationStatus.disputed:
        return 'Disputed';
      case ReconciliationStatus.writtenOff:
        return 'Written Off';
    }
  }

  Color _getStatusColor(ReconciliationStatus status) {
    switch (status) {
      case ReconciliationStatus.pending:
        return Colors.orange;
      case ReconciliationStatus.partiallyPaid:
        return Colors.blue;
      case ReconciliationStatus.fullyPaid:
        return Colors.green;
      case ReconciliationStatus.overdue:
        return Colors.red;
      case ReconciliationStatus.disputed:
        return Colors.purple;
      case ReconciliationStatus.writtenOff:
        return Colors.grey;
    }
  }

  Widget _buildReconciliationCard(InvoiceReconciliation reconciliation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reconciliation.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Invoice: ${reconciliation.invoiceId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(reconciliation.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusLabel(reconciliation.status),
                style: TextStyle(
                  color: _getStatusColor(reconciliation.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: reconciliation.paymentPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                _getStatusColor(reconciliation.status),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: \$${reconciliation.paidAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${reconciliation.paymentPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Outstanding: \$${reconciliation.outstandingAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (reconciliation.payments.isEmpty)
                  const Text('No payments recorded yet')
                else
                  ...reconciliation.payments.map((payment) {
                    return _buildPaymentTile(payment);
                  }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Record Payment'),
                        onPressed: () => _showAddPaymentDialog(reconciliation),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reconciliation.status != ReconciliationStatus.fullyPaid)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Reconciled'),
                          onPressed: () => _showReconcileDialog(reconciliation),
                        ),
                      ),
                  ],
                ),
                if (reconciliation.status == ReconciliationStatus.pending ||
                    reconciliation.status == ReconciliationStatus.partiallyPaid) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.warning),
                          label: const Text('Mark Disputed'),
                          onPressed: () => _showDisputeDialog(reconciliation),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.block),
                          label: const Text('Write Off'),
                          onPressed: () => _showWriteOffDialog(reconciliation),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(PaymentRecord payment) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(_getPaymentMethodIcon(payment.method)),
      ),
      title: Text('\$${payment.amount.toStringAsFixed(2)}'),
      subtitle: Text(
        '${_getPaymentMethodLabel(payment.method)} • ${_formatDate(payment.paymentDate)}',
      ),
      trailing: payment.referenceNumber != null
          ? Text(
              'Ref: ${payment.referenceNumber}',
              style: const TextStyle(fontSize: 12),
            )
          : null,
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.paypal:
        return Icons.payment;
      case PaymentMethod.stripe:
        return Icons.payment;
      case PaymentMethod.other:
        return Icons.help_outline;
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddPaymentDialog(InvoiceReconciliation reconciliation) {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.bankTransfer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Payment Method'),
                DropdownButton<PaymentMethod>(
                  value: selectedMethod,
                  isExpanded: true,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(_getPaymentMethodLabel(method)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number (Optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                try {
                  final repository = ref.read(reconciliationRepositoryProvider);
                  final payment = PaymentRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: amount,
                    method: selectedMethod,
                    paymentDate: DateTime.now(),
                    referenceNumber: referenceController.text.isEmpty
                        ? null
                        : referenceController.text,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );

                  await repository.addPayment(reconciliation.id, payment);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(reconciliationsProvider(_selectedStatus));
                    ref.invalidate(reconciliationStatsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReconcileDialog(InvoiceReconciliation reconciliation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Reconciled'),
        content: Text(
          'Are you sure you want to mark invoice ${reconciliation.invoiceNumber} as reconciled?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(reconciliationRepositoryProvider);
                await repository.markAsReconciled(reconciliation.id, 'admin');

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(reconciliationsProvider(_selectedStatus));
                  ref.invalidate(reconciliationStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice marked as reconciled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(InvoiceReconciliation reconciliation) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Disputed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for dispute',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(reconciliationRepositoryProvider);
                await repository.markAsDisputed(
                  reconciliation.id,
                  notesController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(reconciliationsProvider(_selectedStatus));
                  ref.invalidate(reconciliationStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice marked as disputed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Mark Disputed'),
          ),
        ],
      ),
    );
  }

  void _showWriteOffDialog(InvoiceReconciliation reconciliation) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write Off Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to write off invoice ${reconciliation.invoiceNumber}?',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for write-off',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                final repository = ref.read(reconciliationRepositoryProvider);
                await repository.writeOff(
                  reconciliation.id,
                  notesController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(reconciliationsProvider(_selectedStatus));
                  ref.invalidate(reconciliationStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice written off')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Write Off'),
          ),
        ],
      ),
    );
  }
}