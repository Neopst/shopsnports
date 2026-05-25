import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/invoice_export.dart';
import '../../data/repositories/invoice_export_repository.dart';

/// Screen for managing invoice exports
class InvoiceExportsScreen extends ConsumerStatefulWidget {
  const InvoiceExportsScreen({super.key});

  @override
  ConsumerState<InvoiceExportsScreen> createState() =>
      _InvoiceExportsScreenState();
}

class _InvoiceExportsScreenState extends ConsumerState<InvoiceExportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvoiceExportRepository _repository = InvoiceExportRepository();

  List<InvoiceExport> _allExports = [];
  List<InvoiceExport> _pendingExports = [];
  List<InvoiceExport> _completedExports = [];
  List<InvoiceExport> _failedExports = [];
  Map<String, dynamic> _statistics = {};
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
        _repository.getStatistics(),
      ]);

      setState(() {
        _allExports = results[0] as List<InvoiceExport>;
        _pendingExports = _allExports
            .where((e) => e.status == ExportStatus.pending)
            .toList();
        _completedExports = _allExports
            .where((e) => e.status == ExportStatus.completed)
            .toList();
        _failedExports = _allExports
            .where((e) => e.status == ExportStatus.failed)
            .toList();
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exports: $e')),
        );
      }
    }
  }

  Future<void> _cancelExport(String exportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Export'),
        content: const Text('Are you sure you want to cancel this export?'),
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
        await _repository.cancel(exportId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export cancelled')),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling export: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteExport(String exportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export'),
        content: const Text(
          'Are you sure you want to delete this export? This action cannot be undone.',
        ),
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
        await _repository.delete(exportId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export deleted')),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting export: $e')),
          );
        }
      }
    }
  }

  void _showExportDetails(InvoiceExport export) {
    showDialog(
      context: context,
      builder: (context) => _ExportDetailsDialog(export: export),
    );
  }

  void _showCreateExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateExportDialog(),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Exports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateExportDialog,
            tooltip: 'New Export',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
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
                      _buildExportList(_allExports),
                      _buildExportList(_pendingExports),
                      _buildExportList(_completedExports),
                      _buildExportList(_failedExports),
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
              Icons.file_download, Colors.blue),
          _buildStatItem('Pending', _statistics['pending']?.toString() ?? '0',
              Icons.pending, Colors.orange),
          _buildStatItem('Completed', _statistics['completed']?.toString() ?? '0',
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

  Widget _buildExportList(List<InvoiceExport> exports) {
    if (exports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No exports',
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
      itemCount: exports.length,
      itemBuilder: (context, index) {
        final export = exports[index];
        return _buildExportCard(export);
      },
    );
  }

  Widget _buildExportCard(InvoiceExport export) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: export.status.color,
          child: Text(
            export.format.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          export.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${export.totalInvoices} invoices'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(export.status),
                const SizedBox(width: 8),
                _buildFormatChip(export.format),
                const SizedBox(width: 8),
                if (export.fileSize != null)
                  Text(
                    export.formattedFileSize,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (export.canDownload)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadExport(export),
                tooltip: 'Download',
              ),
            if (export.status == ExportStatus.pending ||
                export.status == ExportStatus.processing)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cancelExport(export.id),
                tooltip: 'Cancel',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteExport(export.id),
              tooltip: 'Delete',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showExportDetails(export),
              tooltip: 'Details',
            ),
          ],
        ),
        onTap: () => _showExportDetails(export),
      ),
    );
  }

  Widget _buildStatusChip(ExportStatus status) {
    return Chip(
      label: Text(status.displayName),
      backgroundColor: status.color.withOpacity(0.2),
      labelStyle: TextStyle(color: status.color),
    );
  }

  Widget _buildFormatChip(ExportFormat format) {
    return Chip(
      label: Text(format.displayName),
      avatar: Text(format.icon),
    );
  }

  void _downloadExport(InvoiceExport export) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${export.name}...')),
    );
  }
}

class _ExportDetailsDialog extends StatelessWidget {
  final InvoiceExport export;

  const _ExportDetailsDialog({required this.export});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(export.format.icon),
          const SizedBox(width: 8),
          const Text('Export Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', export.name),
            _buildDetailRow('Format', export.format.displayName),
            _buildDetailRow('Status', export.status.displayName),
            _buildDetailRow('Invoices', '${export.totalInvoices}'),
            _buildDetailRow('Start Date', _formatDate(export.startDate)),
            _buildDetailRow('End Date', _formatDate(export.endDate)),
            if (export.filePath != null)
              _buildDetailRow('File Path', export.filePath!),
            if (export.fileSize != null)
              _buildDetailRow('File Size', export.formattedFileSize),
            if (export.completedAt != null)
              _buildDetailRow('Completed', _formatDate(export.completedAt!)),
            if (export.errorMessage != null)
              _buildDetailRow('Error', export.errorMessage!),
            _buildDetailRow('Created', _formatDate(export.createdAt)),
            _buildDetailRow('Created By', export.createdBy),
            const SizedBox(height: 16),
            if (export.selectedFields != null) ...[
              const Text(
                'Selected Fields:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: export.selectedFields!
                    .map((field) => Chip(label: Text(field)))
                    .toList(),
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

class _CreateExportDialog extends StatefulWidget {
  const _CreateExportDialog();

  @override
  State<_CreateExportDialog> createState() => _CreateExportDialogState();
}

class _CreateExportDialogState extends State<_CreateExportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final Set<String> _selectedFields = {
    'id',
    'invoiceNumber',
    'customerName',
    'amount',
    'status',
    'dueDate',
  };
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createExport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final repository = InvoiceExportRepository();
      final export = InvoiceExport(
        id: '',
        name: _nameController.text,
        format: _selectedFormat,
        status: ExportStatus.pending,
        invoiceIds: [],
        totalInvoices: 0,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'current_user', // TODO: Get current user ID
        selectedFields: _selectedFields.toList(),
      );

      await repository.create(export);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export created successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating export: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Export'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Export Name',
                  hintText: 'e.g., Monthly Invoices Export',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ExportFormat>(
                segments: ExportFormat.values
                    .map((format) => ButtonSegment(
                          value: format,
                          label: Text(format.displayName),
                          icon: Text(format.icon),
                        ))
                    .toList(),
                selected: {_selectedFormat},
                onSelectionChanged: (Set<ExportFormat> selected) {
                  setState(() {
                    _selectedFormat = selected.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(_formatDate(_startDate)),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_formatDate(_endDate)),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Fields to Export:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExportField.availableFields.map((field) {
                  final isSelected = _selectedFields.contains(field.key);
                  return FilterChip(
                    label: Text(field.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFields.add(field.key);
                        } else {
                          _selectedFields.remove(field.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createExport,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Export'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}