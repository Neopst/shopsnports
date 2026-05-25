import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';
import 'package:shopsnports/providers/super_admin_provider.dart';

/// Dialog for creating a new sub-admin
/// Only accessible by super admin
class CreateSubAdminDialog extends ConsumerStatefulWidget {
  const CreateSubAdminDialog({super.key});

  @override
  ConsumerState<CreateSubAdminDialog> createState() =>
      _CreateSubAdminDialogState();
}

class _CreateSubAdminDialogState extends ConsumerState<CreateSubAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _notesController = TextEditingController();

  bool _sendWelcomeEmail = true;
  List<AdminPermission> _selectedPermissions = [];
  bool _isLoading = false;

  // Predefined permission sets for quick selection
  DefaultPermissionSet? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPermissions =
        DefaultPermissionSet.shippingManager.permissions.toList();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPreset(DefaultPermissionSet preset) {
    setState(() {
      _selectedPreset = preset;
      _selectedPermissions = List.from(preset.permissions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text('Create Sub-Admin'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Permission Presets
              const Text(
                'Permission Preset',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<DefaultPermissionSet>(
                initialValue: _selectedPreset,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: DefaultPermissionSet.presets.map((preset) {
                  return DropdownMenuItem(
                    value: preset,
                    child: Text(preset.name),
                  );
                }).toList(),
                onChanged: (value) => _applyPreset(value!),
              ),
              const SizedBox(height: 20),

              // Selected Permissions
              const Text(
                'Selected Permissions (${0})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedPermissions.isEmpty
                    ? const Text('No permissions selected',
                        style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedPermissions.map((permission) {
                          return Chip(
                            label: Text(
                              permission.displayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedPermissions.remove(permission);
                                _selectedPreset = null;
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // Toggle permission selection
              TextButton.icon(
                onPressed: () => _showPermissionSelector(context),
                icon: const Icon(Icons.edit),
                label: const Text('Customize Permissions'),
              ),
              const SizedBox(height: 16),

              // Email notification option
              CheckboxListTile(
                value: _sendWelcomeEmail,
                onChanged: (value) {
                  setState(() => _sendWelcomeEmail = value ?? true);
                },
                title: const Text('Send welcome email with login details'),
                secondary: const Icon(Icons.email),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isLoading ? null : _createSubAdmin,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create Sub-Admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showPermissionSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PermissionSelectorDialog(
        selectedPermissions: _selectedPermissions,
        onChanged: (permissions) {
          setState(() {
            _selectedPermissions = permissions;
            _selectedPreset = null;
          });
        },
      ),
    );
  }

  Future<void> _createSubAdmin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(createSubAdminProvider((
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        permissions: _selectedPermissions,
        sendWelcomeEmail: _sendWelcomeEmail,
      )).future);

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success dialog with credentials
        showDialog(
          context: context,
          builder: (context) => SubAdminCreatedDialog(
            email: _emailController.text.trim(),
            tempPassword: result.tempPassword,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog showing created sub-admin credentials
class SubAdminCreatedDialog extends StatelessWidget {
  final String email;
  final String tempPassword;

  const SubAdminCreatedDialog({
    super.key,
    required this.email,
    required this.tempPassword,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('Sub-Admin Created'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'The sub-admin account has been created successfully.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login Credentials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Email: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: SelectableText(
                        email,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Password: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: SelectableText(
                        tempPassword,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '⚠️ Please copy the password now. It will not be shown again.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close this dialog
            Navigator.pop(context); // Close create dialog
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Dialog for selecting permissions
class PermissionSelectorDialog extends StatefulWidget {
  final List<AdminPermission> selectedPermissions;
  final Function(List<AdminPermission>) onChanged;

  const PermissionSelectorDialog({
    super.key,
    required this.selectedPermissions,
    required this.onChanged,
  });

  @override
  State<PermissionSelectorDialog> createState() =>
      _PermissionSelectorDialogState();
}

class _PermissionSelectorDialogState
    extends State<PermissionSelectorDialog> {
  late List<AdminPermission> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = List.from(widget.selectedPermissions);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Permissions'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: ListView.builder(
          itemCount: PermissionGroup.allGroups.length,
          itemBuilder: (context, index) {
            final group = PermissionGroup.allGroups[index];
            final allSelected =
                group.permissions.every((p) => _permissions.contains(p));

            return ExpansionTile(
              title: Text(group.name),
              leading: Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _permissions.addAll(group.permissions);
                    } else {
                      _permissions
                          .removeWhere((p) => group.permissions.contains(p));
                    }
                    widget.onChanged(_permissions);
                  });
                },
              ),
              children: group.permissions.map((permission) {
                return CheckboxListTile(
                  title: Text(
                    permission.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: _permissions.contains(permission),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _permissions.add(permission);
                      } else {
                        _permissions.remove(permission);
                      }
                      widget.onChanged(_permissions);
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}