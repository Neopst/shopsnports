import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/models/user_role.dart';
import 'package:shopsnports/utils/countries.dart';
import 'package:shopsnports/widgets/country_phone_field.dart';
import 'package:shopsnports/widgets/stylish_widgets.dart';
import 'package:shopsnports/styles/colors.dart';

/// Stylish Signup Screen with gradient buttons and modern UI
class StylishSignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/signup';

  final UserRole? initialRole;

  const StylishSignupScreen({
    super.key,
    this.initialRole,
  });

  @override
  ConsumerState<StylishSignupScreen> createState() =>
      _StylishSignupScreenState();
}

class _StylishSignupScreenState extends ConsumerState<StylishSignupScreen> {
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _pwdCtl = TextEditingController();
  final TextEditingController _confirmPwdCtl = TextEditingController();

  late CountryData _selectedCountry;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _agreedToTerms = false;

  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedCountry = getDefaultCountry();
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

    if (email.isEmpty || !email.contains('@')) {
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
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

    setState(() => _googleLoading = true);

    try {
      final user = await ref.read(authActionsProvider).signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
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
        setState(() => _googleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Logo with shadow
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join ShopsNports today',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Role Selection (only show if no initial role passed)
                    if (_selectedRole == null) ...[
                      Text(
                        'I want to...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              role: UserRole.customer,
                              isSelected: _selectedRole == UserRole.customer,
                              onTap: () => setState(() => _selectedRole = UserRole.customer),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleCard(
                              role: UserRole.affiliate,
                              isSelected: _selectedRole == UserRole.affiliate,
                              onTap: () => setState(() => _selectedRole = UserRole.affiliate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Account Details Form
                    if (_selectedRole != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            StylishTextField(
                              controller: _nameCtl,
                              label: 'Full Name',
                              hint: 'John Doe',
                              prefixIcon: Icons.person_outlined,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 16),
                            StylishTextField(
                              controller: _emailCtl,
                              label: 'Email Address',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            StylishTextField(
                              controller: _pwdCtl,
                              label: 'Password (min. 6 characters)',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              enabled: !_loading,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.muted,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            StylishTextField(
                              controller: _confirmPwdCtl,
                              label: 'Confirm Password',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscureConfirm,
                              enabled: !_loading,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.muted,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Terms checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: _loading
                                      ? null
                                      : (val) {
                                          setState(() => _agreedToTerms = val ?? false);
                                        },
                                  activeColor: AppColors.primary,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _agreedToTerms = !_agreedToTerms);
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                                        children: [
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' and ', style: TextStyle(color: AppColors.muted)),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign up button
                      GradientButton(
                        text: 'Create Account',
                        onPressed: _loading ? null : _signUpWithEmail,
                        isLoading: _loading,
                        icon: Icons.person_add,
                      ),

                      const SizedBox(height: 20),

                      // Or divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Or', style: TextStyle(color: AppColors.muted)),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google signup
                      SocialLoginButton(
                        label: 'Sign up with Google',
                        icon: Icons.g_translate,
                        color: Colors.red.shade700,
                        onPressed: _signUpWithGoogle,
                        isLoading: _googleLoading,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/auth/login');
                          },
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              role.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              role.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role.description,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(
                Icons.add_circle_outline,
                color: AppColors.muted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}