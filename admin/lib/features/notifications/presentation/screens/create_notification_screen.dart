import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/services/api_client.dart';
import '../../../../core/utils/app_logger.dart';

class CreateNotificationScreen extends ConsumerStatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  ConsumerState<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState
    extends ConsumerState<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isLoading = false;
  bool _isSending = false;
  String? _selectedTemplate;
  String _selectedCategory = 'customer';
  String _selectedUserType = 'customer';
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(adminApiClientProvider);

      // Debug: Print request info
      AppLogger.debug('Loading templates from: /api/v1/push-notifications/templates', tag: 'Notifications');

      final response = await client.get('/api/v1/push-notifications/templates');

      // Debug: Print response
      AppLogger.debug('Templates response: $response', tag: 'Notifications');

      if (response['success'] == true) {
        final templates = List<Map<String, dynamic>>.from(
          response['data'] ?? [],
        );
        AppLogger.info('Loaded ${templates.length} templates', tag: 'Notifications');

        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      } else {
        AppLogger.error('Template load failed: ${response['message']}', tag: 'Notifications');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading templates: $e', tag: 'Notifications', error: e, stackTrace: stackTrace);
      AppLogger.debug('Stack trace: $stackTrace', tag: 'Notifications');

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading templates: $e'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadTemplates,
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog with enhanced preview
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.send, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Confirm Send'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sending to all ${_selectedUserType.toUpperCase()}S',
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
              const Text(
                'Notification Preview:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              // Phone mockup preview
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _bodyController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
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
      final client = ref.read(adminApiClientProvider);
      final response = await client.post(
        '/api/v1/push-notifications/send',
        {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'category': _selectedCategory,
          'targetUserType': _selectedUserType,
          if (_selectedTemplate != null) 'templateId': _selectedTemplate,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          final sentCount = response['data']?['sent'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent to $sentCount devices'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return to history screen
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Send notification error: $e', tag: 'Notifications', error: e, stackTrace: stackTrace);
      AppLogger.debug('Stack trace: $stackTrace', tag: 'Notifications');

      if (mounted) {
        // Show error dialog with full message (SnackBar disappears too quickly)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error Sending Notification'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Failed to send notification:'),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: SelectableText(
                      e.toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
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

  void _useTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplate = template['id']?.toString() ?? '';
      _titleController.text = template['title']?.toString() ?? '';
      _bodyController.text = template['body']?.toString() ?? '';
      _selectedCategory = template['category']?.toString() ?? 'customer';
      _selectedUserType = template['category']?.toString() ?? 'customer';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryTemplates = _templates
        .where((t) => t['category'] == _selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Send Push Notification'),
        actions: [
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendNotification,
              tooltip: 'Send Notification',
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
                    // Target Audience Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Audience',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildUserTypeChip(
                                  'customer',
                                  'Shippers',
                                  Icons.local_shipping,
                                ),
                                _buildUserTypeChip(
                                  'affiliate',
                                  'Affiliates',
                                  Icons.people,
                                ),
                                _buildUserTypeChip(
                                  'shipper',
                                  'Shippers',
                                  Icons.local_shipping,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Template Dropdown
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Templates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTemplate,
                              decoration: InputDecoration(
                                labelText: 'Select a template (optional)',
                                hintText: 'Choose a pre-made template',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.description),
                                suffixIcon: _selectedTemplate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _selectedTemplate = null;
                                            _titleController.clear();
                                            _bodyController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Custom message (no template)'),
                                ),
                                ...categoryTemplates.map((template) {
                                  return DropdownMenuItem<String>(
                                    value: template['id'].toString(),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getTemplateIcon(template['type']),
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            template['name'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  setState(() {
                                    _selectedTemplate = null;
                                    _titleController.clear();
                                    _bodyController.clear();
                                  });
                                } else {
                                  final template = _templates.firstWhere(
                                    (t) => t['id'].toString() == value,
                                  );
                                  _useTemplate(template);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                hintText: 'Notification title',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              maxLength: 100,
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
                                labelText: 'Message',
                                hintText: 'Notification message',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.message),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              maxLength: 500,
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
                    const SizedBox(height: 16),

                    // Preview Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.notifications,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _titleController.text.isEmpty
                                              ? 'Notification Title'
                                              : _titleController.text,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _bodyController.text.isEmpty
                                              ? 'Notification message will appear here'
                                              : _bodyController.text,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Just now',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedUserType == value;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = value;
          _selectedCategory = value;
          _selectedTemplate = null; // Clear template when changing category
        });
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  IconData _getTemplateIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'invoice':
        return Icons.receipt;
      case 'promotion':
        return Icons.local_offer;
      case 'inventory':
        return Icons.inventory;
      case 'payout':
        return Icons.account_balance_wallet;
      case 'shipping':
        return Icons.local_shipping;
      case 'commission':
        return Icons.attach_money;
      case 'engagement':
        return Icons.thumb_up;
      case 'shipment':
        return Icons.flight;
      case 'schedule':
        return Icons.calendar_today;
      case 'action':
        return Icons.task_alt;
      default:
        return Icons.notifications;
    }
  }
}
