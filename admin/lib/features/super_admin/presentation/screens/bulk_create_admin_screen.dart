import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../providers/super_admin_providers.dart';

/// Screen for bulk creating admin accounts
/// Allows creating multiple admins at once with CSV upload or manual entry
class BulkCreateAdminScreen extends ConsumerStatefulWidget {
  const BulkCreateAdminScreen({super.key});

  @override
  ConsumerState<BulkCreateAdminScreen> createState() =>
      _BulkCreateAdminScreenState();
}

class _BulkCreateAdminScreenState extends ConsumerState<BulkCreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();

  String _selectedRole = 'admin';
  String _selectedTemplate = 'Custom';
  late Map<String, bool> _selectedPermissions;

  // Bulk creation data
  final List<Map<String, dynamic>> _adminList = [];
  bool _isCreating = false;
  int _createdCount = 0;
  int _failedCount = 0;
  final List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _selectedPermissions = AdminPermissions.defaultPermissions().permissions;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Create Admins'),
        elevation: 0,
        actions: [
          if (_adminList.isNotEmpty)
            TextButton.icon(
              onPressed: _isCreating ? null : _startBulkCreation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Create All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              // Add admin form
              _buildAddAdminForm(),
              // Admin list
              if (_adminList.isNotEmpty) _buildAdminList(),
              // Creation progress
              if (_isCreating) _buildCreationProgress(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build add admin form
  Widget _buildAddAdminForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text(
              'Add Admin to Queue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'admin@shopsnports.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            // Display name field
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Display name is required';
                }
                if (value!.length < 2) {
                  return 'Display name must be at least 2 characters';
                }
                return null;
              },
            ),
            // Role selection
            _buildRoleSelection(),
            // Permission templates
            _buildPermissionTemplates(),
            // Add button
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _addAdminToQueue,
              icon: const Icon(Icons.add),
              label: const Text('Add to Queue'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build role selection
  Widget _buildRoleSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'admin',
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.admin_panel_settings, size: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Full access to assigned modules',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'sub_admin',
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.person_outline, size: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Sub-Admin',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Limited access to assigned modules',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value ?? 'admin';
            });
          },
        ),
      ),
    );
  }

  /// Build permission templates
  Widget _buildPermissionTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text(
          'Permission Template',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AdminPermissions.getTemplates().length,
            itemBuilder: (context, index) {
              final template = AdminPermissions.getTemplates()[index];
              final isSelected = _selectedTemplate == template.name;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTemplate = template.name;
                      _selectedPermissions = Map<String, bool>.from(template.permissions);
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? template.color.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? template.color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          template.icon,
                          size: 18,
                          color: isSelected ? template.color : Colors.grey.shade600,
                        ),
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? template.color : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build admin list
  Widget _buildAdminList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admins to Create (${_adminList.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_adminList.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isCreating ? null : _clearQueue,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                  ),
              ],
            ),
            ..._adminList.asMap().entries.map((entry) {
              final index = entry.key;
              final admin = entry.value;
              return _buildAdminListItem(index, admin);
            }),
          ],
        ),
      ),
    );
  }

  /// Build admin list item
  Widget _buildAdminListItem(int index, Map<String, dynamic> admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        spacing: 12,
        children: [
          CircleAvatar(
            child: Text(admin['displayName'][0].toUpperCase()),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  admin['displayName'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  admin['email'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: admin['role'] == 'admin'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        admin['role'] == 'admin' ? 'Admin' : 'Sub-Admin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: admin['role'] == 'admin'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    Text(
                      '${(admin['permissions'] as Map<String, bool>).values.where((v) => v).length} modules',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isCreating
                ? null
                : () {
                    setState(() {
                      _adminList.removeAt(index);
                    });
                  },
            ),
        ],
      ),
    );
  }

  /// Build creation progress
  Widget _buildCreationProgress() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                const CircularProgressIndicator(),
                Text(
                  'Creating admins... ($_createdCount/${_adminList.length})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (_errors.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        Text(
                          'Errors ($_failedCount)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    ..._errors.take(5).map((error) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            error,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        )),
                    if (_errors.length > 5)
                      Text(
                        '...and ${_errors.length - 5} more errors',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Add admin to queue
  void _addAdminToQueue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for duplicate email
    if (_adminList.any((admin) => admin['email'] == _emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email is already in the queue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _adminList.add({
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'role': _selectedRole,
        'permissions': Map<String, bool>.from(_selectedPermissions),
      });

      // Clear form
      _emailController.clear();
      _displayNameController.clear();
      _selectedPermissions = AdminPermissions.defaultPermissions().permissions;
      _selectedTemplate = 'Custom';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_adminList.last['displayName']} to queue'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Clear queue
  void _clearQueue() {
    setState(() {
      _adminList.clear();
      _errors.clear();
    });
  }

  /// Start bulk creation
  Future<void> _startBulkCreation() async {
    if (_adminList.isEmpty) return;

    setState(() {
      _isCreating = true;
      _createdCount = 0;
      _failedCount = 0;
      _errors.clear();
    });

    for (final admin in _adminList) {
      try {
        final result = await ref.read(
          createAdminProvider((
            email: admin['email'],
            displayName: admin['displayName'],
            role: admin['role'],
            permissions: admin['permissions'],
          )).future,
        );

        if (result['success'] == true) {
          setState(() {
            _createdCount++;
          });
        } else {
          setState(() {
            _failedCount++;
            _errors.add('${admin['email']}: ${result['error'] ?? 'Failed to create'}');
          });
        }
      } catch (e) {
        setState(() {
          _failedCount++;
          _errors.add('${admin['email']}: $e');
        });
      }

      // Small delay between requests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isCreating = false;
    });

    if (mounted) {
      // Show completion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bulk Creation Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Icon(
                _failedCount == 0 ? Icons.check_circle : Icons.info,
                size: 64,
                color: _failedCount == 0 ? Colors.green : Colors.orange,
              ),
              Text(
                'Created: $_createdCount\nFailed: $_failedCount',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              if (_errors.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Text(
                        'Errors:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ..._errors.take(3).map((error) => Text(
                            error,
                            style: const TextStyle(fontSize: 12),
                          )),
                      if (_errors.length > 3)
                        Text('...and ${_errors.length - 3} more'),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_failedCount == 0) {
                  Navigator.of(context).pop(); // Go back to previous screen
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}