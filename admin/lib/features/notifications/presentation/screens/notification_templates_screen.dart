import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_template.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_type.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_category.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_priority.dart';
import 'package:admin_dashboard/features/notifications/data/repositories/notification_template_repository.dart';

class NotificationTemplatesScreen extends ConsumerStatefulWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  ConsumerState<NotificationTemplatesScreen> createState() =>
      _NotificationTemplatesScreenState();
}

class _NotificationTemplatesScreenState
    extends ConsumerState<NotificationTemplatesScreen> {
  final _repository = NotificationTemplateRepository();
  final _searchController = TextEditingController();
  TemplateStatus? _selectedStatus;
  NotificationType? _selectedType;

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
        title: const Text('Notification Templates'),
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
          // Templates list
          Expanded(
            child: _buildTemplatesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
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
                hintText: 'Search templates...',
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
          if (_selectedStatus != null || _selectedType != null)
            Chip(
              label: const Text('Filters Active'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedType = null;
                });
              },
              backgroundColor: Colors.blue[100],
            ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return FutureBuilder<List<NotificationTemplate>>(
      future: _fetchTemplates(),
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

        final templates = snapshot.data ?? [];

        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No templates found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Template'),
                  onPressed: () => _showTemplateDialog(),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _buildTemplateCard(template);
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(NotificationTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTemplateDetailDialog(template),
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
                      color: template.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.status.icon,
                      color: template.status.color,
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
                              template.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (template.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
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
                                color: template.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                template.status.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: template.status.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              template.type.displayName,
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
                    onSelected: (action) => _handleMenuAction(action, template),
                    itemBuilder: (context) => [
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
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Preview'),
                          ],
                        ),
                      ),
                      if (template.status == TemplateStatus.active)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive, size: 18),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                      if (template.status == TemplateStatus.draft ||
                          template.status == TemplateStatus.archived)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text('Activate'),
                            ],
                          ),
                        ),
                      if (!template.isDefault)
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
                template.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Variables
              if (template.variables.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.variables
                      .map((v) => Chip(
                            label: Text('{{$v}}'),
                            labelStyle: const TextStyle(fontSize: 11),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              const SizedBox(height: 8),
              // Stats
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Used ${template.usageCount} times',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.update, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'v${template.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (template.lastUsedAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Last used: ${_formatDate(template.lastUsedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDialog({NotificationTemplate? template}) {
    final nameController = TextEditingController(text: template?.name ?? '');
    final descriptionController =
        TextEditingController(text: template?.description ?? '');
    final titleController = TextEditingController(text: template?.title ?? '');
    final messageController = TextEditingController(text: template?.message ?? '');
    final actionUrlController =
        TextEditingController(text: template?.actionUrl ?? '');

    NotificationType selectedType = template?.type ?? NotificationType.system;
    NotificationCategory selectedCategory =
        template?.category ?? NotificationCategory.system;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(template == null ? 'New Template' : 'Edit Template'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
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
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: const OutlineInputBorder(),
                      helperText: 'Use {{variable}} for dynamic content',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: const OutlineInputBorder(),
                      helperText: 'Use {{variable}} for dynamic content',
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
                      messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in required fields')),
                    );
                    return;
                  }

                  try {
                    final newTemplate = NotificationTemplate(
                      id: template?.id ??
                          'tpl_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      description: descriptionController.text,
                      type: selectedType,
                      category: selectedCategory,
                      title: titleController.text,
                      message: messageController.text,
                      actionUrl: actionUrlController.text.isEmpty
                          ? null
                          : actionUrlController.text,
                      variables: _extractVariables(
                          titleController.text, messageController.text),
                      status: template?.status ?? TemplateStatus.draft,
                      isDefault: template?.isDefault ?? false,
                      version: template?.version ?? 1,
                      createdAt: template?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (template == null) {
                      await _repository.create(newTemplate);
                    } else {
                      await _repository.update(newTemplate);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              template == null
                                  ? 'Template created'
                                  : 'Template updated'),
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

  void _showTemplateDetailDialog(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(template.status.icon, color: template.status.color),
            const SizedBox(width: 8),
            Expanded(child: Text(template.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', template.id),
              _buildDetailRow('Description', template.description),
              _buildDetailRow('Type', template.type.displayName),
              _buildDetailRow('Category', template.category.displayName),
              _buildDetailRow('Status', template.status.displayName),
              _buildDetailRow('Version', 'v${template.version}'),
              _buildDetailRow('Usage Count', '${template.usageCount}'),
              if (template.lastUsedAt != null)
                _buildDetailRow('Last Used', _formatDateTime(template.lastUsedAt!)),
              const SizedBox(height: 16),
              const Text(
                'Title Template',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(template.title),
              ),
              const SizedBox(height: 12),
              const Text(
                'Message Template',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(template.message),
              ),
              if (template.actionUrl != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Action URL', template.actionUrl!),
              ],
              if (template.variables.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Variables',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: template.variables
                      .map((v) => Chip(
                            label: Text('{{$v}}'),
                          ))
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
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Preview'),
            onPressed: () => _showPreviewDialog(template),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(NotificationTemplate template) {
    final sampleData = _getSampleData(template);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sampleData.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(child: Text(e.value.toString())),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.substituteTitle(sampleData),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(template.substituteMessage(sampleData)),
                ],
              ),
            ),
          ],
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
        title: const Text('Filter Templates'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TemplateStatus.values.map((status) {
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
              const Text('Type'),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedType = null;
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

  void _handleMenuAction(String action, NotificationTemplate template) {
    switch (action) {
      case 'edit':
        _showTemplateDialog(template: template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'preview':
        _showPreviewDialog(template);
        break;
      case 'archive':
        _archiveTemplate(template);
        break;
      case 'activate':
        _activateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  Future<void> _duplicateTemplate(NotificationTemplate template) async {
    try {
      await _repository.duplicate(template.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template duplicated')),
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

  Future<void> _archiveTemplate(NotificationTemplate template) async {
    try {
      await _repository.archive(template.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template archived')),
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

  Future<void> _activateTemplate(NotificationTemplate template) async {
    try {
      await _repository.activate(template.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template activated')),
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

  Future<void> _deleteTemplate(NotificationTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
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
        await _repository.delete(template.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template deleted')),
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

  Future<List<NotificationTemplate>> _fetchTemplates() async {
    if (_searchController.text.isNotEmpty) {
      return await _repository.search(_searchController.text);
    }

    if (_selectedStatus != null && _selectedType != null) {
      // Need to filter by both - get by type and filter manually
      final byType = await _repository.getByType(_selectedType!);
      return byType.where((t) => t.status == _selectedStatus).toList();
    }

    if (_selectedStatus != null) {
      return await _repository.getAll(status: _selectedStatus);
    }

    if (_selectedType != null) {
      return await _repository.getByType(_selectedType!);
    }

    return await _repository.getAll();
  }

  List<String> _extractVariables(String title, String message) {
    final regex = RegExp(r'\{(\w+)\}');
    final variables = <String>{};

    for (final match in regex.allMatches(title)) {
      variables.add(match.group(1)!);
    }
    for (final match in regex.allMatches(message)) {
      variables.add(match.group(1)!);
    }

    return variables.toList();
  }

  Map<String, dynamic> _getSampleData(NotificationTemplate template) {
    final data = <String, dynamic>{};

    for (final variable in template.variables) {
      switch (variable.toLowerCase()) {
        case 'username':
          data[variable] = 'John Doe';
          break;
        case 'ordernumber':
          data[variable] = 'ORD-12345';
          break;
        case 'orderid':
          data[variable] = 'order_12345';
          break;
        case 'amount':
          data[variable] = '5,000';
          break;
        case 'trackingurl':
          data[variable] = 'https://track.example.com/12345';
          break;
        case 'trackingnumber':
          data[variable] = 'TRK-12345';
          break;
        case 'invoicenumber':
          data[variable] = 'INV-12345';
          break;
        case 'invoiceid':
          data[variable] = 'invoice_12345';
          break;
        case 'discount':
          data[variable] = '20';
          break;
        case 'productname':
          data[variable] = 'Amazing Product';
          break;
        case 'promocode':
          data[variable] = 'SAVE20';
          break;
        case 'promoid':
          data[variable] = 'promo_12345';
          break;
        case 'date':
          data[variable] = '2024-01-15';
          break;
        case 'starttime':
          data[variable] = '10:00 AM';
          break;
        case 'endtime':
          data[variable] = '2:00 PM';
          break;
        default:
          data[variable] = 'Sample Value';
      }
    }

    return data;
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}