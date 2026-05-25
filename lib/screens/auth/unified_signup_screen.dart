import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/models/user_role.dart';
import 'package:shopsnports/utils/countries.dart';
import 'package:shopsnports/widgets/country_phone_field.dart';

/// Unified Signup Screen for creating new accounts
/// Supports Email/Google signup with role selection
class UnifiedSignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/signup';

  final UserRole? initialRole;

  const UnifiedSignupScreen({
    super.key,
    this.initialRole,
  });

  @override
  ConsumerState<UnifiedSignupScreen> createState() =>
      _UnifiedSignupScreenState();
}

class _UnifiedSignupScreenState extends ConsumerState<UnifiedSignupScreen> {
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _pwdCtl = TextEditingController();
  final TextEditingController _confirmPwdCtl = TextEditingController();

  late CountryData _selectedCountry;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreedToTerms = false;

  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedCountry = getDefaultCountry(); // Default to Nigeria
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _pwdCtl.dispose();
    _confirmPwdCtl.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    final pwd = _pwdCtl.text;
    final confirmPwd = _confirmPwdCtl.text;

    if (name.isEmpty) {
      _showError('Please enter your name');
      return false;
    }

    if (email.isEmpty) {
      _showError('Please enter your email');
      return false;
    }

    // Simple email validation: must have @ and a dot after @
    if (!email.contains('@') ||
        !email.substring(email.indexOf('@')).contains('.')) {
      _showError('Please enter a valid email');
      return false;
    }

    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }

    if (pwd.isEmpty || pwd.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }

    if (pwd != confirmPwd) {
      _showError('Passwords do not match');
      return false;
    }

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service');
      return false;
    }

    // Only validate role selection if the UI is shown (no initial role)
    if (_selectedRole == null && widget.initialRole == null) {
      _showError('Please select a role');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _signUpWithEmail() async {
    if (!_validateInputs()) return;

    setState(() => _loading = true);

    try {
      final fullPhone = '${_selectedCountry.code}${_phoneCtl.text.trim()}';
      final user = await ref.read(authActionsProvider).register(
            _nameCtl.text.trim(),
            _emailCtl.text.trim(),
            _pwdCtl.text,
            phone: fullPhone,
          );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        // Store selected role in provider or user profile
        // Then navigate to role-specific dashboard
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (mounted) {
        _showError('Signup failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_selectedRole == null && widget.initialRole == null) {
      _showError('Please select a role first');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await ref.read(authActionsProvider).signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (mounted) {
        _showError('Google signup cancelled');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Section: Role Selection (only show if no initial role passed)
                  if (_selectedRole == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'I want to...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role selection cards
                    for (final role in [UserRole.customer, UserRole.affiliate])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RoleCard(
                          role: role,
                          isSelected: _selectedRole == role,
                          onTap: _loading
                              ? null
                              : () => setState(() => _selectedRole = role),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Section: Account Details
                  if (_selectedRole != null) ...[
                    Text(
                      'Account Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name field
                    TextField(
                      controller: _nameCtl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Email field
                    TextField(
                      controller: _emailCtl,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Phone field with country code (searchable)
                    CountryPhoneField(
                      phoneController: _phoneCtl,
                      initialCountry: _selectedCountry,
                      onCountryChanged: (country) {
                        setState(() => _selectedCountry = country);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      label: 'Phone Number',
                      hintText: 'Enter phone number',
                      readOnly: _loading,
                    ),
                    const SizedBox(height: 12),

                    // Password field
                    TextField(
                      controller: _pwdCtl,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: 'Password (min. 6 characters)',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Confirm password field
                    TextField(
                      controller: _confirmPwdCtl,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            );
                          },
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // Terms agreement checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: _loading
                              ? null
                              : (val) {
                                  setState(() => _agreedToTerms = val ?? false);
                                },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: theme.textTheme.bodySmall,
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: theme.textTheme.bodySmall,
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign up button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signUpWithEmail,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    const Divider(),

                    const SizedBox(height: 20),

                    // Google signup
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade700,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        icon: const Icon(Icons.g_translate),
                        label: const Text(
                          'Sign up with Google',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: _loading ? null : _signUpWithGoogle,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/auth/login');
                          },
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection card widget
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              role.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
