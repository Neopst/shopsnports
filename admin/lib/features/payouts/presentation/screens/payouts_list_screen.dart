import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payouts_providers.dart';
import '../../data/models/payout_models.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class PayoutsListScreen extends ConsumerStatefulWidget {
  const PayoutsListScreen({super.key});

  @override
  ConsumerState<PayoutsListScreen> createState() => _PayoutsListScreenState();
}

class _PayoutsListScreenState extends ConsumerState<PayoutsListScreen> {
  String? _statusFilter;
  String? _recipientTypeFilter;

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    final filter = PayoutsFilter(
      status: _statusFilter,
      recipientType: _recipientTypeFilter,
    );

    final payoutsAsync = ref.watch(payoutsListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(payoutsListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Payouts List
          Expanded(
            child: payoutsAsync.when(
              data: (payouts) => payouts.isEmpty
                  ? const Center(child: Text('No payouts found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payouts.length,
                      itemBuilder: (context, index) {
                        return _buildPayoutCard(payouts[index], formatter);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(payoutsListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _recipientTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Recipient Type',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'affiliate', child: Text('Affiliates')),
                DropdownMenuItem(value: 'shipper', child: Text('Shippers')),
              ],
              onChanged: (value) =>
                  setState(() => _recipientTypeFilter = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Payout payout, CurrencyFormatter formatter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payout.payoutNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(payout.status),
              ],
            ),
            const SizedBox(height: 12),

            // Recipient Info
            Row(
              children: [
                Icon(_getRecipientIcon(payout.recipientType), size: 20),
                const SizedBox(width: 8),
                Text(
                  payout.recipientName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payout.recipientType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildAmountRow(
                    'Gross Amount',
                    payout.grossAmount,
                    formatter,
                  ),
                  _buildAmountRow(
                    'Commission',
                    -payout.commissionAmount,
                    formatter,
                    isNegative: true,
                  ),
                  _buildAmountRow(
                    'Tax',
                    -payout.taxAmount,
                    formatter,
                    isNegative: true,
                  ),
                  const Divider(),
                  _buildAmountRow(
                    'Net Amount',
                    payout.netAmount,
                    formatter,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Period and Payment Method
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Period',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(payout.periodStart)} - ${DateFormat('MMM d, y').format(payout.periodEnd)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        payout.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action Buttons
            if (payout.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePayout(payout),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (payout.status == 'approved') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _processPayout(payout),
                  icon: const Icon(Icons.send),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (payout.status == 'completed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Completed on ${DateFormat('MMM d, y').format(payout.processedAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (payout.paymentReference != null)
                Text(
                  'Ref: ${payout.paymentReference}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    CurrencyFormatter formatter, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(amount.abs(), decimalDigits: 2),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? Colors.red
                  : (isBold ? Colors.green[700] : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'approved':
        color = Colors.blue;
        icon = Icons.check;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRecipientIcon(String type) {
    switch (type) {
      case 'affiliate':
        return Icons.person;
      case 'shipper':
        return Icons.local_shipping;
      default:
        return Icons.account_circle;
    }
  }

  Future<void> _approvePayout(Payout payout) async {
    final selectedCurrency = ref.read(selectedCurrencyProvider);
    final currencyService = ref.read(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payout'),
        content: Text(
          'Approve payout of ${formatter.format(payout.netAmount, decimalDigits: 2)} to ${payout.recipientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(
          approvePayoutProvider((
            payoutId: payout.id,
            approvedBy: 'admin',
          )).future,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _processPayout(Payout payout) async {
    final selectedCurrency = ref.read(selectedCurrencyProvider);
    final currencyService = ref.read(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Process payout of ${formatter.format(payout.netAmount, decimalDigits: 2)} to ${payout.recipientName}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Payment Reference',
                hintText: 'Enter transaction reference',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        await ref.read(
          processPayoutProvider((
            payoutId: payout.id,
            processedBy: 'admin',
            paymentReference: result,
          )).future,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout processed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
