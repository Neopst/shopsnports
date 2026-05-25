import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/invoice_reminder.dart';
import '../../data/repositories/invoice_reminder_repository.dart';

/// Screen for managing invoice reminders
class InvoiceRemindersScreen extends ConsumerStatefulWidget {
  const InvoiceRemindersScreen({super.key});

  @override
  ConsumerState<InvoiceRemindersScreen> createState() =>
      _InvoiceRemindersScreenState();
}

class _InvoiceRemindersScreenState extends ConsumerState<InvoiceRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvoiceReminderRepository _repository = InvoiceReminderRepository();

  List<InvoiceReminder> _allReminders = [];
  List<InvoiceReminder> _pendingReminders = [];
  List<InvoiceReminder> _sentReminders = [];
  List<InvoiceReminder> _failedReminders = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _repository.getAll(limit: 100),
        _repository.getPendingReminders(),
        _repository.getFailedReminders(),
        _repository.getStatistics(),
      ]);

      setState(() {
        _allReminders = results[0] as List<InvoiceReminder>;
        _pendingReminders = results[1] as List<InvoiceReminder>;
        _failedReminders = results[2] as List<InvoiceReminder>;
        _sentReminders = _allReminders
            .where((r) => r.status == ReminderStatus.sent)
            .toList();
        _statistics = results[3] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }

  Future<void> _cancelReminder(String reminderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reminder'),
        content: const Text('Are you sure you want to cancel this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.cancel(reminderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder cancelled')),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling reminder: $e')),
          );
        }
      }
    }
  }

  Future<void> _retryReminder(String reminderId) async {
    try {
      await _repository.retry(reminderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder retried')),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrying reminder: $e')),
        );
      }
    }
  }

  void _showReminderDetails(InvoiceReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => _ReminderDetailsDialog(reminder: reminder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Sent'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatisticsCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReminderList(_allReminders),
                      _buildReminderList(_pendingReminders),
                      _buildReminderList(_sentReminders),
                      _buildReminderList(_failedReminders),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _statistics['total']?.toString() ?? '0',
              Icons.notifications, Colors.blue),
          _buildStatItem('Pending', _statistics['pending']?.toString() ?? '0',
              Icons.pending, Colors.orange),
          _buildStatItem('Sent', _statistics['sent']?.toString() ?? '0',
              Icons.check_circle, Colors.green),
          _buildStatItem('Failed', _statistics['failed']?.toString() ?? '0',
              Icons.error, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReminderList(List<InvoiceReminder> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No reminders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(InvoiceReminder reminder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.status.color,
          child: Text(
            reminder.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          reminder.subject ?? reminder.type.defaultSubject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.customerName),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(reminder.status),
                const SizedBox(width: 8),
                _buildTypeChip(reminder.type),
                const SizedBox(width: 8),
                if (reminder.isOverdue)
                  const Chip(
                    label: Text('Overdue'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reminder.status == ReminderStatus.pending)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cancelReminder(reminder.id),
                tooltip: 'Cancel',
              ),
            if (reminder.canRetry)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _retryReminder(reminder.id),
                tooltip: 'Retry',
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showReminderDetails(reminder),
              tooltip: 'Details',
            ),
          ],
        ),
        onTap: () => _showReminderDetails(reminder),
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    return Chip(
      label: Text(status.displayName),
      backgroundColor: status.color.withOpacity(0.2),
      labelStyle: TextStyle(color: status.color),
    );
  }

  Widget _buildTypeChip(ReminderType type) {
    return Chip(
      label: Text(type.displayName),
      avatar: Text(type.icon),
    );
  }
}

class _ReminderDetailsDialog extends StatelessWidget {
  final InvoiceReminder reminder;

  const _ReminderDetailsDialog({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(reminder.type.icon),
          const SizedBox(width: 8),
          const Text('Reminder Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', reminder.type.displayName),
            _buildDetailRow('Status', reminder.status.displayName),
            _buildDetailRow('Customer', reminder.customerName),
            _buildDetailRow('Email', reminder.customerEmail),
            _buildDetailRow('Invoice ID', reminder.invoiceId),
            _buildDetailRow('Subject', reminder.subject ?? 'N/A'),
            _buildDetailRow('Scheduled', _formatDate(reminder.scheduledDate)),
            if (reminder.sentDate != null)
              _buildDetailRow('Sent', _formatDate(reminder.sentDate!)),
            _buildDetailRow('Attempts', '${reminder.attemptCount}'),
            if (reminder.lastAttemptAt != null)
              _buildDetailRow('Last Attempt', _formatDate(reminder.lastAttemptAt!)),
            if (reminder.errorMessage != null)
              _buildDetailRow('Error', reminder.errorMessage!),
            _buildDetailRow('Created', _formatDate(reminder.createdAt)),
            const SizedBox(height: 16),
            const Text(
              'Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(reminder.message ?? reminder.type.defaultMessage),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}