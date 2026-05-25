import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../services/affiliate_api_service.dart';
import '../../widgets/main_scaffold.dart';

/// Payout Management Screen
/// Admin Dashboard compliant - allows affiliates to request payouts and view history
class PayoutManagementScreen extends ConsumerStatefulWidget {
  const PayoutManagementScreen({super.key});

  @override
  ConsumerState<PayoutManagementScreen> createState() =>
      _PayoutManagementScreenState();
}

class _PayoutManagementScreenState
    extends ConsumerState<PayoutManagementScreen> {
  final _affiliateService = AffiliateService();
  List<Map<String, dynamic>> _payouts = [];
  double _availableBalance = 0;
  bool _isLoading = true;
  String? _error;
  PayoutStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadPayouts();
    _loadBalance();
  }

  Future<void> _loadPayouts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final listResponse = await _affiliateService.getPayouts(
        status: _filterStatus,
      );
      setState(() {
        _payouts = listResponse;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBalance() async {
    try {
      final earnings = await _affiliateService.getEarnings();
      setState(() => _availableBalance = earnings.pendingPayout);
    } catch (_) {
      // Ignore errors when loading balance
    }
  }

  Future<void> _requestPayout() async {
    if (_availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balance available for payout')),
      );
      return;
    }

    final amountController = TextEditingController(
      text: _availableBalance.toStringAsFixed(2),
    );
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0 || amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    try {
      await _affiliateService.requestPayout(
        amount: amount,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout requested successfully')),
      );
      _loadPayouts();
      _loadBalance();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Color _getStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.completed:
        return Colors.green;
      case PayoutStatus.processing:
        return Colors.blue;
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.completed:
        return Icons.check_circle;
      case PayoutStatus.processing:
        return Icons.sync;
      case PayoutStatus.pending:
        return Icons.pending;
      case PayoutStatus.failed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Payment History',
      showBackOnly: true,
      body: Column(
        children: [
          // Available Balance Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green,
                  Colors.green.shade700,
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_availableBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_availableBalance > 0) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _requestPayout,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text(
                      'Request Payout',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PayoutStatus?>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...PayoutStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadPayouts();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadPayouts,
                ),
              ],
            ),
          ),

          // Payouts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadPayouts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _payouts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No payout history'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadPayouts();
                              await _loadBalance();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _payouts.length,
                              itemBuilder: (context, index) {
                                final payout = _payouts[index];
                                final status = PayoutStatus.values.firstWhere(
                                  (e) => e.name == payout['status'],
                                  orElse: () => PayoutStatus.pending,
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(status)
                                          .withValues(alpha: 0.2),
                                      child: Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                    title: Text(
                                      '\$${(payout['amount'] as num).toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.name.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _getStatusColor(status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Requested: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(payout['requestDate'] as String))}',
                                        ),
                                        if (payout['processedDate'] != null)
                                          Text(
                                            'Processed: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(payout['processedDate'] as String))}',
                                          ),
                                        if (payout['transactionId'] != null)
                                          Text(
                                            'Transaction: ${payout['transactionId']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (payout['notes'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            payout['notes']!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
