import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/models/affiliate.dart';
import 'package:shopsnports/models/enums.dart';
import 'package:shopsnports/services/affiliate_api_service.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'share_form_dialog.dart';

/// Affiliate Dashboard Screen
/// Central hub for affiliate earnings, shipments, and commissions
class AffiliateDashboardScreen extends ConsumerStatefulWidget {
  const AffiliateDashboardScreen({super.key});

  @override
  ConsumerState<AffiliateDashboardScreen> createState() =>
      _AffiliateDashboardScreenState();
}

class _AffiliateDashboardScreenState
    extends ConsumerState<AffiliateDashboardScreen> {
  final _affiliateService = AffiliateService();
  Affiliate? _affiliate;
  AffiliateEarnings? _earnings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final affiliate = await _affiliateService.getAffiliateProfile();
      final earnings = await _affiliateService.getEarnings();

      setState(() {
        _affiliate = affiliate;
        _earnings = earnings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(AffiliateStatus status) {
    switch (status) {
      case AffiliateStatus.approved:
        return Colors.green;
      case AffiliateStatus.pending:
        return Colors.orange;
      case AffiliateStatus.suspended:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load dashboard',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? 'Unknown error',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: CustomScrollView(
                    slivers: [
                      // Profile Header Card
                      SliverToBoxAdapter(
                        child: _buildProfileCard(context),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                      // Earnings Overview Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Earnings Overview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: 'Total Earnings',
                                  value: _earnings != null
                                      ? '\$${_earnings!.totalEarnings.toStringAsFixed(2)}'
                                      : '\$0.00',
                                  icon: Icons.account_balance_wallet,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: 'Pending',
                                  value: _earnings != null
                                      ? '\$${_earnings!.pendingPayout.toStringAsFixed(2)}'
                                      : '\$0.00',
                                  icon: Icons.pending_actions,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatCard(
                            context,
                            title: 'This Month',
                            value: _earnings != null
                                ? '\$${_earnings!.thisMonthEarnings.toStringAsFixed(2)}'
                                : '\$0.00',
                            subtitle: _earnings != null
                                ? '${_earnings!.thisMonthShipments} shipments'
                                : '0 shipments',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      // Performance Stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Performance',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: 'Total Shipments',
                                  value: _earnings != null
                                      ? _earnings!.totalShipments.toString()
                                      : '0',
                                  icon: Icons.local_shipping,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  title: 'Avg Commission',
                                  value: _earnings != null
                                      ? '\$${_earnings!.averageCommission.toStringAsFixed(2)}'
                                      : '\$0.00',
                                  icon: Icons.attach_money,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      // Quick Actions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Quick Actions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildActionTile(
                                context,
                                icon: Icons.add_box,
                                title: 'New Shipping Request',
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.requestShipping,
                                  );
                                },
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.share,
                                title: 'Share Form with Client',
                                subtitle: 'Send shipping form to client',
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const ShareFormDialog(),
                                  );
                                },
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.list_alt,
                                title: 'View Shipments',
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.affiliateDashboard,
                                  );
                                },
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.account_balance_wallet,
                                title: 'Payment History',
                                subtitle: _earnings?.pendingPayout != null &&
                                        _earnings!.pendingPayout > 0
                                    ? '\$${_earnings!.pendingPayout.toStringAsFixed(2)} pending'
                                    : 'View past payouts',
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.affiliatePayouts,
                                    arguments: {
                                      'affiliateId': _affiliate?.id ?? ''
                                    },
                                  );
                                },
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.bar_chart,
                                title: 'Commission Tracking',
                                subtitle: 'Monitor your earnings',
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.affiliateCommissionTracking,
                                  );
                                },
                              ),
                              _buildActionTile(
                                context,
                                icon: Icons.settings,
                                title: 'Settings',
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.affiliateProfile,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      // Form Share Analytics Section (NEW)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Form Share Analytics',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildFormShareAnalyticsCard(context),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    if (_affiliate == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _affiliate!.fullName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _affiliate!.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (_affiliate!.companyName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _affiliate!.companyName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _getStatusColor(_affiliate!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(_affiliate!.status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _affiliate!.status == AffiliateStatus.approved
                        ? Icons.check_circle
                        : _affiliate!.status == AffiliateStatus.pending
                            ? Icons.schedule
                            : Icons.block,
                    color: _getStatusColor(_affiliate!.status),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_affiliate!.status.displayName}',
                    style: TextStyle(
                      color: _getStatusColor(_affiliate!.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Commission: ${_affiliate!.commissionRate}%',
                    style: TextStyle(
                      color: _getStatusColor(_affiliate!.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// Build Form Share Analytics Card
  /// Shows: Links sent, Links used, Conversion rate
  /// Fetches real data from Firestore
  Widget _buildFormShareAnalyticsCard(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('form_shares')
          .where('affiliateId', isEqualTo: _affiliate?.id ?? '')
          .snapshots(),
      builder: (context, snapshot) {
        int totalSent = 0;
        int totalUsed = 0;
        String conversionRate = '0%';

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalSent = docs.length;
          totalUsed = docs.where((d) => d['used'] == true).length;
          conversionRate = totalSent > 0
              ? '${((totalUsed / totalSent) * 100).toStringAsFixed(0)}%'
              : '0%';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Shareable Forms',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsStat(
                        context,
                        icon: Icons.link,
                        label: 'Links Sent',
                        value: '$totalSent',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsStat(
                        context,
                        icon: Icons.check_circle,
                        label: 'Successfully Used',
                        value: '$totalUsed',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsStat(
                        context,
                        icon: Icons.trending_up,
                        label: 'Conversion Rate',
                        value: conversionRate,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.affiliateFormShares,
                        arguments: {'affiliateId': _affiliate?.id ?? ''},
                      );
                    },
                    child: const Text('View All Shares'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build individual analytics stat
  Widget _buildAnalyticsStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
