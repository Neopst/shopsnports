import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/services/fcm_sender_service.dart';
import '../../data/models/notification_history.dart';
import '../providers/push_notification_providers.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  List<NotificationHistory> _history = [];
  bool _isLoading = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final fcmService = ref.read(fcmSenderServiceProvider);
      final historyData = await fcmService.getHistory();
      setState(() {
        _history = historyData.map((h) => NotificationHistory.fromJson(h)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Filter by:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = null);
                              _loadHistory();
                            }
                          },
                        ),
                        FilterChip(
                          label: const Text('Customers'),
                          selected: _selectedCategory == 'customer',
                          onSelected: (selected) {
                            setState(
                              () => _selectedCategory = selected
                                  ? 'customer'
                                  : null,
                            );
                            _loadHistory();
                          },
                        ),
                        FilterChip(
                          label: const Text('Affiliates'),
                          selected: _selectedCategory == 'affiliate',
                          onSelected: (selected) {
                            setState(
                              () => _selectedCategory = selected
                                  ? 'affiliate'
                                  : null,
                            );
                            _loadHistory();
                          },
                        ),
                        FilterChip(
                          label: const Text('Shippers'),
                          selected: _selectedCategory == 'shipper',
                          onSelected: (selected) {
                            setState(
                              () => _selectedCategory = selected
                                  ? 'shipper'
                                  : null,
                            );
                            _loadHistory();
                          },
                        ),
                        FilterChip(
                          label: const Text('All Admins'),
                          selected: _selectedCategory == 'all_admins',
                          onSelected: (selected) {
                            setState(
                              () => _selectedCategory = selected
                                  ? 'all_admins'
                                  : null,
                            );
                            _loadHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications sent yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[200],
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Title',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Category',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Sent',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Delivered',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Failed',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Opened',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Delivery Rate',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Open Rate',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _history.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  dateFormat.format(
                                    item.sentAt ?? item.createdAt,
                                  ),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 200,
                                  ),
                                  child: Tooltip(
                                    message: item.body,
                                    child: Text(
                                      item.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(item.category.toUpperCase()),
                                  backgroundColor: Colors.blue[100],
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(item.status.toUpperCase()),
                                  backgroundColor: _getStatusColor(item.status),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(Text(item.sentCount.toString())),
                              DataCell(Text(item.deliveredCount.toString())),
                              DataCell(
                                Text(
                                  item.failedCount.toString(),
                                  style: TextStyle(
                                    color: item.failedCount > 0
                                        ? Colors.red
                                        : null,
                                  ),
                                ),
                              ),
                              DataCell(Text(item.openedCount.toString())),
                              DataCell(
                                Text(
                                  '${item.deliveryRate.toStringAsFixed(1)}%',
                                ),
                              ),
                              DataCell(
                                Text('${item.openRate.toStringAsFixed(1)}%'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
