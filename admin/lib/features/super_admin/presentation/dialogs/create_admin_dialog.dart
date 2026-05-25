import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../../services/password_generator_service.dart';
import '../providers/super_admin_providers.dart';

/// Dialog for creating a new admin
/// - Registration form
/// - Permission selection
/// - Password generation
class CreateAdminDialog extends ConsumerStatefulWidget {
  const CreateAdminDialog({super.key});

  @override
  ConsumerState<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends ConsumerState<CreateAdminDialog> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  late String _generatedPassword;
  final Map<String, bool> _selectedPermissions = {};
  String _selectedRole = 'admin'; // Default to 'admin'
  String _selectedTemplate = 'Custom'; // Default to custom
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generatedPassword = PasswordGeneratorService.generateSecurePassword();
    // Initialize all permissions to false
    for (var module in AdminModule.values) {
      _selectedPermissions[module.name] = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _generatedPassword = PasswordGeneratorService.generateSecurePassword();
    });
  }

  void _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied to clipboard')),
      );
    }
  }

  Future<void> _createAdmin() async {
    if (_emailController.text.isEmpty || _displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final createAdminAsync = ref.read(
        createAdminProvider((
          email: _emailController.text.trim(),
          displayName: _displayNameController.text.trim(),
          role: _selectedRole,
          permissions: _selectedPermissions,
        )),
      );

      await createAdminAsync.when(
        data: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin created: ${result['adminId']}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const Divider(),

                // Email field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'admin@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                // Display name field
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'John Doe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),

                // Role selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Text(
                      'Admin Role',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Container(
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
                    ),
                  ],
                ),

                // Password section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Text(
                      'Temporary Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: SelectableText(
                              _generatedPassword,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyPassword,
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy',
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate'),
                    ),
                  ],
                ),

                // Permissions section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    const Text(
                      'Module Permissions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: AdminModule.values.map((module) {
                          final isChecked =
                              _selectedPermissions[module.name] ?? false;

                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                _selectedPermissions[module.name] =
                                    value ?? false;
                              });
                            },
                            title: Text(
                              module.displayName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              module.description,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                // Action buttons
                Row(
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createAdmin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Admin'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
