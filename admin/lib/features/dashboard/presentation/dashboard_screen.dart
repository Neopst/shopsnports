// FILE: lib/features/dashboard/presentation/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/dashboard_stats_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(),
          const SizedBox(height: 24),

          // Enhanced KPI Grid
          _buildEnhancedKpiGrid(context, statsAsync),
          const SizedBox(height: 24),

          // Shipping Performance Section
          _buildShippingPerformance(context, statsAsync),
          const SizedBox(height: 24),

          // Quick Actions Section
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Recent Activity Section
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getCurrentDate(),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEnhancedKpiGrid(BuildContext context, AsyncValue<DashboardStats> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        _buildFinancialKpiGrid(context, statsAsync),
      ],
    );
  }

  Widget _buildFinancialKpiGrid(BuildContext context, AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => _buildKpiGridWithData(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildKpiGridWithError(context, error),
    );
  }

  Widget _buildKpiGridWithData(BuildContext context, DashboardStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _FinancialKpiCard(
          title: 'Total Revenue',
          value: stats.formattedRevenue,
          subtitle: '${stats.totalShipments} shipments',
          icon: Icons.trending_up,
          color: Colors.green,
          onTap: () => context.go('/dashboard/orders'),
        ),
        _FinancialKpiCard(
          title: 'Total Commissions',
          value: stats.formattedCommissions,
          subtitle: '${stats.totalAffiliates} affiliates',
          icon: Icons.percent,
          color: Colors.blue,
          onTap: () => context.go('/dashboard/affiliates'),
        ),
        _FinancialKpiCard(
          title: 'Average Order Value',
          value: stats.formattedAOV,
          subtitle: 'Per shipment',
          icon: Icons.shopping_cart,
          color: Colors.purple,
          onTap: () => context.go('/dashboard/orders'),
        ),
        _FinancialKpiCard(
          title: 'Total Orders',
          value: stats.totalOrders.toString(),
          subtitle: stats.pendingShipments > 0
            ? '${stats.pendingShipments} pending'
            : 'All processed',
          icon: Icons.receipt_long,
          color: Colors.orange,
          onTap: () => context.go('/dashboard/orders'),
        ),
      ],
    );
  }

  Widget _buildKpiGridWithError(BuildContext context, Object error) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _FinancialKpiCard(
          title: 'Total Revenue',
          value: '\$0.00',
          subtitle: 'Unable to load',
          icon: Icons.trending_up,
          color: Colors.grey,
          onTap: () {},
        ),
        _FinancialKpiCard(
          title: 'Total Commissions',
          value: '\$0.00',
          subtitle: 'Unable to load',
          icon: Icons.percent,
          color: Colors.grey,
          onTap: () {},
        ),
        _FinancialKpiCard(
          title: 'Average Order Value',
          value: '\$0.00',
          subtitle: 'Unable to load',
          icon: Icons.shopping_cart,
          color: Colors.grey,
          onTap: () {},
        ),
        _FinancialKpiCard(
          title: 'Total Orders',
          value: '0',
          subtitle: 'Unable to load',
          icon: Icons.receipt_long,
          color: Colors.grey,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildShippingPerformance(BuildContext context, AsyncValue<DashboardStats> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ShippingKpiCard(
              title: 'On-Time Delivery Rate',
              value: '94.2%',
              progress: 0.942,
              target: 0.95,
              icon: Icons.timer,
              color: Colors.green,
            ),
            _ShippingKpiCard(
              title: 'Capacity Utilization',
              value: '78.5%',
              progress: 0.785,
              target: 0.85,
              icon: Icons.airline_seat_recline_normal,
              color: Colors.blue,
            ),
            _ShippingKpiCard(
              title: 'Claim Rate',
              value: '1.2%',
              progress: 0.012,
              target: 0.01,
              isLowerBetter: true,
              icon: Icons.warning,
              color: Colors.orange,
            ),
            _ShippingKpiCard(
              title: 'Active Shipments',
              value: '23',
              subtitle: 'In transit',
              icon: Icons.local_shipping,
              color: Colors.purple,
              onTap: () => context.go('/dashboard/shipping-request'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.store,
                  label: 'Manage Vendors',
                  color: Colors.blue,
                  onTap: () => context.go('/dashboard/vendors'),
                ),
                _QuickActionButton(
                  icon: Icons.local_shipping,
                  label: 'Shipping Requests',
                  color: Colors.green,
                  onTap: () => context.go('/dashboard/shipping-request'),
                ),
                _QuickActionButton(
                  icon: Icons.payment,
                  label: 'Process Payouts',
                  color: Colors.purple,
                  onTap: () => context.go('/dashboard/payouts'),
                ),
                _QuickActionButton(
                  icon: Icons.notifications,
                  label: 'Send Alert',
                  color: Colors.orange,
                  onTap: () => _showNotificationDialog(context),
                ),
                _QuickActionButton(
                  icon: Icons.people,
                  label: 'Customer Support',
                  color: Colors.teal,
                  onTap: () => context.go('/dashboard/customers'),
                ),
                _QuickActionButton(
                  icon: Icons.analytics,
                  label: 'View Reports',
                  color: Colors.indigo,
                  onTap: () => context.go('/dashboard/analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOrderList(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPlatformStatus(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    final orders = [
      {'id': '#1048', 'status': 'Completed', 'customer': 'John Doe'},
      {'id': '#1047', 'status': 'Pending', 'customer': 'Sarah Wilson'},
      {'id': '#1046', 'status': 'Shipped', 'customer': 'Mike Johnson'},
      {'id': '#1045', 'status': 'Processing', 'customer': 'Emma Davis'},
    ];

    return Column(
      children: orders
          .map(
            (order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    _getOrderStatusIcon(order['status']!),
                    size: 16,
                    color: _getOrderStatusColor(order['status']!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order['id']} - ${order['customer']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Chip(
                    label: Text(
                      order['status']!,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: _getOrderStatusColor(order['status']!),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlatformStatus() {
    return Column(
      children: [
        _PlatformStatusItem(
          label: 'Active Vendors',
          value: '15',
          color: Colors.green,
        ),
        _PlatformStatusItem(
          label: 'Pending Approval',
          value: '3',
          color: Colors.orange,
        ),
        _PlatformStatusItem(
          label: 'Total Products',
          value: '245',
          color: Colors.blue,
        ),
        _PlatformStatusItem(
          label: 'System Health',
          value: 'Excellent',
          color: Colors.green,
        ),
      ],
    );
  }

  // Helper methods
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  // DEPRECATED: Use dashboardStatsProvider instead
  @Deprecated('Use dashboardStatsProvider for real data')
  Map<String, dynamic> _calculateMockMetrics() {
    return {
      'gmv': '125.4K',
      'profitMargin': '18.5',
      'aov': '245.60',
      'totalOrders': '512',
    };
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'processing':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: const Text(
          'This feature will be implemented in the next phase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Enhanced KPI Card Widgets
class _FinancialKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FinancialKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          width: 220,
          height: 110,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double? progress;
  final double? target;
  final bool isLowerBetter;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ShippingKpiCard({
    required this.title,
    required this.value,
    this.progress,
    this.target,
    this.isLowerBetter = false,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool showProgress = progress != null && target != null;
    final bool meetsTarget = showProgress
        ? (isLowerBetter ? progress! <= target! : progress! >= target!)
        : true;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (showProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: meetsTarget
                            ? Colors.green.withAlpha(40)
                            : Colors.orange.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meetsTarget ? 'On Target' : 'Needs Attention',
                        style: TextStyle(
                          color: meetsTarget ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
              if (showProgress) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: meetsTarget ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${(target! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformStatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PlatformStatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
