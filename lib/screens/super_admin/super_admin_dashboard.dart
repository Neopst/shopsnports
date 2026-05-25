import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/super_admin_provider.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/models/admin_user.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';
import 'package:shopsnports/widgets/create_sub_admin_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Super Admin Dashboard - Main hub for platform management
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OverviewTab(),
    const SubAdminsTab(),
    const ActivityLogsTab(),
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'Admin Management',
    'Activity Logs',
  ];

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.admin_panel_settings,
    Icons.history,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          // Admin profile badge
          Consumer(
            builder: (context, ref, _) {
              final admin = ref.watch(currentAdminProvider);
              return admin.when(
                data: (adminUser) {
                  if (adminUser == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Chip(
                      label: Text(adminUser.displayName),
                      avatar: const Icon(Icons.person, size: 18),
                      backgroundColor: const Color(0xFF1565C0),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: _titles.asMap().entries.map((entry) {
              return NavigationRailDestination(
                icon: Icon(_icons[entry.key]),
                label: Text(entry.value),
              );
            }).toList(),
            backgroundColor: Colors.grey[50],
            indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Main Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(authActionsProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Overview Tab - Dashboard with stats and quick actions
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAdminsAsync = ref.watch(allSubAdminsProvider);
    final currentAdminAsync = ref.watch(currentAdminProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          currentAdminAsync.when(
            data: (admin) => Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${admin?.displayName ?? "Admin"}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Super Administrator Dashboard',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Stats Cards
          subAdminsAsync.when(
            data: (subAdmins) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.admin_panel_settings,
                    label: 'Total Admins',
                    value: '${subAdmins.length + 1}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Active',
                    value: '${subAdmins.where((a) => a.isActive).length + 1}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pause_circle,
                    label: 'Suspended',
                    value: '${subAdmins.where((a) => a.isSuspended).length}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            loading: () => const Row(
              children: [
                Expanded(child: Card(child: LinearProgressIndicator())),
                SizedBox(width: 16),
                Expanded(child: Card(child: LinearProgressIndicator())),
                SizedBox(width: 16),
                Expanded(child: Card(child: LinearProgressIndicator())),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_add,
                  title: 'Create Sub-Admin',
                  onTap: () => _showCreateAdminDialog(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.manage_accounts,
                  title: 'Manage Admins',
                  onTap: () {}, // Navigate to admin management
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.settings,
                  title: 'System Settings',
                  onTap: () {}, // Navigate to settings
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: const Color(0xFF1565C0)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateSubAdminDialog(),
    );
  }
}

/// Sub-Admins Tab - List and manage sub-admins
class SubAdminsTab extends ConsumerWidget {
  const SubAdminsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAdminsAsync = ref.watch(allSubAdminsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sub-Administrators',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CreateSubAdminDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Sub-Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sub-Admins List
          subAdminsAsync.when(
            data: (subAdmins) {
              if (subAdmins.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No sub-admins yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first sub-admin to help manage the platform',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: subAdmins.length,
                itemBuilder: (context, index) {
                  final admin = subAdmins[index];
                  return SubAdminCard(admin: admin);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Error loading sub-admins',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a sub-admin
class SubAdminCard extends ConsumerWidget {
  final AdminUser admin;

  const SubAdminCard({super.key, required this.admin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  admin.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    admin.email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(admin.roleType.displayName),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(
                            color: Colors.blue[700], fontSize: 11),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text(admin.status.displayName),
                        backgroundColor: admin.status == UserStatus.active
                            ? Colors.green[50]
                            : Colors.orange[50],
                        labelStyle: TextStyle(
                            color: admin.status == UserStatus.active
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontSize: 11),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Permissions'),
                ),
                if (admin.isActive)
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Text('Suspend Admin'),
                  ),
                if (admin.isSuspended)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reactivate Admin'),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Admin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        _showEditPermissionsDialog(context);
        break;
      case 'suspend':
        await _suspendAdmin(context, ref);
        break;
      case 'reactivate':
        await _reactivateAdmin(context, ref);
        break;
      case 'delete':
        await _deleteAdmin(context, ref);
        break;
    }
  }

  void _showEditPermissionsDialog(BuildContext context) {
    // TODO: Implement edit permissions dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit permissions - Coming soon')),
    );
  }

  Future<void> _suspendAdmin(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Admin'),
        content: Text('Are you sure you want to suspend ${admin.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(suspendSubAdminProvider(admin.id).future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin suspended successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _reactivateAdmin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(reactivateSubAdminProvider(admin.id).future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin reactivated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAdmin(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text(
            'Are you sure you want to permanently delete ${admin.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(deleteSubAdminProvider(admin.id).future);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}

/// Activity Logs Tab
class ActivityLogsTab extends ConsumerWidget {
  const ActivityLogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('activity_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .get()
                    .then((snap) => snap.docs.map((doc) {
                          final data = doc.data();
                          data['id'] = doc.id;
                          return data;
                        }).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No activity logs yet'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: Icon(
                          _getActivityIcon(log['type']),
                          color: _getActivityColor(log['type']),
                        ),
                        title: Text(_formatActivityType(log['type'])),
                        subtitle: Text(
                          'By: ${log['performedBy'] ?? 'System'}\n${_formatTimestamp(log['timestamp'])}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'sub_admin_created':
        return Icons.person_add;
      case 'sub_admin_suspended':
        return Icons.pause_circle;
      case 'sub_admin_reactivated':
        return Icons.play_circle;
      case 'sub_admin_deleted':
        return Icons.delete;
      case 'permissions_updated':
        return Icons.security;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'sub_admin_created':
        return Colors.green;
      case 'sub_admin_suspended':
        return Colors.orange;
      case 'sub_admin_reactivated':
        return Colors.blue;
      case 'sub_admin_deleted':
        return Colors.red;
      case 'permissions_updated':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatActivityType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    }
    return timestamp.toString();
  }
}