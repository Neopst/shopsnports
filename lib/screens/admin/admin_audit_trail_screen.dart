import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAuditTrailScreen extends ConsumerStatefulWidget {
  const AdminAuditTrailScreen({super.key});

  @override
  ConsumerState<AdminAuditTrailScreen> createState() =>
      _AdminAuditTrailScreenState();
}

class _AdminAuditTrailScreenState extends ConsumerState<AdminAuditTrailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedEntityType;
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildAuditTrailList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedEntityType != null)
              Chip(
                label: Text('Type: $_selectedEntityType'),
                onDeleted: () => setState(() => _selectedEntityType = null),
              ),
            if (_selectedAction != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Action: $_selectedAction'),
                onDeleted: () => setState(() => _selectedAction = null),
              ),
            ],
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '${_startDate != null ? DateFormat('MM/dd').format(_startDate!) : ''}'
                  ' - '
                  '${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : ''}',
                ),
                onDeleted: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailList() {
    Query query = _firestore
        .collection('audit_trail')
        .orderBy('timestamp', descending: true);

    if (_selectedEntityType != null) {
      query = query.where('entityType', isEqualTo: _selectedEntityType);
    }

    if (_selectedAction != null) {
      query = query.where('action', isEqualTo: _selectedAction);
    }

    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final entries = snapshot.data?.docs ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No audit entries found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final doc = entries[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildAuditEntryCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildAuditEntryCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final entityType = data['entityType'] as String? ?? 'unknown';
    final action = data['action'] as String? ?? 'unknown';
    final performedBy = data['performedBy'] as String? ?? 'system';
    final performedByRole = data['performedByRole'] as String? ?? 'system';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(action),
          child: Icon(
            _getActionIcon(action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${entityType.toUpperCase()} - ${action.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${data['entityId'] ?? doc.id.substring(0, 10)}'),
            Text('By: $performedBy ($performedByRole)'),
            Text(_formatTimestamp(data['timestamp'])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Entity Type', entityType.toUpperCase()),
                _buildDetailRow('Action', action.toUpperCase()),
                _buildDetailRow('Entity ID', data['entityId'] ?? 'N/A'),
                _buildDetailRow('Performed By', performedBy),
                _buildDetailRow('Role', performedByRole),
                _buildDetailRow('Timestamp', _formatTimestamp(data['timestamp'])),
                if (data['ipAddress'] != null)
                  _buildDetailRow('IP Address', data['ipAddress']),
                if (data['changes'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildChangesList(data['changes'] as Map<String, dynamic>?),
                ],
                if (data['metadata'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Metadata:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataList(data['metadata'] as Map<String, dynamic>?),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesList(Map<String, dynamic>? changes) {
    if (changes == null || changes.isEmpty) {
      return const Text('No changes recorded');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes.entries.map((entry) {
        final change = entry.value as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(
                  '${change['oldValue'] ?? 'N/A'} → ${change['newValue'] ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataList(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return const Text('No metadata');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadata.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      case 'status_changed':
        return Colors.orange;
      case 'processed':
        return Colors.purple;
      case 'approved':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add;
      case 'updated':
        return Icons.edit;
      case 'deleted':
        return Icons.delete;
      case 'status_changed':
        return Icons.sync_alt;
      case 'processed':
        return Icons.check_circle;
      case 'approved':
        return Icons.thumb_up;
      case 'rejected':
        return Icons.thumb_down;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> _showFilterDialog() async {
    final entityTypeController = TextEditingController(text: _selectedEntityType ?? '');
    final actionController = TextEditingController(text: _selectedAction ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Trail'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entity Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEntityType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'payout', child: Text('Payout')),
                  DropdownMenuItem(value: 'commission', child: Text('Commission')),
                  DropdownMenuItem(value: 'affiliate', child: Text('Affiliate')),
                  DropdownMenuItem(value: 'payment_settings', child: Text('Payment Settings')),
                  DropdownMenuItem(value: 'payout_schedule', child: Text('Payout Schedule')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() => _selectedEntityType = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Action'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'created', child: Text('Created')),
                  DropdownMenuItem(value: 'updated', child: Text('Updated')),
                  DropdownMenuItem(value: 'deleted', child: Text('Deleted')),
                  DropdownMenuItem(value: 'status_changed', child: Text('Status Changed')),
                  DropdownMenuItem(value: 'processed', child: Text('Processed')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  setState(() => _selectedAction = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? DateFormat('MM/dd').format(_startDate!)
                          : 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? DateFormat('MM/dd').format(_endDate!)
                          : 'End Date'),
                    ),
                  ),
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
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }
}