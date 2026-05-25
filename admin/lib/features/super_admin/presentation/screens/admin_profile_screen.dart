import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../../data/models/admin_user.dart';
import '../providers/super_admin_providers.dart';

/// Screen for viewing and editing admin profile
/// - All admins can view their own profile
/// - Super admins can view any admin's profile
/// - Super admins can manage other admin's permissions and status
class AdminProfileScreen extends ConsumerWidget {
  final String adminId;

  const AdminProfileScreen({required this.adminId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminByIdProvider(adminId));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile'), elevation: 0),
      body: adminAsync.when(
        data: (admin) {
          if (admin == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Admin not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                _buildProfileHeader(context, admin),
                const SizedBox(height: 32),

                // Account information section
                _buildSection(
                  context,
                  title: 'Account Information',
                  children: [
                    _buildInfoTile(
                      label: 'Email',
                      value: admin.email,
                      icon: Icons.email,
                    ),
                    _buildInfoTile(
                      label: 'Display Name',
                      value: admin.displayName,
                      icon: Icons.person,
                    ),
                    _buildInfoTile(
                      label: 'Role',
                      value: admin.isSuperAdmin ? 'Super Admin' : 'Admin',
                      icon: Icons.admin_panel_settings,
                      color: admin.isSuperAdmin ? Colors.purple : Colors.blue,
                    ),
                    _buildInfoTile(
                      label: 'Status',
                      value: admin.isActive ? 'Active' : 'Disabled',
                      icon: admin.isActive ? Icons.check_circle : Icons.cancel,
                      color: admin.isActive ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Activity information section
                _buildSection(
                  context,
                  title: 'Activity',
                  children: [
                    _buildInfoTile(
                      label: 'Created At',
                      value: _formatDateTime(admin.createdAt),
                      icon: Icons.calendar_today,
                    ),
                    if (admin.createdBy != null)
                      _buildCreatedByTile(
                        context,
                        ref,
                        createdBy: admin.createdBy!,
                      ),
                    _buildInfoTile(
                      label: 'Last Login',
                      value: admin.lastLoginFormatted ?? 'Never',
                      icon: Icons.login,
                    ),
                    if (admin.requirePasswordChange)
                      _buildWarningTile(
                        label: 'Password Change Required',
                        message:
                            'This admin must change password on next login',
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Permissions section
                _buildSection(
                  context,
                  title: 'Module Permissions',
                  children: [_buildPermissionsList(admin)],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build profile header with avatar and name
  Widget _buildProfileHeader(BuildContext context, AdminUser admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: admin.isSuperAdmin ? Colors.purple : Colors.blue,
            child: Text(
              admin.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: admin.isActive
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    admin.isActive ? 'Active' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: admin.isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section container
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Build an information tile
  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build "created by" tile with admin details
  Widget _buildCreatedByTile(
    BuildContext context,
    WidgetRef ref, {
    required String createdBy,
  }) {
    final creatorAsync = ref.watch(adminByIdProvider(createdBy));

    return creatorAsync.when(
      data: (creator) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.person_add, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Created By',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creator?.displayName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading creator...'),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.error_outline, size: 20, color: Colors.red),
            SizedBox(width: 12),
            Text('Error loading creator'),
          ],
        ),
      ),
    );
  }

  /// Build warning tile
  Widget _buildWarningTile({required String label, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
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

  /// Build permissions list
  Widget _buildPermissionsList(AdminUser admin) {
    if (admin.permissions.getAccessibleModules().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            admin.isSuperAdmin
                ? 'Super Admin has access to all modules'
                : 'No module access granted',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: admin.permissions.getAccessibleModules().asMap().entries.map((
        entry,
      ) {
        final index = entry.key;
        final module = entry.value;

        return Column(
          children: [
            if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Module access granted',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
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
      }).toList(),
    );
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
