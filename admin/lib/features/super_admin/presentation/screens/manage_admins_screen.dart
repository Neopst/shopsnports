import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_user.dart';
import '../providers/super_admin_providers.dart';
import '../screens/admin_permissions_screen.dart';
import '../screens/admin_profile_screen.dart';
import '../screens/create_admin_screen.dart';

/// Screen for managing all admin accounts
/// - View list of all admins with status
/// - Create new admins
/// - View admin details
/// - Disable/Enable admins
/// - Delete admins
/// - Filter by status
class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  String _filterStatus = 'all'; // 'all', 'active', 'disabled'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAdminsAsync = ref.watch(allAdminsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins'), elevation: 0),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchAndFilterBar(context),
          // Admin list
          Expanded(
            child: allAdminsAsync.when(
              data: (admins) {
                // Apply filters
                var filtered = admins;

                if (_filterStatus != 'all') {
                  filtered = filtered.where((admin) {
                    if (_filterStatus == 'active') {
                      return admin.isActive;
                    } else if (_filterStatus == 'disabled') {
                      return admin.isDisabled;
                    }
                    return true;
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where(
                        (admin) =>
                            admin.displayName.toLowerCase().contains(query) ||
                            admin.email.toLowerCase().contains(query),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No admins found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final admin = filtered[index];
                    return _buildAdminCard(context, admin);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading admins',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
          );
        },
        tooltip: 'Create New Admin',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build search and filter bar
  Widget _buildSearchAndFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade50,
      child: Column(
        spacing: 12,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All',
                  value: 'all',
                  selected: _filterStatus == 'all',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'all';
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'Active',
                  value: 'active',
                  selected: _filterStatus == 'active',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'active';
                    });
                  },
                  color: Colors.green,
                ),
                _buildFilterChip(
                  label: 'Disabled',
                  value: 'disabled',
                  selected: _filterStatus == 'disabled',
                  onTap: () {
                    setState(() {
                      _filterStatus = 'disabled';
                    });
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withValues(alpha:0.1),
      selectedColor: color ?? Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : (color ?? Colors.blue),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Build admin card
  Widget _buildAdminCard(BuildContext context, AdminUser admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: admin.isSuperAdmin ? Colors.purple : Colors.blue,
          child: Text(
            admin.displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(admin.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              admin.email,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              spacing: 8,
              children: [
                _buildStatusBadge(admin),
                if (admin.isSuperAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Super Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleAdminAction(context, admin, value);
          },
          itemBuilder: (BuildContext context) => [
            if (!admin.isSuperAdmin)
              PopupMenuItem(
                value: 'view',
                child: Row(
                  spacing: 12,
                  children: const [
                    Icon(Icons.visibility, size: 18),
                    Text('View Details'),
                  ],
                ),
              ),
            if (!admin.isSuperAdmin)
              PopupMenuItem(
                value: 'permissions',
                child: Row(
                  spacing: 12,
                  children: const [
                    Icon(Icons.security, size: 18),
                    Text('Manage Permissions'),
                  ],
                ),
              ),
            if (!admin.isSuperAdmin) const PopupMenuDivider(),
            if (!admin.isSuperAdmin && admin.isActive)
              PopupMenuItem(
                value: 'disable',
                child: Row(
                  spacing: 12,
                  children: const [
                    Icon(Icons.block, size: 18, color: Colors.orange),
                    Text('Disable'),
                  ],
                ),
              ),
            if (!admin.isSuperAdmin && admin.isDisabled)
              PopupMenuItem(
                value: 'enable',
                child: Row(
                  spacing: 12,
                  children: const [
                    Icon(Icons.check_circle, size: 18, color: Colors.green),
                    Text('Enable'),
                  ],
                ),
              ),
            if (!admin.isSuperAdmin)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  spacing: 12,
                  children: const [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    Text('Delete'),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdminProfileScreen(adminId: admin.id),
            ),
          );
        },
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(AdminUser admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: admin.isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        admin.isActive ? 'Active' : 'Disabled',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: admin.isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  /// Handle admin action (view, permissions, disable, delete)
  void _handleAdminAction(
    BuildContext context,
    AdminUser admin,
    String action,
  ) {
    switch (action) {
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminProfileScreen(adminId: admin.id),
          ),
        );
        break;
      case 'permissions':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminPermissionsScreen(adminId: admin.id),
          ),
        );
        break;
      case 'disable':
        _showConfirmDialog(
          context,
          title: 'Disable Admin',
          message:
              'Are you sure you want to disable ${admin.displayName}? They will no longer be able to login.',
          onConfirm: () => _disableAdmin(admin),
        );
        break;
      case 'enable':
        _showConfirmDialog(
          context,
          title: 'Enable Admin',
          message: 'Are you sure you want to enable ${admin.displayName}?',
          onConfirm: () => _enableAdmin(admin),
        );
        break;
      case 'delete':
        _showConfirmDialog(
          context,
          title: 'Delete Admin',
          message:
              'Are you sure you want to permanently delete ${admin.displayName}? This action cannot be undone. Activity logs will be preserved for audit trail.',
          onConfirm: () => _deleteAdmin(admin),
          isDangerous: true,
        );
        break;
    }
  }

  /// Disable admin
  void _disableAdmin(AdminUser admin) {
    ref.read(disableAdminProvider(admin.id)).whenData((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${admin.displayName} has been disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  /// Enable admin
  void _enableAdmin(AdminUser admin) {
    ref.read(enableAdminProvider(admin.id)).whenData((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${admin.displayName} has been enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  /// Delete admin
  void _deleteAdmin(AdminUser admin) {
    ref.read(deleteAdminProvider(admin.id)).whenData((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${admin.displayName} has been deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Show confirmation dialog
  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : Colors.blue,
            ),
            child: Text(isDangerous ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}
