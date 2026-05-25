import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../providers/super_admin_providers.dart';

/// Screen for managing admin module permissions
/// - Display all 10 modules with checkboxes
/// - Super admin permissions cannot be modified
/// - Save changes to Firestore
class AdminPermissionsScreen extends ConsumerStatefulWidget {
  final String adminId;

  const AdminPermissionsScreen({
    required this.adminId,
    super.key,
  });

  @override
  ConsumerState<AdminPermissionsScreen> createState() =>
      _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState
    extends ConsumerState<AdminPermissionsScreen> {
  late Map<String, bool> _permissions;
  bool _isLoading = false;
  bool _hasChanges = false;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _permissions = AdminPermissions.defaultPermissions().permissions;
  }

  void _onPermissionChanged(String module, bool value) {
    setState(() {
      _permissions[module] = value;
      _hasChanges = true;
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(superAdminRepositoryProvider);
      await repo.updateAdminPermissions(
        adminId: widget.adminId,
        permissions: _permissions,
      );

      // Log activity
      try {
        await repo.logAdminActivity(
          adminId: widget.adminId,
          action: 'updated_admin_permissions',
          itemId: widget.adminId,
          itemName: _adminName,
          details: {'permissions': _permissions},
        );
      } catch (_) {
        // Activity logging is non-critical
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(adminByIdProvider(widget.adminId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Permissions'),
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading ? null : _savePermissions,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: adminAsync.when(
        data: (admin) {
          if (admin == null) {
            return const Center(child: Text('Admin not found'));
          }

          _adminName = admin.displayName;

          // Initialize permissions from admin if not done
          if (!_hasChanges && admin.permissions.permissions.isNotEmpty) {
            _permissions = Map<String, bool>.from(admin.permissions.permissions);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                // Admin info header
                _buildAdminHeader(admin),
                const SizedBox(height: 16),

                // Permissions info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toggle module access for this admin. Changes are saved immediately.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Permissions list
                _buildPermissionsList(admin),

                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Modules Granted'),
                      Text(
                        '${_permissions.values.where((v) => v).length} / ${AdminModule.values.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildAdminHeader(dynamic admin) {
    final isSuperAdmin = admin.role.name == 'super_admin';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border.all(color: Colors.purple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple,
            child: Text(
              admin.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  admin.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isSuperAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Super Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList(dynamic admin) {
    final isSuperAdmin = admin.role.name == 'super_admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: AdminModule.values.asMap().entries.map((entry) {
        final index = entry.key;
        final module = entry.value;
        final isEnabled = _permissions[module.name] ?? false;

        return Column(
          children: [
            if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
            SwitchListTile(
              value: isEnabled,
              onChanged: isSuperAdmin
                  ? null
                  : (value) => _onPermissionChanged(module.name, value),
              title: Text(
                module.displayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                module.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getModuleIcon(module),
                  color: isEnabled ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
            ),
            if (isSuperAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Super admin permissions cannot be modified',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  IconData _getModuleIcon(AdminModule module) {
    switch (module) {
      case AdminModule.news_ticker:
        return Icons.newspaper;
      case AdminModule.content_management:
        return Icons.content_copy;
      case AdminModule.invoices:
        return Icons.receipt;
      case AdminModule.shipping:
        return Icons.airplanemode_active;
      case AdminModule.customers:
        return Icons.people;
      case AdminModule.affiliates:
        return Icons.handshake;
      case AdminModule.payouts:
        return Icons.account_balance_wallet;
      case AdminModule.notifications:
        return Icons.notifications;
      case AdminModule.push_notifications:
        return Icons.notifications_active;
      case AdminModule.settings:
        return Icons.settings;
    }
  }
}