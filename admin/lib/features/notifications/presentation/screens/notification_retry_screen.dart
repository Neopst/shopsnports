import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart' as models;
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_firestore.dart';
import '../../services/notification_retry_service.dart';

/// Screen for managing failed notifications and retry operations
class NotificationRetryScreen extends ConsumerStatefulWidget {
  const NotificationRetryScreen({super.key});

  @override
  ConsumerState<NotificationRetryScreen> createState() =>
      _NotificationRetryScreenState();
}

class _NotificationRetryScreenState
    extends ConsumerState<NotificationRetryScreen> {
  final NotificationRetryService _retryService = NotificationRetryService(
    repository: NotificationRepositoryFirestore(),
  );

  List<models.Notification> _failedNotifications = [];
  Map<String, dynamic> _retryStats = {};
  bool _isLoading = true;
  String? _selectedNotificationId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _retryService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final failed = await _retryService.getRetryableNotifications();
      setState(() {
        _failedNotifications = failed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading failed notifications: $e')),
        );
      }
    }
  }

  Future<void> _loadRetryStats(String notificationId) async {
    final stats = await _retryService.getRetryStats(notificationId);
    setState(() {
      _retryStats = stats;
      _selectedNotificationId = notificationId;
    });
  }

  Future<void> _manualRetry(String notificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Notification'),
        content: const Text(
          'Are you sure you want to retry this notification immediately?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _retryService.manualRetry(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Notification retried successfully' : 'Retry failed',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      await _loadData();
    }
  }

  Future<void> _cancelRetry(String notificationId) async {
    _retryService.cancelRetry(notificationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retry cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Retry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _failedNotifications.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Failed Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('All notifications are delivered successfully'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildStatsCard(),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _failedNotifications.length,
            itemBuilder: (context, index) {
              final notification = _failedNotifications[index];
              final isSelected = _selectedNotificationId == notification.id;
              return _buildNotificationCard(notification, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Failed',
            _failedNotifications.length.toString(),
            Icons.error_outline,
            Colors.red,
          ),
          _buildStatItem(
            'Active Retries',
            _retryService.activeRetryCount.toString(),
            Icons.sync,
            Colors.orange,
          ),
          _buildStatItem(
            'Max Retries',
            '3',
            Icons.repeat,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(models.Notification notification, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Retry count: ${notification.retryCount} | ${_formatDate(notification.createdAt)}',
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _manualRetry(notification.id),
              tooltip: 'Retry Now',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _loadRetryStats(notification.id),
              tooltip: 'View Stats',
            ),
          ],
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadRetryStats(notification.id);
          }
        },
        children: [
          if (isSelected && _retryStats.isNotEmpty)
            _buildRetryStats(notification.id),
          _buildNotificationDetails(notification),
        ],
      ),
    );
  }

  Widget _buildRetryStats(String notificationId) {
    final retryCount = _retryStats['retryCount'] ?? 0;
    final maxRetries = _retryStats['maxRetries'] ?? 3;
    final canRetry = _retryStats['canRetry'] ?? false;
    final lastRetryAt = _retryStats['lastRetryAt'];
    final nextRetryIn = _retryStats['nextRetryIn'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retry Statistics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Retry Count', '$retryCount / $maxRetries'),
          _buildStatRow('Can Retry', canRetry ? 'Yes' : 'No'),
          if (lastRetryAt != null)
            _buildStatRow('Last Retry', _formatDate(lastRetryAt)),
          if (nextRetryIn != null)
            _buildStatRow('Next Retry In', _formatDuration(nextRetryIn)),
          const SizedBox(height: 12),
          if (canRetry)
            ElevatedButton.icon(
              onPressed: () => _manualRetry(notificationId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDetails(models.Notification notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Type', notification.type.displayName),
          _buildDetailRow('Category', notification.category.displayName),
          _buildDetailRow('Status', notification.status.displayName),
          if (notification.errorMessage != null)
            _buildDetailRow('Error', notification.errorMessage!),
          _buildDetailRow('Created', _formatDate(notification.createdAt)),
          if (notification.sentAt != null)
            _buildDetailRow('Sent', _formatDate(notification.sentAt!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                color: Colors.grey.shade700,
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}