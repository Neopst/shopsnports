import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payouts_providers.dart';
import '../../data/models/payout_models.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'payouts_settings_screen.dart';

class EnhancedPayoutsDashboard extends ConsumerStatefulWidget {
  final String? affiliateId;

  const EnhancedPayoutsDashboard({super.key, this.affiliateId});

  @override
  ConsumerState<EnhancedPayoutsDashboard> createState() =>
      _EnhancedPayoutsDashboardState();
}

class _EnhancedPayoutsDashboardState
    extends ConsumerState<EnhancedPayoutsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedPayouts = {};
  String? _filterAffiliateId;

  @override
  void initState() {
    super.initState();
    _filterAffiliateId = widget.affiliateId;
    // If filtering by affiliate, start on Affiliates tab (index 1)
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.affiliateId != null ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts Management'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.people), text: 'Affiliates'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          if (_selectedPayouts.isNotEmpty)
            TextButton.icon(
              onPressed: () => _bulkApprove(context),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                'Approve ${_selectedPayouts.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Commission & Tax Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PayoutsSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(payoutsListProvider),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(formatter),
          _buildAffiliatesTab(formatter),
          _buildHistoryTab(formatter),
          _buildAnalyticsTab(formatter),
        ],
      ),
    );
  }

  Widget _buildPendingTab(CurrencyFormatter formatter) {
    final filter = PayoutsFilter(status: 'pending');
    final payoutsAsync = ref.watch(payoutsListProvider(filter));

    return payoutsAsync.when(
      data: (payouts) {
        return payouts.isEmpty
            ? _buildEmptyState('No pending payouts')
            : Column(
                children: [
                  _buildPendingSummary(payouts, formatter),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payouts.length,
                      itemBuilder: (context, index) {
                        return _buildEnhancedPayoutCard(
                          payouts[index],
                          formatter,
                          showActions: true,
                        );
                      },
                    ),
                  ),
                ],
              );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        return _buildErrorState(error.toString(), stack.toString());
      },
    );
  }

  Widget _buildAffiliatesTab(CurrencyFormatter formatter) {
    // Use recipientId filter if affiliateId is provided
    final payoutsAsync = _filterAffiliateId != null
        ? ref.watch(payoutsListByAffiliateProvider(_filterAffiliateId!))
        : ref.watch(
            payoutsListProvider(PayoutsFilter(recipientType: 'affiliate')),
          );

    return payoutsAsync.when(
      data: (payouts) {
        return payouts.isEmpty
            ? _buildEmptyState('No affiliate payouts')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payouts.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedPayoutCard(payouts[index], formatter);
                },
              );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        return _buildErrorState(error.toString(), stack.toString());
      },
    );
  }

  Widget _buildHistoryTab(CurrencyFormatter formatter) {
    final filter = PayoutsFilter(status: 'completed');
    final payoutsAsync = ref.watch(payoutsListProvider(filter));

    return payoutsAsync.when(
      data: (payouts) {
        return payouts.isEmpty
            ? _buildEmptyState('No completed payouts')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payouts.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedPayoutCard(payouts[index], formatter);
                },
              );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        return _buildErrorState(error.toString());
      },
    );
  }

  Widget _buildAnalyticsTab(CurrencyFormatter formatter) {
    final statsAsync = ref.watch(payoutStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(stats, formatter),
            const SizedBox(height: 24),
            _buildTopRecipients(stats, formatter),
            const SizedBox(height: 24),
            _buildPaymentMethodChart(stats),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildPendingSummary(
    List<Payout> payouts,
    CurrencyFormatter formatter,
  ) {
    // Separate totals by currency
    final ngnTotal = payouts
        .where((p) => p.currency == 'NGN')
        .fold<double>(0, (sum, p) => sum + p.netAmount);
    final usdTotal = payouts
        .where((p) => p.currency == 'USD')
        .fold<double>(0, (sum, p) => sum + p.netAmount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.white, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Approval',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payouts.length} payout${payouts.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (ngnTotal > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NGN',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        formatter.formatNative(ngnTotal, currencyCode: 'NGN'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (usdTotal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'USD',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        formatter.formatNative(usdTotal, currencyCode: 'USD'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPayoutCard(
    Payout payout,
    CurrencyFormatter formatter, {
    bool showActions = false,
  }) {
    final isSelected = _selectedPayouts.contains(payout.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(payout.status).withValues(alpha:0.1),
            child: Row(
              children: [
                if (showActions && payout.status == 'pending')
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedPayouts.add(payout.id);
                        } else {
                          _selectedPayouts.remove(payout.id);
                        }
                      });
                    },
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            payout.payoutNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(payout.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payout.recipientName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.formatNative(
                        payout.netAmount,
                        currencyCode: payout.currency,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      payout.currency,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calculation Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                  'Total Sales/Earnings',
                  formatter.formatNative(
                    payout.grossAmount,
                    currencyCode: payout.currency,
                  ),
                  isGross: true,
                ),
                _buildBreakdownRow(
                  'Platform Fee',
                  '-${formatter.formatNative(
                    payout.commissionAmount,
                    currencyCode: payout.currency,
                  )}',
                  isDeduction: true,
                ),
                _buildBreakdownRow(
                  'Tax Withholding',
                  '-${formatter.formatNative(
                    payout.taxAmount,
                    currencyCode: payout.currency,
                  )}',
                  isDeduction: true,
                ),
                const Divider(thickness: 2),
                _buildBreakdownRow(
                  'NET PAYOUT',
                  formatter.formatNative(
                    payout.netAmount,
                    currencyCode: payout.currency,
                  ),
                  isFinal: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Period: ${DateFormat('MMM d').format(payout.periodStart)} - ${DateFormat('MMM d, yyyy').format(payout.periodEnd)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (payout.paymentMethod.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Payment: ${payout.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          if (showActions && payout.status == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _rejectPayout(payout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _approveSinglePayout(payout),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _processPayment(payout),
                    icon: const Icon(Icons.payment),
                    label: const Text('Process Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A66),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String amount, {
    bool isGross = false,
    bool isDeduction = false,
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isFinal ? 16 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
              color: isFinal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isFinal ? 18 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: isFinal
                  ? Colors.green
                  : isDeduction
                  ? Colors.red
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatsGrid(
    Map<String, dynamic> stats,
    CurrencyFormatter formatter,
  ) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Pending',
          formatter.format(stats['total_pending'] ?? 0),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          'To Process This Week',
          formatter.format(stats['to_process_this_week'] ?? 0),
          Icons.schedule,
          Colors.blue,
        ),
        _buildStatCard(
          'Paid This Month',
          formatter.format(stats['paid_this_month'] ?? 0),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Paid (All Time)',
          formatter.format(stats['total_paid'] ?? 0),
          Icons.account_balance_wallet,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRecipients(
    Map<String, dynamic> stats,
    CurrencyFormatter formatter,
  ) {
    final topRecipients = stats['top_recipients'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Earners This Month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topRecipients.take(5).map((recipient) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    recipient['name'][0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(recipient['name']),
                subtitle: Text(recipient['type'].toUpperCase()),
                trailing: Text(
                  formatter.format(recipient['amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChart(Map<String, dynamic> stats) {
    final paymentMethods = stats['payment_methods'] as Map? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.entries.map((entry) {
              final percentage = entry.value / 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                        Text('${entry.value}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.primaries[paymentMethods.keys.toList().indexOf(
                              entry.key,
                            ) %
                            Colors.primaries.length],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, [String? stackTrace]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Payouts',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            if (stackTrace != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Stack Trace'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      stackTrace,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(payoutsListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _approveSinglePayout(Payout payout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payout'),
        content: Text(
          'Approve payout of ${payout.netAmount} to ${payout.recipientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(
                approvePayoutProvider((
                  payoutId: payout.id,
                  approvedBy: 'admin',
                )),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payout approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _bulkApprove(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve'),
        content: Text('Approve ${_selectedPayouts.length} selected payouts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (final id in _selectedPayouts) {
                ref.read(
                  approvePayoutProvider((payoutId: id, approvedBy: 'admin')),
                );
              }
              setState(() => _selectedPayouts.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payouts approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  void _rejectPayout(Payout payout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject payout to ${payout.recipientName}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payout rejected'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _processPayment(Payout payout) {
    final referenceController = TextEditingController();
    String selectedMethod = payout.paymentMethod;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient: ${payout.recipientName}'),
              const SizedBox(height: 8),
              Text(
                'Amount: ${payout.netAmount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank Transfer'),
                  ),
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                  DropdownMenuItem(value: 'paystack', child: Text('Paystack')),
                  DropdownMenuItem(
                    value: 'flutterwave',
                    child: Text('Flutterwave'),
                  ),
                ],
                onChanged: (value) => selectedMethod = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Payment Reference/Transaction ID',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., TXN-2024-12345',
                ),
              ),
              if (payout.bankAccountNumber != null) ...[
                const SizedBox(height: 16),
                Text('Bank: ${payout.bankName ?? 'N/A'}'),
                Text('Account: ${payout.bankAccountNumber}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (referenceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter payment reference'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ref.read(
                processPayoutProvider((
                  payoutId: payout.id,
                  processedBy: 'admin',
                  paymentReference: referenceController.text,
                )),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment processed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }
}
