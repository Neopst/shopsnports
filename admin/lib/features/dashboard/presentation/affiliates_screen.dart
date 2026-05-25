import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../affiliates/presentation/providers/affiliate_provider.dart';
import '../../affiliates/domain/affiliate_model.dart';
import '../../affiliates/data/affiliate_repository_firestore.dart';

class AffiliatesScreen extends ConsumerWidget {
  const AffiliatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliatesAsync = ref.watch(affiliatesProvider);
    final affiliateStatsAsync = ref.watch(affiliateStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAffiliateStatsHeader(affiliateStatsAsync),
          const SizedBox(height: 16),
          Expanded(
            child: affiliatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Colors.orange[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to Load Affiliates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().contains('permission-denied')
                          ? 'Firebase permission denied. Check Firestore rules.'
                          : error.toString().contains('no such collection')
                              ? 'The affiliates collection does not exist. Create it in Firestore.'
                              : 'Error: ${error.toString().substring(0, 100)}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(affiliatesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (affiliates) =>
                  _buildAffiliatesList(affiliates, ref, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliateStatsHeader(AsyncValue<Map<String, dynamic>> stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 8),
              Text('Loading stats...', style: TextStyle(color: Colors.grey)),
            ],
          ),
          data: (stats) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                stats['totalAffiliates'].toString(),
                Colors.blue,
              ),
              _buildStatItem(
                'Approved',
                stats['approvedAffiliates'].toString(),
                Colors.green,
              ),
              _buildStatItem(
                'Pending',
                stats['pendingAffiliates'].toString(),
                Colors.orange,
              ),
              _buildStatItem(
                'Total Paid',
                '\$${((stats['totalPaidOut'] as num?) ?? 0).toStringAsFixed(0)}',
                Colors.green,
              ),
              _buildStatItem(
                'Pending Payout',
                '\$${((stats['pendingPayouts'] as num?) ?? 0).toStringAsFixed(0)}',
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildAffiliatesList(
    List<Affiliate> affiliates,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (affiliates.isEmpty) {
      return const Center(
        child: Text(
          'No affiliates found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: affiliates.length,
      itemBuilder: (context, index) {
        final affiliate = affiliates[index];
        return _buildAffiliateCard(affiliate, ref, context);
      },
    );
  }

  Widget _buildAffiliateCard(
    Affiliate affiliate,
    WidgetRef ref,
    BuildContext context,
  ) {
    final repository = ref.read(affiliateRepositoryProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(affiliate.status),
          child: Text(
            affiliate.fullName.isNotEmpty
                ? affiliate.fullName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          affiliate.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(affiliate.email),
            Text(affiliate.phone),
            if (affiliate.companyName != null)
              Text('Company: ${affiliate.companyName}'),
            Text(
              'Commission: ${affiliate.commissionRate}% • Payout: ${affiliate.payoutSchedule.name}',
            ),
            Text(
              'Shipments: ${affiliate.totalShipments} • Earnings: \$${(affiliate.totalEarnings).toStringAsFixed(2)}',
            ),
            Text(
              'Pending Payout: \$${(affiliate.pendingPayout).toStringAsFixed(2)}',
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                affiliate.status.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getStatusColor(affiliate.status),
            ),
            const SizedBox(height: 4),
            if (affiliate.status == AffiliateStatus.pending) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: () => _updateAffiliateStatus(
                      affiliate,
                      AffiliateStatus.approved,
                      repository,
                      context,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _updateAffiliateStatus(
                      affiliate,
                      AffiliateStatus.suspended,
                      repository,
                      context,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: () => _showAffiliateDetails(affiliate, repository, context),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateAffiliateStatus(
    Affiliate affiliate,
    AffiliateStatus newStatus,
    AffiliateRepositoryFirestore repository,
    BuildContext context,
  ) async {
    try {
      await repository.updateAffiliateStatus(affiliate.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Affiliate ${affiliate.fullName} ${newStatus.name}'),
            backgroundColor: newStatus == AffiliateStatus.approved
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAffiliateDetails(
    Affiliate affiliate,
    AffiliateRepositoryFirestore repository,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(affiliate.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${affiliate.email}'),
              Text('Phone: ${affiliate.phone}'),
              if (affiliate.companyName != null)
                Text('Company: ${affiliate.companyName}'),
              Text('Status: ${affiliate.status.name.toUpperCase()}'),
              Text('Commission Rate: ${affiliate.commissionRate}%'),
              Text('Payout Schedule: ${affiliate.payoutSchedule.name}'),
              if (affiliate.bankAccountDetails != null)
                Text('Bank: ${affiliate.bankAccountDetails}'),
              if (affiliate.taxId != null) Text('Tax ID: ${affiliate.taxId}'),
              Text('Total Shipments: ${affiliate.totalShipments}'),
              Text(
                'Total Earnings: \$${(affiliate.totalEarnings).toStringAsFixed(2)}',
              ),
              Text(
                'Pending Payout: \$${(affiliate.pendingPayout).toStringAsFixed(2)}',
              ),
              Text('Joined: ${_formatDate(affiliate.joinedDate)}'),
              if (affiliate.lastPayoutDate != null)
                Text('Last Payout: ${_formatDate(affiliate.lastPayoutDate!)}'),
            ],
          ),
        ),
        actions: [
          if (affiliate.status == AffiliateStatus.pending) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateAffiliateStatus(
                  affiliate,
                  AffiliateStatus.approved,
                  repository,
                  context,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Approve',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateAffiliateStatus(
                  affiliate,
                  AffiliateStatus.suspended,
                  repository,
                  context,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard/payouts?affiliateId=${affiliate.id}');
            },
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('View Payout History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A2A66),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AffiliateStatus status) {
    switch (status) {
      case AffiliateStatus.pending:
        return Colors.orange;
      case AffiliateStatus.approved:
        return Colors.green;
      case AffiliateStatus.rejected:
        return Colors.red;
      case AffiliateStatus.suspended:
        return Colors.grey;
    }
  }
}
