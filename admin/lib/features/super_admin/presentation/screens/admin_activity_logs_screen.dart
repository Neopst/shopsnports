import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_activity_log.dart';
import '../providers/super_admin_providers.dart';

/// Screen for monitoring admin activity logs
/// - Display all admin activities in real-time
/// - Filter by admin, action type, date range
/// - Sortable columns
/// - Search functionality
class AdminActivityLogsScreen extends ConsumerStatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  ConsumerState<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState
    extends ConsumerState<AdminActivityLogsScreen> {
  String? _selectedAdminId;
  String? _selectedAction;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(allActivityLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs'), elevation: 0),
      body: Column(
        children: [
          // Filter bar
          _buildFilterBar(context),
          // Activity logs table
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                // Apply filters
                var filtered = logs;

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where(
                        (log) =>
                            log.adminEmail.toLowerCase().contains(query) ||
                            log.itemName?.toLowerCase().contains(query) ==
                                true ||
                            log.action.displayName.toLowerCase().contains(
                              query,
                            ),
                      )
                      .toList();
                }

                if (_selectedAdminId != null) {
                  filtered = filtered
                      .where((log) => log.adminId == _selectedAdminId)
                      .toList();
                }

                if (_selectedAction != null) {
                  filtered = filtered
                      .where((log) => log.action.name == _selectedAction)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No activity logs found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return _buildActivityTable(filtered);
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
                      'Error loading activity logs',
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
    );
  }

  /// Build filter bar
  Widget _buildFilterBar(BuildContext context) {
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
              hintText: 'Search by email, item, or action...',
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
                FilterChip(
                  label: const Text('All Actions'),
                  selected: _selectedAction == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedAction = null;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Admin Actions'),
                  selected: _selectedAction == 'admin_management',
                  onSelected: (_) {
                    setState(() {
                      _selectedAction = 'admin_management';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Content Changes'),
                  selected: _selectedAction == 'content_management',
                  onSelected: (_) {
                    setState(() {
                      _selectedAction = 'content_management';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Login/Logout'),
                  selected: _selectedAction == 'auth',
                  onSelected: (_) {
                    setState(() {
                      _selectedAction = 'auth';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build activity logs table
  Widget _buildActivityTable(List<AdminActivityLog> logs) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 12,
        columns: const [
          DataColumn(
            label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: logs
            .map(
              (log) => DataRow(
                onSelectChanged: (_) => _showLogDetails(context, log),
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        Text(
                          log.adminEmail.split('@').first,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          log.adminEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getActionColor(log.action).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getActionColor(log.action),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      log.itemName ?? log.itemId ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      log.timeFormatted,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Icon(
                      (log.success ?? false)
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                      color: (log.success ?? false) ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  /// Get action color
  Color _getActionColor(AdminActivityAction action) {
    switch (action) {
      case AdminActivityAction.login:
      case AdminActivityAction.logout:
        return Colors.blue;
      case AdminActivityAction.created_admin:
      case AdminActivityAction.updated_admin_permissions:
      case AdminActivityAction.enabled_admin:
        return Colors.purple;
      case AdminActivityAction.disabled_admin:
      case AdminActivityAction.deleted_admin:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Show log details in bottom sheet
  void _showLogDetails(BuildContext context, AdminActivityLog log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Details',
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
              const Divider(),
              _buildDetailRow('Admin', log.adminEmail),
              _buildDetailRow('Action', log.action.displayName),
              if (log.itemId != null) _buildDetailRow('Item ID', log.itemId!),
              if (log.itemName != null)
                _buildDetailRow('Item Name', log.itemName!),
              _buildDetailRow('Time', log.timeFormatted),
              _buildDetailRow(
                'Status',
                (log.success ?? false) ? 'Success' : 'Failed',
                statusColor: (log.success ?? false) ? Colors.green : Colors.red,
              ),
              if ((log.details ?? {}).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Additional Details',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor?.withValues(alpha:0.1) ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
