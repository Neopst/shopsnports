import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_permissions.dart';
import '../../services/password_generator_service.dart';
import '../providers/super_admin_providers.dart';

/// Screen for creating a new admin account
/// - Enter admin email and display name
/// - Select module permissions (checkboxes)
/// - Generate temporary password
/// - Copy password to clipboard
/// - Confirm creation (sends email with credentials)
class CreateAdminScreen extends ConsumerStatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  ConsumerState<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends ConsumerState<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();

  late Map<String, bool> _selectedPermissions;
  String? _generatedPassword;
  bool _showPassword = false;
  bool _isCreating = false;
  String _selectedRole = 'admin'; // Default to 'admin'
  String _selectedTemplate = 'Custom'; // Default to custom

  // Email availability checking
  bool _isCheckingEmail = false;
  bool _isEmailAvailable = true;
  String? _emailAvailabilityMessage;
  Timer? _emailDebounce;

  // Confetti animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize permissions with all unchecked (super_admin excluded)
    _selectedPermissions = AdminPermissions.defaultPermissions().permissions;

    // Set up email listener for availability checking
    _emailController.addListener(_onEmailChanged);

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _emailDebounce?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  /// Handle email changes with debounced availability check
  void _onEmailChanged() {
    final email = _emailController.text.trim();

    // Cancel previous debounce
    _emailDebounce?.cancel();

    // Reset state if email is empty
    if (email.isEmpty) {
      setState(() {
        _isCheckingEmail = false;
        _isEmailAvailable = true;
        _emailAvailabilityMessage = null;
      });
      return;
    }

    // Validate email format first
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _isCheckingEmail = false;
        _isEmailAvailable = false;
        _emailAvailabilityMessage = 'Please enter a valid email address';
      });
      return;
    }

    // Start checking with debounce
    setState(() {
      _isCheckingEmail = true;
      _emailAvailabilityMessage = 'Checking email availability...';
    });

    // Debounce for 500ms
    _emailDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkEmailAvailability(email);
    });
  }

  /// Check if email is available
  Future<void> _checkEmailAvailability(String email) async {
    try {
      final repository = ref.read(superAdminRepositoryProvider);
      final isAvailable = await repository.isEmailAvailable(email);

      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = isAvailable;
          _emailAvailabilityMessage = isAvailable
              ? 'Email is available'
              : 'This email is already in use';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = false;
          _emailAvailabilityMessage = 'Error checking email availability';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Admin'), elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic information section
                  _buildSection(
                    title: 'Admin Information',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'admin@shopsnports.com',
                            prefixIcon: const Icon(Icons.email),
                            suffixIcon: _isCheckingEmail
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : _emailAvailabilityMessage != null
                                    ? Icon(
                                        _isEmailAvailable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _isEmailAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _emailAvailabilityMessage != null &&
                                    !_isEmailAvailable &&
                                    _emailController.text.isNotEmpty
                                ? _emailAvailabilityMessage
                                : null,
                            helperText: _emailAvailabilityMessage != null &&
                                    _isEmailAvailable &&
                                    _emailController.text.isNotEmpty
                                ? _emailAvailabilityMessage
                                : null,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                              return 'Please enter a valid email address';
                            }
                            if (!_isEmailAvailable) {
                              return 'This email is already in use';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role selection section
                  _buildSection(
                    title: 'Admin Role',
                    child: Column(
                      children: [
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
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    children: [
                                      Icon(Icons.person_outline, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedRole == 'admin'
                                      ? 'Admins have full access to all assigned modules and can manage sub-admins.'
                                      : 'Sub-admins have limited access to assigned modules only.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Password section
                  _buildSection(
                    title: 'Temporary Password',
                    child: Column(
                      children: [
                        _buildPasswordField(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _generatedPassword == null
                                  ? _generatePassword
                                  : _regeneratePassword,
                              icon: Icon(
                                _generatedPassword == null
                                    ? Icons.vpn_key
                                    : Icons.refresh,
                              ),
                              label: Text(
                                _generatedPassword == null
                                    ? 'Generate Password'
                                    : 'Regenerate',
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_generatedPassword != null)
                              ElevatedButton.icon(
                                onPressed: _copyPassword,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        if (_generatedPassword != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Password Generated',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'This temporary password will be sent via email. Admin must change it on first login.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
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

                  const SizedBox(height: 24),

                  // Permissions section
                  _buildSection(
                    title: 'Module Permissions',
                    child: Column(
                      children: [
                        // Permission templates
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Templates',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                          color: isSelected ? template.color.withValues(alpha:0.2) : Colors.grey.shade100,
                                          border: Border.all(
                                            color: isSelected ? template.color : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              template.icon,
                                              size: 18,
                                              color: isSelected ? template.color : Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
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
                        ),
                        const SizedBox(height: 12),
                        // Permissions list
                        _buildPermissionsList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary section
                  if (_generatedPassword != null &&
                      _selectedPermissions.values.any((v) => v))
                    _buildSection(
                      title: 'Summary',
                      child: Column(
                        children: [
                          _buildSummaryItem(
                            label: 'Email',
                            value: _emailController.text,
                          ),
                          _buildSummaryItem(
                            label: 'Display Name',
                            value: _displayNameController.text,
                          ),
                          _buildSummaryItem(
                            label: 'Role',
                            value: _selectedRole == 'admin' ? 'Admin' : 'Sub-Admin',
                          ),
                          _buildSummaryItem(
                            label: 'Modules Granted',
                            value:
                                '${_selectedPermissions.values.where((v) => v).length} module(s)',
                          ),
                          // Permission preview
                          if (_selectedPermissions.values.any((v) => v))
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Permission Preview',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  ...AdminModule.values
                                      .where((module) =>
                                          _selectedPermissions[module.name] ?? false)
                                      .map((module) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                              top: 4,
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 14,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    module.displayName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCreating
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _createAdmin,
                          child: _isCreating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Creating...'),
                                  ],
                                )
                              : const Text('Create Admin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.5,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Build section wrapper
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }

  /// Build password field
  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generatedPassword ?? 'No password generated yet',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: _generatedPassword != null
                    ? Colors.black
                    : Colors.grey.shade500,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Build permissions list
  Widget _buildPermissionsList() {
    final modules = AdminModule.values;

    return Column(
      children: modules.map((module) {
        final isChecked = _selectedPermissions[module.name] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isChecked ? Colors.blue.shade200 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isChecked ? Colors.blue.shade50 : Colors.transparent,
          ),
          child: CheckboxListTile(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                _selectedPermissions[module.name] = value ?? false;
              });
            },
            title: Text(
              module.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              module.description,
              style: const TextStyle(fontSize: 12),
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  /// Build summary item
  Widget _buildSummaryItem({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Generate password
  void _generatePassword() {
    final password = PasswordGeneratorService.generateSecurePassword();
    setState(() {
      _generatedPassword = password;
    });
  }

  /// Regenerate password
  void _regeneratePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Password'),
        content: const Text(
          'This will generate a new temporary password. The old one will no longer be valid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePassword();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  /// Copy password to clipboard
  void _copyPassword() async {
    if (_generatedPassword != null) {
      await Clipboard.setData(ClipboardData(text: _generatedPassword!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Create admin account
  void _createAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_generatedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a password first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_selectedPermissions.values.any((v) => v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant at least one module permission'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final result = await ref.read(
        createAdminProvider((
          email: _emailController.text.trim(),
          displayName: _displayNameController.text.trim(),
          role: _selectedRole,
          permissions: _selectedPermissions,
        )).future,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Trigger confetti animation
          _confettiController.play();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Admin created successfully. Email verification link sent to ${_emailController.text}',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back after a short delay to show confetti
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to create admin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}