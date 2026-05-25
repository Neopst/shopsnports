import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../providers/super_admin_providers.dart';

/// Screen for super admin to view their own profile
/// - Shows admin details
/// - Shows permissions
/// - Shows activity logs
class SuperAdminMyProfileScreen extends ConsumerWidget {
  const SuperAdminMyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(currentUserAdminProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), elevation: 0),
      body: adminAsync.when(
        data: (admin) {
          if (admin == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No super admin profile found'),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact an administrator',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                // Profile header
                _buildProfileHeader(context, admin),

                const Divider(),

                // Account info
                _buildAccountInfo(admin),

                const SizedBox(height: 8),

                // Security section
                _buildSecuritySection(admin),

                const SizedBox(height: 8),

                // Permissions
                _buildPermissionsSection(context, admin),

                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(context),

                const SizedBox(height: 24),
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
              const Text('Error loading profile'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 16,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              (admin.displayName?.isNotEmpty ?? false)
                  ? admin.displayName![0].toUpperCase()
                  : admin.email[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  admin.displayName ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  admin.email,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    admin.role.name.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildAccountInfo(dynamic admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Text(
          'Account Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        _buildInfoRow('Email', admin.email),
        _buildInfoRow('Display Name', admin.displayName ?? 'Not set'),
        _buildInfoRow(
          'Status',
          admin.isActive ? 'Active' : 'Disabled',
          statusColor: admin.isActive ? Colors.green : Colors.red,
        ),
        _buildInfoRow(
          'Role',
          admin.role.name.replaceAll('_', ' ').toUpperCase(),
          statusColor: Colors.blue,
        ),
        _buildInfoRow('Created', _formatDateTime(admin.createdAt)),
        if (admin.lastLogin != null)
          _buildInfoRow('Last Login', _formatDateTime(admin.lastLogin!)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        if (statusColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          )
        else
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionsSection(BuildContext context, dynamic admin) {
    final accessibleModules = admin.permissions.getAccessibleModules();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Module Permissions (${accessibleModules.length}/${AdminModule.values.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (accessibleModules.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No module permissions granted',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          Column(
            children: accessibleModules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;

              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                module.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                module.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSecuritySection(dynamic admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Text(
          'Security',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            spacing: 12,
            children: [
              _buildSecurityRow(
                Icons.verified_user,
                'Email Verified',
                'Your email has been verified',
                true,
              ),
              _buildSecurityRow(
                Icons.security,
                'Two-Factor Authentication',
                admin.twoFactorEnabled ? 'Enabled' : 'Disabled',
                admin.twoFactorEnabled,
              ),
              _buildSecurityRow(
                Icons.lock,
                'Account Status',
                admin.isActive
                    ? 'Active - All access granted'
                    : 'Inactive - Limited access',
                admin.isActive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityRow(
    IconData icon,
    String label,
    String description,
    bool isEnabled,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isEnabled ? Colors.green : Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigate to edit profile')),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change form')),
            );
          },
          icon: const Icon(Icons.vpn_key),
          label: const Text('Change Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }
}
