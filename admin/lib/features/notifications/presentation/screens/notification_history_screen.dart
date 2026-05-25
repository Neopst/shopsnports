import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_history.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_type.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_category.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_priority.dart';
import 'package:admin_dashboard/features/notifications/data/repositories/notification_history_repository.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  final _repository = NotificationHistoryRepository();
  final _searchController = TextEditingController();
  DeliveryStatus? _selectedStatus;
  NotificationType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics cards
          _buildStatisticsSection(),
          const SizedBox(height: 16),
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),
          // History list
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return StreamBuilder<Map<String, int>>(
      stream: _repository.getStatisticsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final total = stats['total'] ?? 0;
        final delivered = stats['delivered'] ?? 0;
        final opened = stats['opened'] ?? 0;
        final failed = stats['failed'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('Total', total, Icons.notifications, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('Delivered', delivered, Icons.check_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('Opened', opened, Icons.visibility, Colors.purple),
                  const SizedBox(width: 12),
                  _buildStatCard('Failed', failed, Icons.error, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          if (_selectedStatus != null ||
              _selectedType != null ||
              _startDate != null ||
              _endDate != null)
            Chip(
              label: const Text('Filters Active'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedType = null;
                  _startDate = null;
                  _endDate = null;
                });
              },
              backgroundColor: Colors.blue[100],
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<NotificationHistory>>(
      future: _fetchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No notification history found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildHistoryItem(item);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(NotificationHistory item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.deliveryStatus.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.deliveryStatus.icon,
                      color: item.deliveryStatus.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.deliveryStatus.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.deliveryStatus.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.deliveryStatus.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  Text(
                    _formatDateTime(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Error message if failed
              if (item.deliveryError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.deliveryError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Tracking info
              if (item.sentAt != null ||
                  item.deliveredAt != null ||
                  item.openedAt != null ||
                  item.clickedAt != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.sentAt != null)
                      _buildTrackingChip('Sent', item.sentAt!),
                    if (item.deliveredAt != null)
                      _buildTrackingChip('Delivered', item.deliveredAt!),
                    if (item.openedAt != null)
                      _buildTrackingChip('Opened', item.openedAt!),
                    if (item.clickedAt != null)
                      _buildTrackingChip('Clicked', item.clickedAt!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingChip(String label, DateTime dateTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: ${_formatTime(dateTime)}',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  void _showDetailDialog(NotificationHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(item.deliveryStatus.icon, color: item.deliveryStatus.color),
            const SizedBox(width: 8),
            const Text('Notification Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', item.id),
              _buildDetailRow('Title', item.title),
              _buildDetailRow('Message', item.message),
              _buildDetailRow('Type', item.type.displayName),
              _buildDetailRow('Category', item.category.displayName),
              _buildDetailRow('Priority', item.priority.displayName),
              _buildDetailRow('Status', item.deliveryStatus.displayName),
              _buildDetailRow('User ID', item.userId),
              if (item.actionUrl != null)
                _buildDetailRow('Action URL', item.actionUrl!),
              _buildDetailRow('Created', _formatDateTime(item.createdAt)),
              if (item.sentAt != null)
                _buildDetailRow('Sent', _formatDateTime(item.sentAt!)),
              if (item.deliveredAt != null)
                _buildDetailRow('Delivered', _formatDateTime(item.deliveredAt!)),
              if (item.openedAt != null)
                _buildDetailRow('Opened', _formatDateTime(item.openedAt!)),
              if (item.clickedAt != null)
                _buildDetailRow('Clicked', _formatDateTime(item.clickedAt!)),
              if (item.deliveryError != null)
                _buildDetailRow('Error', item.deliveryError!, isError: true),
              if (item.metadata != null && item.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadata',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...item.metadata!.entries.map(
                  (e) => _buildDetailRow(e.key, e.value.toString()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item.deliveryStatus == DeliveryStatus.failed)
            ElevatedButton(
              onPressed: () => _retryNotification(item),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isError ? Colors.red : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DeliveryStatus.values.map((status) {
                  return FilterChip(
                    label: Text(status.displayName),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Notification Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: NotificationType.values.map((type) {
                  return FilterChip(
                    label: Text(type.displayName),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? _formatDate(_startDate!)
                            : 'Start Date',
                      ),
                      onPressed: () => _selectStartDate(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null ? _formatDate(_endDate!) : 'End Date',
                      ),
                      onPressed: () => _selectEndDate(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedType = null;
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<List<NotificationHistory>> _fetchHistory() async {
    if (_searchController.text.isNotEmpty) {
      return await _repository.search(_searchController.text);
    }

    if (_selectedStatus != null) {
      return await _repository.getByDeliveryStatus(_selectedStatus!);
    }

    if (_selectedType != null) {
      return await _repository.getByType(_selectedType!);
    }

    if (_startDate != null && _endDate != null) {
      return await _repository.getByDateRange(_startDate!, _endDate!);
    }

    return await _repository.getAll();
  }

  Future<void> _retryNotification(NotificationHistory item) async {
    // TODO: Implement retry logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}