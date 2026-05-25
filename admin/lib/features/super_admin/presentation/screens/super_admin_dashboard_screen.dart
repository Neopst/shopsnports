import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/super_admin_providers.dart';
import '../screens/admin_activity_logs_screen.dart';
import '../screens/manage_admins_screen.dart';
import '../screens/super_admin_my_profile_screen.dart';
import '../dialogs/create_admin_dialog.dart';

/// Main dashboard for super admin
/// - Overview of admin counts and status
/// - Recent activity summary
/// - Quick action buttons
/// - Navigation to all super admin features
class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatisticsProvider);
    final activitySummaryAsync = ref.watch(activitySummaryProvider);
    final recentLogsAsync = ref.watch(allActivityLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            // Statistics cards
            statsAsync.when(
              data: (stats) => _buildStatisticsSection(context, stats),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Activity summary
            activitySummaryAsync.when(
              data: (summary) => _buildActivitySummarySection(context, summary),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Recent activity
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            recentLogsAsync.when(
              data: (logs) =>
                  _buildRecentActivitySection(context, logs.take(5).toList()),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Quick actions
            _buildQuickActionsSection(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build statistics section with admin counts
  Widget _buildStatisticsSection(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Admins',
                value: '${stats['total'] ?? 0}',
                icon: Icons.admin_panel_settings,
                color: Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                title: 'Active',
                value: '${stats['active'] ?? 0}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                title: 'Disabled',
                value: '${stats['disabled'] ?? 0}',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
          ],
        ),
        if ((stats['superAdmins'] ?? 0) > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border.all(color: Colors.purple.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              spacing: 12,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.purple.shade600),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      const Text(
                        'Super Admins',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        '${stats['superAdmins']} super admin(s) with full system access',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build activity summary section
  Widget _buildActivitySummarySection(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 12,
        children: [
          const Icon(Icons.history, color: Colors.orange),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                const Text(
                  'Activity Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Row(
                  spacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        const Text('Last 24h', style: TextStyle(fontSize: 11)),
                        Text(
                          '${summary['last24h'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        const Text('Last 7d', style: TextStyle(fontSize: 11)),
                        Text(
                          '${summary['last7d'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 11)),
                        Text(
                          '${summary['total'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent activity section
  Widget _buildRecentActivitySection(BuildContext context, dynamic logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            spacing: 8,
            children: const [
              Icon(Icons.history, size: 32, color: Colors.grey),
              Text('No recent activity', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: logs.asMap().entries.map((entry) {
          final index = entry.key;
          final log = entry.value;

          return Column(
            children: [
              if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  spacing: 12,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, size: 16, color: Colors.blue),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            log.action.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${log.adminEmail} • ${log.timeFormatted}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      log.success ? Icons.check_circle : Icons.error,
                      size: 20,
                      color: log.success ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build quick actions section
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.person,
                label: 'My Profile',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminMyProfileScreen(),
                    ),
                  );
                },
                color: Colors.indigo,
              ),
            ),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.person_add,
                label: 'Create Admin',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateAdminDialog(),
                  );
                },
                color: Colors.blue,
              ),
            ),
          ],
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.admin_panel_settings,
                label: 'Manage Admins',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageAdminsScreen(),
                    ),
                  );
                },
                color: Colors.purple,
              ),
            ),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.history,
                label: 'View Logs',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminActivityLogsScreen(),
                    ),
                  );
                },
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build statistic card
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        border: Border.all(color: color.withValues(alpha:0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        spacing: 8,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha:0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            spacing: 8,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
