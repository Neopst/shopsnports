import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/notification_batch.dart';
import '../../data/repositories/notification_batch_repository.dart';

final batchRepositoryProvider =
    Provider<NotificationBatchRepository>((ref) {
  return NotificationBatchRepository();
});

final batchesProvider = FutureProvider<List<NotificationBatch>>((ref) async {
  final repository = ref.read(batchRepositoryProvider);
  return repository.getAllBatches();
});

final batchStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(batchRepositoryProvider);
  return repository.getBatchStatistics();
});

class NotificationBatchesScreen extends ConsumerStatefulWidget {
  const NotificationBatchesScreen({super.key});

  @override
  ConsumerState<NotificationBatchesScreen> createState() =>
      _NotificationBatchesScreenState();
}

class _NotificationBatchesScreenState
    extends ConsumerState<NotificationBatchesScreen> {
  BatchStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesProvider);
    final statsAsync = ref.watch(batchStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(batchesProvider);
              ref.invalidate(batchStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          _buildFilterChips(),
          Expanded(
            child: batchesAsync.when(
              data: (batches) {
                if (batches.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No batches yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: batches.length,
                  itemBuilder: (context, index) {
                    return _buildBatchCard(batches[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBatchDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Batch'),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: statsAsync.when(
        data: (stats) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Batch Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('Total', stats['total'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem('Sent', stats['totalSent'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Delivery',
                    '${stats['overallDeliveryRate']?.toStringAsFixed(1) ?? 0}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip('Pending', stats['pending'] ?? 0, Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatusChip('Processing', stats['processing'] ?? 0, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatusChip('Completed', stats['completed'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusChip('Failed', stats['failed'] ?? 0, Colors.red),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.2),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = selected ? null : _selectedStatus;
              });
            },
          ),
          ...BatchStatus.values.map((status) {
            return FilterChip(
              label: Text(_getStatusLabel(status)),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  String _getStatusLabel(BatchStatus status) {
    switch (status) {
      case BatchStatus.pending:
        return 'Pending';
      case BatchStatus.processing:
        return 'Processing';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.failed:
        return 'Failed';
      case BatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.pending:
        return Colors.orange;
      case BatchStatus.processing:
        return Colors.blue;
      case BatchStatus.completed:
        return Colors.green;
      case BatchStatus.failed:
        return Colors.red;
      case BatchStatus.cancelled:
        return Colors.grey;
    }
  }

  Widget _buildBatchCard(NotificationBatch batch) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    batch.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildStatusChip(batch.status.name, batch.sentCount, Colors.green),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: batch.progress / 100,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sent: ${batch.sentCount}/${batch.totalRecipients}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${batch.progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Remaining: ${batch.remainingCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildMetricsRow(batch),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (batch.status == BatchStatus.pending)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          onPressed: () => _showStartDialog(batch),
                        ),
                      ),
                    if (batch.status == BatchStatus.processing) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                          onPressed: () => _showPauseDialog(batch),
                        ),
                      ),
                    ],
                    if (batch.status == BatchStatus.failed) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => _showRetryDialog(batch),
                        ),
                      ),
                    ],
                    if (batch.status == BatchStatus.pending ||
                        batch.status == BatchStatus.processing) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          onPressed: () => _showCancelDialog(batch),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list),
                        label: const Text('View Items'),
                        onPressed: () => _showItemsDialog(batch),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricsRow(NotificationBatch batch) {
    return Row(
      children: [
        _buildMetricItem('Delivered', batch.deliveredCount, Colors.green),
        const SizedBox(width: 16),
        _buildMetricItem('Failed', batch.failedCount, Colors.red),
        const SizedBox(width: 16),
        _buildMetricItem(
          'Rate',
          '${batch.deliveryRate.toStringAsFixed(1)}%',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, dynamic value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBatchDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final templateIdController = TextEditingController();
    final recipientIdsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Batch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: templateIdController,
                decoration: const InputDecoration(
                  labelText: 'Template ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recipientIdsController,
                decoration: const InputDecoration(
                  labelText: 'Recipient IDs (comma-separated)',
                ),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final templateId = templateIdController.text.trim();
              final recipientIdsText = recipientIdsController.text.trim();

              if (name.isEmpty ||
                  templateId.isEmpty ||
                  recipientIdsText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final recipientIds = recipientIdsText
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              try {
                final repository = ref.read(batchRepositoryProvider);
                final batch = NotificationBatch(
                  id: '',
                  name: name,
                  description: description,
                  templateId: templateId,
                  recipientIds: recipientIds,
                  totalRecipients: recipientIds.length,
                  sentCount: 0,
                  deliveredCount: 0,
                  failedCount: 0,
                  status: BatchStatus.pending,
                  scheduledFor: DateTime.now(),
                  metadata: {},
                  createdBy: 'admin',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await repository.createBatch(batch);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(batchesProvider);
                  ref.invalidate(batchStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch created successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showStartDialog(NotificationBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Batch'),
        content: Text(
          'Are you sure you want to start the batch "${batch.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(batchRepositoryProvider);
                await repository.startBatch(batch.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(batchesProvider);
                  ref.invalidate(batchStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch started')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showPauseDialog(NotificationBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Batch'),
        content: Text(
          'Are you sure you want to pause the batch "${batch.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(batchRepositoryProvider);
                await repository.cancelBatch(batch.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(batchesProvider);
                  ref.invalidate(batchStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch paused')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(NotificationBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Failed Items'),
        content: Text(
          'Retry ${batch.failedCount} failed items in batch "${batch.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(batchRepositoryProvider);
                await repository.retryFailedItems(batch.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(batchesProvider);
                  ref.invalidate(batchStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Retrying failed items')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(NotificationBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Batch'),
        content: Text(
          'Are you sure you want to cancel the batch "${batch.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                final repository = ref.read(batchRepositoryProvider);
                await repository.cancelBatch(batch.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(batchesProvider);
                  ref.invalidate(batchStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch cancelled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Cancel Batch'),
          ),
        ],
      ),
    );
  }

  void _showItemsDialog(NotificationBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Items - ${batch.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              _buildItemsSummary(batch),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<BatchItem>>(
                  future: ref
                      .read(batchRepositoryProvider)
                      .getBatchItems(batch.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No items found'));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildItemTile(items[index]);
                      },
                    );
                  },
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

  Widget _buildItemsSummary(NotificationBatch batch) {
    return Row(
      children: [
        _buildSummaryItem('Total', batch.totalRecipients),
        const SizedBox(width: 16),
        _buildSummaryItem('Sent', batch.sentCount),
        const SizedBox(width: 16),
        _buildSummaryItem('Delivered', batch.deliveredCount),
        const SizedBox(width: 16),
        _buildSummaryItem('Failed', batch.failedCount),
      ],
    );
  }

  Widget _buildSummaryItem(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BatchItem item) {
    Color statusColor;
    String statusLabel;

    switch (item.status) {
      case BatchItemStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        break;
      case BatchItemStatus.sent:
        statusColor = Colors.blue;
        statusLabel = 'Sent';
        break;
      case BatchItemStatus.delivered:
        statusColor = Colors.green;
        statusLabel = 'Delivered';
        break;
      case BatchItemStatus.failed:
        statusColor = Colors.red;
        statusLabel = 'Failed';
        break;
      case BatchItemStatus.retrying:
        statusColor = Colors.amber;
        statusLabel = 'Retrying';
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.2),
        child: Icon(
          _getStatusIcon(item.status),
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(item.recipientEmail),
      subtitle: Text(
        '$statusLabel${item.retryCount > 0 ? ' (Retry ${item.retryCount})' : ''}',
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
        ),
      ),
      trailing: item.errorMessage != null
          ? IconButton(
              icon: const Icon(Icons.error_outline),
              onPressed: () => _showErrorDialog(item.errorMessage!),
              tooltip: 'View Error',
            )
          : null,
    );
  }

  IconData _getStatusIcon(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.pending:
        return Icons.schedule;
      case BatchItemStatus.sent:
        return Icons.send;
      case BatchItemStatus.delivered:
        return Icons.check_circle;
      case BatchItemStatus.failed:
        return Icons.error;
      case BatchItemStatus.retrying:
        return Icons.refresh;
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}