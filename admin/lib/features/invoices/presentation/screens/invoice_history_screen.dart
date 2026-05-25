import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_history.dart';
import '../../data/repositories/invoice_history_repository.dart';

final historyRepositoryProvider = Provider<InvoiceHistoryRepository>((ref) {
  return InvoiceHistoryRepository(FirebaseFirestore.instance);
});

final historyProvider = StreamProvider<List<InvoiceHistory>>((ref) {
  return ref.watch(historyRepositoryProvider).getAllHistory();
});

class InvoiceHistoryScreen extends ConsumerStatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  ConsumerState<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends ConsumerState<InvoiceHistoryScreen> {
  HistoryAction? _selectedAction;
  bool? _showSystemOnly;
  String _searchQuery = '';
  String? _selectedInvoiceId;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportHistory(context),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: historyAsync.when(
              data: (history) {
                final filteredHistory = _filterHistory(history);
                if (filteredHistory.isEmpty) {
                  return const Center(child: Text('No history found'));
                }
                return ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(filteredHistory[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16,
        children: [
          Row(
            children: [
              const Text('Action: ', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<HistoryAction>(
                value: _selectedAction,
                hint: const Text('All'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...HistoryAction.values.map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(action.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedAction = value);
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('Source: ', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<bool>(
                value: _showSystemOnly,
                hint: const Text('All'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('System Only')),
                  DropdownMenuItem(value: false, child: Text('User Only')),
                ],
                onChanged: (value) {
                  setState(() => _showSystemOnly = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search history...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  List<InvoiceHistory> _filterHistory(List<InvoiceHistory> history) {
    var filtered = history;

    if (_selectedAction != null) {
      filtered = filtered.where((entry) => entry.action == _selectedAction).toList();
    }

    if (_showSystemOnly != null) {
      filtered = filtered.where((entry) => entry.isSystemGenerated == _showSystemOnly).toList();
    }

    if (_selectedInvoiceId != null) {
      filtered = filtered.where((entry) => entry.invoiceId == _selectedInvoiceId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((entry) =>
              entry.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              entry.performedBy.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildHistoryCard(InvoiceHistory entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _buildActionIcon(entry.action),
        title: Row(
          children: [
            Expanded(child: Text(entry.description)),
            _buildActionChip(entry.action),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${entry.invoiceId}'),
            Row(
              children: [
                _buildSourceChip(entry.isSystemGenerated),
                const SizedBox(width: 8),
                Text('By: ${entry.performedBy}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text(_formatDate(entry.createdAt), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Action', entry.action.name),
                _buildInfoRow('Description', entry.description),
                _buildInfoRow('Invoice ID', entry.invoiceId),
                _buildInfoRow('Performed By', entry.performedBy),
                if (entry.performedByRole != null)
                  _buildInfoRow('Role', entry.performedByRole!),
                _buildInfoRow('Created At', _formatDate(entry.createdAt)),
                if (entry.ipAddress != null)
                  _buildInfoRow('IP Address', entry.ipAddress!),
                if (entry.userAgent != null)
                  _buildInfoRow('User Agent', entry.userAgent!),
                if (entry.relatedEntityId != null) ...[
                  const Divider(),
                  _buildInfoRow('Related Entity ID', entry.relatedEntityId!),
                  if (entry.relatedEntityType != null)
                    _buildInfoRow('Related Entity Type', entry.relatedEntityType!),
                ],
                if (entry.oldValue.isNotEmpty) ...[
                  const Divider(),
                  const Text('Old Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildJsonViewer(entry.oldValue),
                ],
                if (entry.newValue.isNotEmpty) ...[
                  const Divider(),
                  const Text('New Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildJsonViewer(entry.newValue),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(HistoryAction action) {
    IconData icon;
    Color color;

    switch (action) {
      case HistoryAction.created:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case HistoryAction.updated:
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case HistoryAction.deleted:
        icon = Icons.delete;
        color = Colors.red;
        break;
      case HistoryAction.statusChanged:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case HistoryAction.paymentReceived:
        icon = Icons.payments;
        color = Colors.green;
        break;
      case HistoryAction.paymentRefunded:
        icon = Icons.money_off;
        color = Colors.red;
        break;
      case HistoryAction.reminderSent:
        icon = Icons.alarm;
        color = Colors.orange;
        break;
      case HistoryAction.noteAdded:
        icon = Icons.note_add;
        color = Colors.blue;
        break;
      case HistoryAction.noteUpdated:
        icon = Icons.note;
        color = Colors.blue;
        break;
      case HistoryAction.noteDeleted:
        icon = Icons.delete;
        color = Colors.red;
        break;
      case HistoryAction.lineItemAdded:
        icon = Icons.add_shopping_cart;
        color = Colors.green;
        break;
      case HistoryAction.lineItemUpdated:
        icon = Icons.shopping_cart;
        color = Colors.blue;
        break;
      case HistoryAction.lineItemDeleted:
        icon = Icons.remove_shopping_cart;
        color = Colors.red;
        break;
      case HistoryAction.taxUpdated:
        icon = Icons.receipt_long;
        color = Colors.purple;
        break;
      case HistoryAction.discountApplied:
        icon = Icons.local_offer;
        color = Colors.green;
        break;
      case HistoryAction.discountRemoved:
        icon = Icons.local_offer;
        color = Colors.red;
        break;
      case HistoryAction.templateApplied:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case HistoryAction.exported:
        icon = Icons.download;
        color = Colors.blue;
        break;
      case HistoryAction.emailed:
        icon = Icons.email;
        color = Colors.blue;
        break;
      case HistoryAction.viewed:
        icon = Icons.visibility;
        color = Colors.grey;
        break;
      case HistoryAction.downloaded:
        icon = Icons.file_download;
        color = Colors.blue;
        break;
      case HistoryAction.disputed:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case HistoryAction.resolved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case HistoryAction.writtenOff:
        icon = Icons.block;
        color = Colors.red;
        break;
      case HistoryAction.reinstated:
        icon = Icons.restore;
        color = Colors.green;
        break;
      case HistoryAction.archived:
        icon = Icons.archive;
        color = Colors.grey;
        break;
      case HistoryAction.unarchived:
        icon = Icons.unarchive;
        color = Colors.blue;
        break;
      case HistoryAction.duplicateCreated:
        icon = Icons.content_copy;
        color = Colors.blue;
        break;
      case HistoryAction.merged:
        icon = Icons.merge_type;
        color = Colors.purple;
        break;
      case HistoryAction.split:
        icon = Icons.call_split;
        color = Colors.purple;
        break;
      case HistoryAction.custom:
        icon = Icons.settings;
        color = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActionChip(HistoryAction action) {
    final color = _getActionColor(action);
    return Chip(
      label: Text(action.name),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 11),
    );
  }

  Color _getActionColor(HistoryAction action) {
    switch (action) {
      case HistoryAction.created:
      case HistoryAction.paymentReceived:
      case HistoryAction.resolved:
      case HistoryAction.reinstated:
      case HistoryAction.discountApplied:
      case HistoryAction.lineItemAdded:
        return Colors.green;
      case HistoryAction.updated:
      case HistoryAction.noteAdded:
      case HistoryAction.noteUpdated:
      case HistoryAction.lineItemUpdated:
      case HistoryAction.templateApplied:
      case HistoryAction.exported:
      case HistoryAction.emailed:
      case HistoryAction.downloaded:
      case HistoryAction.unarchived:
      case HistoryAction.duplicateCreated:
        return Colors.blue;
      case HistoryAction.deleted:
      case HistoryAction.paymentRefunded:
      case HistoryAction.noteDeleted:
      case HistoryAction.lineItemDeleted:
      case HistoryAction.discountRemoved:
      case HistoryAction.writtenOff:
        return Colors.red;
      case HistoryAction.statusChanged:
      case HistoryAction.reminderSent:
      case HistoryAction.disputed:
        return Colors.orange;
      case HistoryAction.taxUpdated:
      case HistoryAction.merged:
      case HistoryAction.split:
        return Colors.purple;
      case HistoryAction.viewed:
      case HistoryAction.archived:
      case HistoryAction.custom:
        return Colors.grey;
    }
  }

  Widget _buildSourceChip(bool isSystemGenerated) {
    return Chip(
      label: Text(isSystemGenerated ? 'System' : 'User'),
      backgroundColor: isSystemGenerated ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSystemGenerated ? Colors.purple : Colors.blue,
        fontSize: 11,
      ),
    );
  }

  Widget _buildJsonViewer(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatJson(data),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}: ${e.value.toString()}')
        .join('\n');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showStatistics(BuildContext context) async {
    final stats = await ref.read(historyRepositoryProvider).getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Statistics'),
        content: SizedBox(
          width: 500,
          height: 500,
          child: ListView(
            children: [
              _buildStatRow('Total Entries', stats['totalEntries'].toString()),
              _buildStatRow('System Entries', stats['systemEntries'].toString()),
              _buildStatRow('User Entries', stats['userEntries'].toString()),
              const Divider(),
              const Text('Action Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(stats['actionCounts'] as Map<HistoryAction, int>).entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key.name}: ${entry.value}'),
                );
              }),
              const Divider(),
              const Text('User Activity:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(stats['userActivity'] as Map<String, int>).entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key}: ${entry.value} actions'),
                );
              }),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _exportHistory(BuildContext context) async {
    if (_selectedInvoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please filter by invoice ID first')),
      );
      return;
    }

    try {
      final csv = await ref.read(historyRepositoryProvider).exportHistoryToCSV(_selectedInvoiceId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }
}