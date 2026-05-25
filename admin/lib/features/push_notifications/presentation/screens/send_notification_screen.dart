import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/services/fcm_sender_service.dart';
import '../../data/models/notification_template.dart';
import '../providers/push_notification_providers.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _targetAudience = 'all_admins';
  Set<String> _selectedAdminIds = {};
  NotificationTemplate? _selectedTemplate;
  bool _isSending = false;
  bool _selectAll = false;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Templates removed - using simple form only
    // _loadTemplates();
  }

  // REMOVED: API template loading - use Firestore or local templates in future
  // Future<void> _loadTemplates() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final client = ref.read(pushNotificationApiClientProvider);
  //     final templates = await client.getTemplates();
  //     setState(() {
  //       _templates = templates;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error loading templates: $e'),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 60),
  //         ),
  //       );
  //     }
  //   }
  // }

  List<NotificationTemplate> get _filteredTemplates =>
      []; // No templates for now

  void _useTemplate(NotificationTemplate? template) {
    if (template == null) {
      setState(() {
        _selectedTemplate = null;
        _titleController.clear();
        _bodyController.clear();
      });
      return;
    }

    setState(() {
      _selectedTemplate = template;
      _titleController.text = template.title;
      _bodyController.text = template.body;
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send, color: Colors.blue),
            SizedBox(width: 8),
            Text('Confirm Send'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sending to all ${_targetAudience.toUpperCase()}S',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Title:', style: Theme.of(context).textTheme.bodySmall),
            Text(
              _titleController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Message:', style: Theme.of(context).textTheme.bodySmall),
            Text(_bodyController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send),
            label: const Text('Send Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final fcmService = ref.read(fcmSenderServiceProvider);
      final topic = _targetAudience;

      final result = await fcmService.sendToTopic(
        topic: topic,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Notification sent to topic: $topic'),
              backgroundColor: Colors.green,
            ),
          );
          _titleController.clear();
          _bodyController.clear();
          setState(() => _selectedTemplate = null);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error Sending Notification'),
                ],
              ),
              content: SelectableText(result.error ?? 'Unknown error'),
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
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error Sending Notification'),
              ],
            ),
            content: SelectableText(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Push Notification'),
        backgroundColor: Colors.deepPurple,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed('/dashboard/push-notifications/history');
            },
            icon: const Icon(Icons.history, color: Colors.white),
            label: const Text('History', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Audience
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Audience',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All Admins'),
                                  selected: _targetAudience == 'all_admins',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _targetAudience = 'all_admins';
                                        _selectedAdminIds.clear();
                                        _selectAll = false;
                                        _selectedTemplate = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Specific Admins'),
                                  selected:
                                      _targetAudience == 'specific_admins',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _targetAudience = 'specific_admins';
                                        _selectedTemplate = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Customers'),
                                  selected: _targetAudience == 'customer',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _targetAudience = 'customer';
                                        _selectedTemplate = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Affiliates'),
                                  selected: _targetAudience == 'affiliate',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _targetAudience = 'affiliate';
                                        _selectedTemplate = null;
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Shippers'),
                                  selected: _targetAudience == 'shipper',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _targetAudience = 'shipper';
                                        _selectedTemplate = null;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_targetAudience == 'specific_admins') ...[
                              const SizedBox(height: 16),
                              Text(
                                'Select Admins',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                title: const Text('Select All Admins'),
                                value: _selectAll,
                                onChanged: (value) {
                                  setState(() {
                                    _selectAll = value ?? false;
                                    if (_selectAll) {
                                      // Load and select all admin IDs
                                      // For now, placeholder logic
                                      _selectedAdminIds = {'admin1', 'admin2'};
                                    } else {
                                      _selectedAdminIds.clear();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected: ${_selectedAdminIds.length} admin(s)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Admin multi-select list will be loaded from Firestore users collection (role=admin).\n\nView admin list to configure recipient selection.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Template Selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Quick Templates',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                if (_selectedTemplate != null)
                                  TextButton.icon(
                                    onPressed: () => _useTemplate(null),
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Clear'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<NotificationTemplate>(
                              initialValue: _selectedTemplate,
                              decoration: const InputDecoration(
                                labelText: 'Select Template',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.bookmark),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Custom message'),
                                ),
                                ..._filteredTemplates.map((template) {
                                  return DropdownMenuItem(
                                    value: template,
                                    child: Text(template.name),
                                  );
                                }),
                              ],
                              onChanged: _useTemplate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message Composer
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bodyController,
                              decoration: const InputDecoration(
                                labelText: 'Message *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.message),
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Message is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendNotification,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSending ? 'Sending...' : 'Send Notification',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
