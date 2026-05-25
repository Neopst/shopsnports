// lib/features/affiliates/presentation/affiliate_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/affiliate_provider.dart';
import '../domain/affiliate_model.dart';

class AffiliateDetailScreen extends ConsumerStatefulWidget {
  final String affiliateId;

  const AffiliateDetailScreen({super.key, required this.affiliateId});

  @override
  ConsumerState<AffiliateDetailScreen> createState() =>
      _AffiliateDetailScreenState();
}

class _AffiliateDetailScreenState extends ConsumerState<AffiliateDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final affiliateAsync = ref.watch(affiliateByIdProvider(widget.affiliateId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate Details'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Shipping'),
            Tab(icon: Icon(Icons.attach_money), text: 'Earnings'),
            Tab(icon: Icon(Icons.payment), text: 'Payouts'),
            Tab(icon: Icon(Icons.history), text: 'Activity'),
          ],
        ),
      ),
      body: affiliateAsync.when(
        data: (affiliate) {
          if (affiliate == null) {
            return const Center(child: Text('Affiliate not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ProfileTab(affiliate: affiliate),
              _ShippingHistoryTab(affiliateId: widget.affiliateId),
              _EarningsTab(
                affiliate: affiliate,
                affiliateId: widget.affiliateId,
              ),
              _PayoutsTab(affiliateId: widget.affiliateId),
              _ActivityTab(affiliate: affiliate),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
            ],
          ),
        ),
      ),
      floatingActionButton: affiliateAsync.when(
        data: (affiliate) {
          if (affiliate == null || affiliate.pendingPayout <= 0) return null;
          return FloatingActionButton.extended(
            onPressed: () => _generatePayout(affiliate),
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.payment),
            label: const Text('Generate Payout'),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Future<void> _generatePayout(Affiliate affiliate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate payout for ${affiliate.fullName}?'),
            const SizedBox(height: 16),
            Text(
              'Amount: ${affiliate.preferredCurrency.symbol}${affiliate.pendingPayout.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Generate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        final payoutId = await repository.generatePayoutForAffiliate(
          affiliate.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                payoutId != null
                    ? 'Payout generated! ID: $payoutId'
                    : 'No unpaid shipments found',
              ),
              backgroundColor: payoutId != null ? Colors.green : Colors.orange,
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

// ==================== PROFILE TAB ====================
class _ProfileTab extends StatelessWidget {
  final Affiliate affiliate;

  const _ProfileTab({required this.affiliate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and basic info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: affiliate.photoUrl != null
                      ? NetworkImage(affiliate.photoUrl!)
                      : null,
                  child: affiliate.photoUrl == null
                      ? Text(
                          affiliate.fullName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 48),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  affiliate.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(affiliate.status),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Contact Information
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _InfoCard(icon: Icons.email, label: 'Email', value: affiliate.email),
          _InfoCard(icon: Icons.phone, label: 'Phone', value: affiliate.phone),
          if (affiliate.companyName != null)
            _InfoCard(
              icon: Icons.business,
              label: 'Company',
              value: affiliate.companyName!,
            ),
          if (affiliate.address != null)
            _InfoCard(
              icon: Icons.location_on,
              label: 'Address',
              value: affiliate.address!,
            ),

          const SizedBox(height: 24),

          // Business Information
          const Text(
            'Business Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.percent,
            label: 'Commission Rate',
            value: '${affiliate.commissionRate}%',
          ),
          _InfoCard(
            icon: Icons.schedule,
            label: 'Payout Schedule',
            value: affiliate.payoutSchedule.name,
          ),
          if (affiliate.countryCode != null)
            _InfoCard(
              icon: Icons.location_on,
              label: 'Country',
              value: affiliate.countryCode!,
            ),
          _InfoCard(
            icon: Icons.attach_money,
            label: 'Preferred Currency',
            value: '${affiliate.preferredCurrency.name.toUpperCase()} (${affiliate.preferredCurrency.symbol})',
          ),
          if (affiliate.bankAccountDetails != null)
            _InfoCard(
              icon: Icons.account_balance,
              label: 'Bank Account',
              value: affiliate.bankAccountDetails!,
            ),
          if (affiliate.taxId != null)
            _InfoCard(
              icon: Icons.receipt,
              label: 'Tax ID',
              value: affiliate.taxId!,
            ),

          const SizedBox(height: 24),

          // Approval Information
          const Text(
            'Status Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.calendar_today,
            label: 'Joined',
            value: _formatDate(affiliate.joinedDate),
          ),
          if (affiliate.approvedAt != null)
            _InfoCard(
              icon: Icons.check_circle,
              label: 'Approved',
              value: _formatDate(affiliate.approvedAt!),
            ),
          if (affiliate.approvedBy != null)
            _InfoCard(
              icon: Icons.person,
              label: 'Approved By',
              value: affiliate.approvedBy!,
            ),
          if (affiliate.rejectionReason != null)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: const Text('Rejection Reason'),
                subtitle: Text(affiliate.rejectionReason!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AffiliateStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AffiliateStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case AffiliateStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AffiliateStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case AffiliateStatus.suspended:
        color = Colors.grey;
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A2A66)),
        title: Text(label),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

// ==================== SHIPPING HISTORY TAB ====================
class _ShippingHistoryTab extends ConsumerWidget {
  final String affiliateId;

  const _ShippingHistoryTab({required this.affiliateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(affiliateShipmentsProvider(affiliateId));
    final affiliateAsync = ref.watch(affiliateByIdProvider(affiliateId));

    return shipmentsAsync.when(
      data: (shipments) {
        if (shipments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('No shipments found'),
              ],
            ),
          );
        }

        final affiliate = affiliateAsync.value;
        final symbol = affiliate?.preferredCurrency.symbol ?? '\$';

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF0A2A66).withValues(alpha:0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Route')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Commission')),
                  DataColumn(label: Text('Created')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: shipments.map((shipment) {
                  final origin =
                      shipment['pickupLocation'] as String? ?? 'Unknown';
                  final destination =
                      shipment['deliveryLocation'] as String? ?? 'Unknown';
                  final status = shipment['status'] as String? ?? 'pending';
                  final commission =
                      (shipment['commissionAmount'] as num?)?.toDouble() ?? 0.0;
                  final created = shipment['createdAt'];

                  return DataRow(
                    cells: [
                      DataCell(Text(shipment['id'] as String? ?? 'N/A')),
                      DataCell(Text('$origin → $destination')),
                      DataCell(_buildStatusChip(status)),
                      DataCell(Text('$symbol${commission.toStringAsFixed(2)}')),
                      DataCell(Text(_formatTimestamp(created))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            context.go('/shipping/${shipment['id']}');
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'in_transit':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withValues(alpha:0.2),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as dynamic).toDate() as DateTime;
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

// ==================== EARNINGS TAB ====================
class _EarningsTab extends ConsumerWidget {
  final Affiliate affiliate;
  final String affiliateId;

  const _EarningsTab({required this.affiliate, required this.affiliateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(affiliateEarningsProvider(affiliateId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _EarningsCard(
                  title: 'Total Earnings',
                  amount: affiliate.totalEarnings,
                  icon: Icons.attach_money,
                  color: Colors.green,
                  currencySymbol: affiliate.preferredCurrency.symbol,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _EarningsCard(
                  title: 'Pending Payout',
                  amount: affiliate.pendingPayout,
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  currencySymbol: affiliate.preferredCurrency.symbol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Shipments',
                  value: affiliate.totalShipments.toString(),
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCardWidget(
                  title: 'Last Payout',
                  value: affiliate.lastPayoutDate != null
                      ? _formatDate(affiliate.lastPayoutDate!)
                      : 'Never',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Calculated Earnings
          const Text(
            'Current Period Earnings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          earningsAsync.when(
            data: (earnings) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          size: 32,
                          color: Color(0xFF0A2A66),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Calculated from Delivered Shipments',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Text(
                      '${affiliate.preferredCurrency.symbol}${earnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error calculating earnings: $err'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  const _EarningsCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCardWidget({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
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
}

// ==================== PAYOUTS TAB ====================
class _PayoutsTab extends ConsumerWidget {
  final String affiliateId;

  const _PayoutsTab({required this.affiliateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(affiliatePayoutsProvider(affiliateId));
    final affiliateAsync = ref.watch(affiliateByIdProvider(affiliateId));

    return payoutsAsync.when(
      data: (payouts) {
        if (payouts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payouts yet'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF0A2A66).withValues(alpha:0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Payout ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Shipments')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: payouts.map((payout) {
                  final affiliate = affiliateAsync.value;
                  final symbol = affiliate?.preferredCurrency.symbol ?? '\$';
                  return DataRow(
                    cells: [
                      DataCell(Text(payout.id.substring(0, 8))),
                      DataCell(Text('$symbol${payout.amount.toStringAsFixed(2)}')),
                      DataCell(_buildPayoutStatusBadge(payout.status)),
                      DataCell(Text(payout.shipmentIds.length.toString())),
                      DataCell(Text(_formatDate(payout.payoutDate))),
                      DataCell(
                        payout.status == PayoutStatus.pending
                            ? IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () => _markPayoutCompleted(
                                  context,
                                  ref,
                                  payout.id,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildPayoutStatusBadge(PayoutStatus status) {
    Color color;
    switch (status) {
      case PayoutStatus.pending:
        color = Colors.orange;
        break;
      case PayoutStatus.processing:
        color = Colors.blue;
        break;
      case PayoutStatus.completed:
        color = Colors.green;
        break;
      case PayoutStatus.failed:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(status.name.toUpperCase()),
      backgroundColor: color.withValues(alpha:0.2),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _markPayoutCompleted(
    BuildContext context,
    WidgetRef ref,
    String payoutId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Payout Completed'),
        content: const Text(
          'Confirm that the payout has been transferred to the affiliate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        // Get payout details first to get affiliateId and amount
        final payouts = await repository.getPayoutsByAffiliate(affiliateId);
        final payout = payouts.firstWhere((p) => p.id == payoutId);

        await repository.processPayout(
          payoutId: payoutId,
          affiliateId: payout.affiliateId,
          amount: payout.amount,
          transactionReference:
              'TRANSFER_REF_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// ==================== ACTIVITY TAB ====================
class _ActivityTab extends StatelessWidget {
  final Affiliate affiliate;

  const _ActivityTab({required this.affiliate});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Activity timeline coming soon'),
        ],
      ),
    );
  }
}
