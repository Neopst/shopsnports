import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_ticker.dart';
import '../../data/providers/news_ticker_providers.dart';

class NewsTickerScreen extends ConsumerStatefulWidget {
  const NewsTickerScreen({super.key});

  @override
  ConsumerState<NewsTickerScreen> createState() => _NewsTickerScreenState();
}

class _NewsTickerScreenState extends ConsumerState<NewsTickerScreen> {
  bool? _selectedActive;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter() {
    // Filter state is managed locally in the widget
    setState(() {}); // Trigger rebuild to apply local filter changes
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateNewsTickerDialog(),
    ).then((_) {
      // Refresh data after dialog closes
      ref.invalidate(filteredNewsItemsProvider);
    });
  }

  void _showEditDialog(NewsTicker item) {
    showDialog(
      context: context,
      builder: (context) => _EditNewsTickerDialog(newsItem: item),
    ).then((_) {
      ref.invalidate(filteredNewsItemsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use streaming providers for real-time updates
    final itemsAsync = ref.watch(streamAllNewsItemsProvider);
    final statsAsync = ref.watch(newsTickerStatsMockProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'News Ticker Management',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage news items and announcements for the mobile app',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create News Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats
          statsAsync.when(
            data: (stats) => _buildStatsGrid(context, stats),
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Text('Error loading stats: $err'),
          ),
          const SizedBox(height: 32),

          // Filters
          _buildFiltersSection(),
          const SizedBox(height: 24),

          // News Items Table - Real-time from Firestore
          itemsAsync.when(
            data: (items) {
              // Apply local filtering
              var filtered = items;
              if (_selectedActive != null) {
                filtered = filtered
                    .where((item) => item.isActive == _selectedActive)
                    .toList();
              }
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                filtered = filtered
                    .where(
                      (item) =>
                          item.text.toLowerCase().contains(query) ||
                          (item.link?.toLowerCase().contains(query) ?? false),
                    )
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No news items found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildNewsItemsTable(context, filtered);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error loading news items: $err'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _StatCard(
          title: 'Total Items',
          value: '${stats['total'] ?? 0}',
          icon: Icons.newspaper,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Active',
          value: '${stats['active'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Inactive',
          value: '${stats['inactive'] ?? 0}',
          icon: Icons.visibility_off,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Expired',
          value: '${stats['expired'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.purple,
        ),
        _StatCard(
          title: 'Total Views',
          value: '${stats['totalViews'] ?? 0}',
          icon: Icons.visibility,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title or content...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => _updateFilter(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: _selectedActive,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('All'),
                      ),
                      const DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Active'),
                      ),
                      const DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedActive = value);
                      _updateFilter();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItemsTable(BuildContext context, List<NewsTicker> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No news items found',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Text')),
          DataColumn(label: Text('Link')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Created')),
          DataColumn(label: Text('Expires')),
          DataColumn(label: Text('Views')),
          DataColumn(label: Text('Actions')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    item.link ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.link != null ? Colors.blue : Colors.grey,
                      decoration: item.link != null ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ),
              DataCell(_buildStatusChip(item.isActive)),
              DataCell(
                Center(
                  child: Chip(
                    label: Text('${item.priority}'),
                    backgroundColor: _getPriorityColor(item.priority),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              DataCell(Text(_formatDate(item.createdAt))),
              DataCell(
                Text(
                  item.expiresAt != null ? _formatDate(item.expiresAt!) : '-',
                  style: TextStyle(color: item.isExpired ? Colors.red : null),
                ),
              ),
              DataCell(Text('${item.viewCount}')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showEditDialog(item),
                      tooltip: 'Edit',
                    ),
                    if (!item.isActive)
                      IconButton(
                        icon: const Icon(Icons.publish, size: 18),
                        onPressed: () => _publishItem(item.id),
                        tooltip: 'Activate',
                      ),
                    if (item.isActive)
                      IconButton(
                        icon: const Icon(Icons.archive, size: 18),
                        onPressed: () => _archiveItem(item.id),
                        tooltip: 'Deactivate',
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteItem(item.id),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? Colors.green : Colors.grey;
    final label = isActive ? 'Active' : 'Inactive';
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 5) return Colors.red;
    if (priority >= 4) return Colors.orange;
    if (priority >= 3) return Colors.yellow;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _publishItem(String id) async {
    try {
      await ref.read(publishNewsItemFirestoreProvider(id).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News item activated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _archiveItem(String id) async {
    try {
      await ref.read(archiveNewsItemFirestoreProvider(id).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News item deactivated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News Item'),
        content: const Text(
          'Are you sure you want to delete this news item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deleteNewsItemFirestoreProvider(id).future);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('News item deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateNewsTickerDialog extends ConsumerStatefulWidget {
  const _CreateNewsTickerDialog();

  @override
  ConsumerState<_CreateNewsTickerDialog> createState() =>
      _CreateNewsTickerDialogState();
}

class _CreateNewsTickerDialogState
    extends ConsumerState<_CreateNewsTickerDialog> {
  final _textController = TextEditingController();
  final _linkController = TextEditingController();
  int _priority = 0;
  bool _isActive = true;
  DateTime? _expiresAt;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _createItem() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final newItem = NewsTicker(
      id: '', // Will be generated by repository
      text: _textController.text.trim(),
      link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      priority: _priority,
      isActive: _isActive,
      expiresAt: _expiresAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin@example.com',
    );

    ref
        .read(createNewsItemFirestoreProvider(newItem))
        .when(
          data: (_) {
            if (mounted) {
              Navigator.pop(context);
              // Show success popup
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Success'),
                    ],
                  ),
                  content: Text('News item "${newItem.text}" has been created successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('News item created successfully')),
              );
            }
          },
          error: (e, st) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          loading: () {},
        );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create News Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Low')),
                DropdownMenuItem(value: 5, child: Text('Medium')),
                DropdownMenuItem(value: 10, child: Text('High')),
              ],
              onChanged: (value) => setState(() => _priority = value ?? 0),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show in mobile app'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _expiresAt != null
                        ? 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                        : 'No expiration',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _expiresAt = date);
                    }
                  },
                  child: const Text('Set Expiration'),
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
        ElevatedButton(
          onPressed: _isSubmitting ? null : _createItem,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _EditNewsTickerDialog extends ConsumerStatefulWidget {
  final NewsTicker newsItem;

  const _EditNewsTickerDialog({required this.newsItem});

  @override
  ConsumerState<_EditNewsTickerDialog> createState() =>
      _EditNewsTickerDialogState();
}

class _EditNewsTickerDialogState extends ConsumerState<_EditNewsTickerDialog> {
  late TextEditingController _textController;
  late TextEditingController _linkController;
  late int _priority;
  late bool _isActive;
  DateTime? _expiresAt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.newsItem.text);
    _linkController = TextEditingController(text: widget.newsItem.link ?? '');
    _priority = widget.newsItem.priority;
    _isActive = widget.newsItem.isActive;
    _expiresAt = widget.newsItem.expiresAt;
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _updateItem() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final updatedItem = widget.newsItem.copyWith(
      text: _textController.text,
      link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      priority: _priority,
      isActive: _isActive,
      expiresAt: _expiresAt,
    );

    ref
        .read(updateNewsItemFirestoreProvider(updatedItem))
        .when(
          data: (_) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('News item updated successfully')),
              );
            }
          },
          error: (e, st) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          loading: () {},
        );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit News Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Low')),
                DropdownMenuItem(value: 5, child: Text('Medium')),
                DropdownMenuItem(value: 10, child: Text('High')),
              ],
              onChanged: (value) => setState(() => _priority = value ?? 0),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show in mobile app'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _expiresAt != null
                        ? 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                        : 'No expiration',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _expiresAt ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _expiresAt = date);
                    }
                  },
                  child: const Text('Set Expiration'),
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
        ElevatedButton(
          onPressed: _isSubmitting ? null : _updateItem,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
