import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/notifications/data/models/scheduled_notification.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_type.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_category.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_priority.dart';
import 'package:admin_dashboard/features/notifications/data/repositories/scheduled_notification_repository.dart';

class ScheduledNotificationsScreen extends ConsumerStatefulWidget {
  const ScheduledNotificationsScreen({super.key});

  @override
  ConsumerState<ScheduledNotificationsScreen> createState() =>
      _ScheduledNotificationsScreenState();
}

class _ScheduledNotificationsScreenState
    extends ConsumerState<ScheduledNotificationsScreen> {
  final _repository = ScheduledNotificationRepository();
  final _searchController = TextEditingController();
  ScheduleStatus? _selectedStatus;
  ScheduleFrequency? _selectedFrequency;

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
        title: const Text('Scheduled Notifications'),
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
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),
          // Scheduled notifications list
          Expanded(
            child: _buildScheduledList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Schedule Notification'),
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
                hintText: 'Search scheduled notifications...',
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
          if (_selectedStatus != null || _selectedFrequency != null)
            Chip(
              label: const Text('Filters Active'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedFrequency = null;
                });
              },
              backgroundColor: Colors.blue[100],
            ),
        ],
      ),
    );
  }

  Widget _buildScheduledList() {
    return FutureBuilder<List<ScheduledNotification>>(
      future: _fetchScheduledNotifications(),
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

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No scheduled notifications',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Schedule Notification'),
                  onPressed: () => _showScheduleDialog(),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildScheduledCard(notification);
          },
        );
      },
    );
  }

  Widget _buildScheduledCard(ScheduledNotification notification) {
    final isOverdue = notification.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(notification),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isOverdue ? Colors.red : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
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
                        color: notification.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        notification.status.icon,
                        color: notification.status.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                notification.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (notification.isRecurring) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Recurring',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                                  color: notification.status.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  notification.status.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: notification.status.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                notification.frequency.displayName,
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
                    // Actions
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleMenuAction(action, notification),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (notification.status == ScheduleStatus.pending)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel'),
                              ],
                            ),
                          ),
                        if (notification.status == ScheduleStatus.failed && notification.canRetry)
                          const PopupMenuItem(
                            value: 'retry',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 18),
                                SizedBox(width: 8),
                                Text('Retry'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  notification.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Scheduled time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${_formatDateTime(notification.scheduledFor)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (notification.recurringUntil != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Until: ${_formatDate(notification.recurringUntil!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                // Error message if failed
                if (notification.errorMessage != null)
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
                            notification.errorMessage!,
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
            ),
          ),
        ),
      ),
    );
  }

  void _showScheduleDialog({ScheduledNotification? notification}) {
    final nameController = TextEditingController(text: notification?.name ?? '');
    final descriptionController =
        TextEditingController(text: notification?.description ?? '');
    final titleController = TextEditingController(text: notification?.title ?? '');
    final messageController = TextEditingController(text: notification?.message ?? '');
    final actionUrlController =
        TextEditingController(text: notification?.actionUrl ?? '');

    NotificationType selectedType = notification?.type ?? NotificationType.system;
    NotificationCategory selectedCategory =
        notification?.category ?? NotificationCategory.system;
    NotificationPriority selectedPriority =
        notification?.priority ?? NotificationPriority.normal;
    ScheduleFrequency selectedFrequency =
        notification?.frequency ?? ScheduleFrequency.once;
    DateTime? scheduledFor = notification?.scheduledFor;
    DateTime? recurringUntil = notification?.recurringUntil;
    int? recurringInterval = notification?.recurringInterval;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(notification == null ? 'Schedule Notification' : 'Edit Schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NotificationType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: NotificationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NotificationCategory>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: NotificationCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NotificationPriority>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: NotificationPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPriority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: actionUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Action URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ScheduleFrequency>(
                    value: selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: ScheduleFrequency.values.map((frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedFrequency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: scheduledFor ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => scheduledFor = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Scheduled For',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        scheduledFor != null
                            ? _formatDateTime(scheduledFor!)
                            : 'Select date and time',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedFrequency != ScheduleFrequency.once) ...[
                    TextField(
                      controller: TextEditingController(text: recurringInterval?.toString()),
                      decoration: const InputDecoration(
                        labelText: 'Recurring Interval (days)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        recurringInterval = int.tryParse(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: recurringUntil ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => recurringUntil = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Recurring Until (optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          recurringUntil != null
                              ? _formatDate(recurringUntil!)
                              : 'No end date',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      titleController.text.isEmpty ||
                      messageController.text.isEmpty ||
                      scheduledFor == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in required fields')),
                    );
                    return;
                  }

                  try {
                    final newNotification = ScheduledNotification(
                      id: notification?.id ??
                          'sched_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      description: descriptionController.text,
                      type: selectedType,
                      category: selectedCategory,
                      title: titleController.text,
                      message: messageController.text,
                      actionUrl: actionUrlController.text.isEmpty
                          ? null
                          : actionUrlController.text,
                      priority: selectedPriority,
                      status: notification?.status ?? ScheduleStatus.pending,
                      frequency: selectedFrequency,
                      scheduledFor: scheduledFor!,
                      recurringUntil: recurringUntil,
                      recurringInterval: recurringInterval,
                      createdAt: notification?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (notification == null) {
                      await _repository.create(newNotification);
                    } else {
                      await _repository.update(newNotification);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              notification == null
                                  ? 'Notification scheduled'
                                  : 'Schedule updated'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetailDialog(ScheduledNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.status.icon, color: notification.status.color),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', notification.id),
              _buildDetailRow('Description', notification.description),
              _buildDetailRow('Type', notification.type.displayName),
              _buildDetailRow('Category', notification.category.displayName),
              _buildDetailRow('Priority', notification.priority.displayName),
              _buildDetailRow('Status', notification.status.displayName),
              _buildDetailRow('Frequency', notification.frequency.displayName),
              _buildDetailRow('Scheduled For', _formatDateTime(notification.scheduledFor)),
              if (notification.recurringUntil != null)
                _buildDetailRow('Recurring Until', _formatDate(notification.recurringUntil!)),
              if (notification.recurringInterval != null)
                _buildDetailRow('Interval', '${notification.recurringInterval} days'),
              _buildDetailRow('Created', _formatDateTime(notification.createdAt)),
              if (notification.sentAt != null)
                _buildDetailRow('Sent At', _formatDateTime(notification.sentAt!)),
              if (notification.errorMessage != null)
                _buildDetailRow('Error', notification.errorMessage!, isError: true),
              if (notification.retryCount > 0)
                _buildDetailRow('Retries', '${notification.retryCount}/${notification.maxRetries}'),
              const SizedBox(height: 16),
              const Text(
                'Notification Content',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(notification.message),
                  ],
                ),
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
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Scheduled Notifications'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ScheduleStatus.values.map((status) {
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
              const Text('Frequency'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ScheduleFrequency.values.map((frequency) {
                  return FilterChip(
                    label: Text(frequency.displayName),
                    selected: _selectedFrequency == frequency,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFrequency = selected ? frequency : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedFrequency = null;
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

  void _handleMenuAction(String action, ScheduledNotification notification) {
    switch (action) {
      case 'view':
        _showDetailDialog(notification);
        break;
      case 'edit':
        _showScheduleDialog(notification: notification);
        break;
      case 'cancel':
        _cancelNotification(notification);
        break;
      case 'retry':
        _retryNotification(notification);
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  Future<void> _cancelNotification(ScheduledNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Schedule'),
        content: Text('Cancel "${notification.name}"?'),
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
        await _repository.cancel(notification.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _retryNotification(ScheduledNotification notification) async {
    try {
      await _repository.retry(notification.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification rescheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(ScheduledNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete "${notification.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.delete(notification.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<List<ScheduledNotification>> _fetchScheduledNotifications() async {
    if (_searchController.text.isNotEmpty) {
      return await _repository.search(_searchController.text);
    }

    if (_selectedStatus != null && _selectedFrequency != null) {
      final byStatus = await _repository.getAll(status: _selectedStatus);
      return byStatus.where((n) => n.frequency == _selectedFrequency).toList();
    }

    if (_selectedStatus != null) {
      return await _repository.getAll(status: _selectedStatus);
    }

    if (_selectedFrequency != null) {
      final all = await _repository.getAll();
      return all.where((n) => n.frequency == _selectedFrequency).toList();
    }

    return await _repository.getAll();
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}