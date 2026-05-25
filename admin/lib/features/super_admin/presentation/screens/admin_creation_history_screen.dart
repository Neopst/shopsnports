import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_activity_log.dart';
import '../../data/models/admin_user.dart';
import '../providers/super_admin_providers.dart';

/// Screen for viewing admin creation history
/// Shows all admins created by the current super admin
/// with detailed information about each creation
class AdminCreationHistoryScreen extends ConsumerStatefulWidget {
  const AdminCreationHistoryScreen({super.key});

  @override
  ConsumerState<AdminCreationHistoryScreen> createState() =>
      _AdminCreationHistoryScreenState();
}

class _AdminCreationHistoryScreenState
    extends ConsumerState<AdminCreationHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(allActivityLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Creation History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allActivityLogsStreamProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          // Filter for admin creation actions only
          final creationLogs = logs
              .where((log) => log.action == AdminActivityAction.created_admin)
              .toList();

          if (creationLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No admins created yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first admin to see history here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: creationLogs.length,
            itemBuilder: (context, index) {
              final log = creationLogs[index];
              return _buildCreationCard(context, log);
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
                'Error loading history',
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
    );
  }

  /// Build creation card
  Widget _buildCreationCard(BuildContext context, AdminActivityLog log) {
    final details = log.details ?? {};
    final email = details['email'] as String? ?? 'Unknown';
    final role = details['role'] as String? ?? 'admin';
    final permissions = details['permissions'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showCreationDetails(context, log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              // Header
              Row(
                spacing: 12,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          log.itemName ?? 'Unknown Admin',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: role == 'super_admin'
                          ? Colors.purple.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role == 'super_admin'
                          ? 'Super Admin'
                          : role == 'admin'
                              ? 'Admin'
                              : 'Sub-Admin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: role == 'super_admin'
                            ? Colors.purple.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              // Permissions summary
              if (permissions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Icon(
                            Icons.security,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          Text(
                            'Permissions Granted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: permissions.entries
                            .where((entry) => entry.value == true)
                            .map((entry) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatModuleName(entry.key),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              // Footer
              Row(
                spacing: 8,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  Text(
                    log.timeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show creation details in bottom sheet
  void _showCreationDetails(BuildContext context, AdminActivityLog log) {
    final details = log.details ?? {};
    final email = details['email'] as String? ?? 'Unknown';
    final role = details['role'] as String? ?? 'admin';
    final permissions = details['permissions'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creation Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Admin info
                    _buildDetailSection(
                      'Admin Information',
                      [
                        _buildDetailRow('Name', log.itemName ?? 'Unknown'),
                        _buildDetailRow('Email', email),
                        _buildDetailRow(
                          'Role',
                          role == 'super_admin'
                              ? 'Super Admin'
                              : role == 'admin'
                                  ? 'Admin'
                                  : 'Sub-Admin',
                          statusColor: role == 'super_admin'
                              ? Colors.purple
                              : Colors.green,
                        ),
                        _buildDetailRow('Created By', log.adminEmail),
                        _buildDetailRow('Created At', log.timeFormatted),
                      ],
                    ),
                    // Permissions
                    if (permissions.isNotEmpty)
                      _buildDetailSection(
                        'Module Permissions',
                        [
                          ...permissions.entries
                              .where((entry) => entry.value == true)
                              .map((entry) => _buildDetailRow(
                                    _formatModuleName(entry.key),
                                    'Granted',
                                    statusColor: Colors.green,
                                  )),
                        ],
                      ),
                    // Raw details
                    if ((log.details ?? {}).isNotEmpty)
                      _buildDetailSection(
                        'Raw Details',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.details.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail section
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format module name for display
  String _formatModuleName(String moduleName) {
    return moduleName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}