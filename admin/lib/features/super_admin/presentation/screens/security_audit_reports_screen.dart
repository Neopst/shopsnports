import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SecurityAuditReportsScreen extends StatefulWidget {
  const SecurityAuditReportsScreen({super.key});

  @override
  State<SecurityAuditReportsScreen> createState() => _SecurityAuditReportsScreenState();
}

class _SecurityAuditReportsScreenState extends State<SecurityAuditReportsScreen> {
  String _selectedActionFilter = 'all';
  String _selectedUserFilter = 'all';
  DateTimeRange? _dateRange;
  bool _isLoading = false;
  List<Map<String, dynamic>> _filteredLogs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('admin_activity_logs')
          .orderBy('timestamp', descending: true);

      if (_dateRange != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange!.start));
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange!.end));
      }

      if (_selectedActionFilter != 'all') {
        query = query.where('action', isEqualTo: _selectedActionFilter);
      }

      if (_selectedUserFilter != 'all') {
        query = query.where('userId', isEqualTo: _selectedUserFilter);
      }

      final snapshot = await query.limit(1000).get();

      setState(() {
        _filteredLogs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audit logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export as JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          const Divider(height: 1),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildAuditLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalLogs = _filteredLogs.length;
    final criticalLogs = _filteredLogs.where((log) {
      final action = log['action'] as String?;
      return action != null && _isCriticalAction(action);
    }).length;
    final uniqueUsers = _filteredLogs.map((log) => log['userId'] as String?).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Logs',
              value: totalLogs.toString(),
              icon: Icons.description,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Critical Actions',
              value: criticalLogs.toString(),
              icon: Icons.warning,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Unique Users',
              value: uniqueUsers.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_dateRange != null)
            Chip(
              label: Text(
                'Date: ${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}',
              ),
              onDeleted: () {
                setState(() => _dateRange = null);
                _loadAuditLogs();
              },
            ),
          if (_selectedActionFilter != 'all')
            Chip(
              label: Text('Action: ${_formatAction(_selectedActionFilter)}'),
              onDeleted: () {
                setState(() => _selectedActionFilter = 'all');
                _loadAuditLogs();
              },
            ),
          if (_selectedUserFilter != 'all')
            Chip(
              label: Text('User: $_selectedUserFilter'),
              onDeleted: () {
                setState(() => _selectedUserFilter = 'all');
                _loadAuditLogs();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _AuditLogCard(log: log, index: index);
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Logs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Action Type:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Create', 'create'),
                  _buildFilterChip('Update', 'update'),
                  _buildFilterChip('Delete', 'delete'),
                  _buildFilterChip('Login', 'login'),
                  _buildFilterChip('Logout', 'logout'),
                  _buildFilterChip('Admin Created', 'admin_created'),
                  _buildFilterChip('Admin Deleted', 'admin_deleted'),
                  _buildFilterChip('Permission Changed', 'permission_changed'),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Date Range:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dateRange == null
                          ? 'Select Range'
                          : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'),
                      onPressed: _selectDateRange,
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _dateRange = null);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAuditLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedActionFilter == value,
      onSelected: (selected) {
        setState(() => _selectedActionFilter = value);
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _handleExport(String format) async {
    if (_filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String content;
      String mimeType;
      String fileName;

      if (format == 'csv') {
        content = _convertToCSV();
        mimeType = 'text/csv';
        fileName = 'security_audit_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      } else {
        content = _convertToJSON();
        mimeType = 'application/json';
        fileName = 'security_audit_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Security Audit Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported as $format')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _convertToCSV() {
    final headers = ['Timestamp', 'User Email', 'User Name', 'Action', 'Details', 'IP Address'];
    final rows = _filteredLogs.map((log) {
      final timestamp = log['timestamp'] as Timestamp?;
      return [
        timestamp != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp.toDate()) : '',
        log['userEmail'] ?? '',
        log['userDisplayName'] ?? '',
        log['action'] ?? '',
        _formatDetails(log['details'] as Map<String, dynamic>?),
        log['ipAddress'] ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  String _convertToJSON() {
    return const JsonEncoder.withIndent('  ').convert(_filteredLogs);
  }

  String _formatDetails(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return '';
    return details.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
  }

  String _formatAction(String action) {
    return action.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  bool _isCriticalAction(String action) {
    return ['delete', 'admin_created', 'admin_deleted', 'permission_changed']
        .contains(action.toLowerCase());
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final int index;

  const _AuditLogCard({required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? 'Unknown';
    final timestamp = log['timestamp'] as Timestamp?;
    final userEmail = log['userEmail'] as String? ?? 'Unknown';
    final userName = log['userDisplayName'] as String? ?? '';
    final details = log['details'] as Map<String, dynamic>? ?? {};
    final ipAddress = log['ipAddress'] as String?;

    final isCritical = _isCriticalAction(action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildActionIcon(action, isCritical),
        title: Text(
          _formatAction(action),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isCritical ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userEmail),
            if (userName.isNotEmpty) Text(userName),
          ],
        ),
        trailing: Text(
          timestamp != null
              ? _formatTimestamp(timestamp.toDate())
              : 'Unknown',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ipAddress != null) ...[
                  _buildDetailRow('IP Address', ipAddress),
                  const SizedBox(height: 8),
                ],
                if (details.isNotEmpty) ...[
                  const Text(
                    'Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...details.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildDetailRow(
                        entry.key,
                        entry.value.toString(),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String action, bool isCritical) {
    IconData icon;
    Color color;

    switch (action.toLowerCase()) {
      case 'create':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'update':
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case 'delete':
        icon = Icons.delete;
        color = Colors.red;
        break;
      case 'login':
        icon = Icons.login;
        color = Colors.purple;
        break;
      case 'logout':
        icon = Icons.logout;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  String _formatAction(String action) {
    return action.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MM/dd/yyyy HH:mm').format(timestamp);
    }
  }

  bool _isCriticalAction(String action) {
    return ['delete', 'admin_created', 'admin_deleted', 'permission_changed']
        .contains(action.toLowerCase());
  }
}