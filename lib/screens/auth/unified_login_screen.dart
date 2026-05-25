import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/screens/phone_login_screen.dart';

/// Unified Login Screen with Email, Phone, and Google signin options
/// Consolidated from multiple auth screens into one clean interface
class UnifiedLoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/login';

  const UnifiedLoginScreen({super.key});

  @override
  ConsumerState<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends ConsumerState<UnifiedLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _pwdCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  void _showResetDialog() async {
    final resetEmailCtl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: resetEmailCtl,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailCtl.text.trim();
              if (email.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                }
                return;
              }

              Navigator.of(ctx).pop();

              try {
                await ref.read(authActionsProvider).sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Password reset email sent. Check your inbox.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    final email = _emailCtl.text.trim();
    final password = _pwdCtl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await ref.read(authActionsProvider).signIn(email, password);
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in successful')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);

    try {
      final user = await ref.read(authActionsProvider).signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in successful')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        title: const Text('Sign In'),
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
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Tab bar for Email and Phone
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Email', icon: Icon(Icons.email_outlined)),
                        Tab(
                          text: 'Phone',
                          icon: Icon(Icons.phone_android_outlined),
                        ),
                      ],
                      labelColor: theme.primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: theme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tab content
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Email tab
                        _EmailLoginForm(
                          emailCtl: _emailCtl,
                          pwdCtl: _pwdCtl,
                          obscurePassword: _obscurePassword,
                          loading: _loading,
                          onTogglePassword: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          onSignIn: _signInWithEmail,
                          onForgotPassword: _showResetDialog,
                        ),
                        // Phone tab
                        _PhoneLoginForm(
                          loading: _loading,
                          onNavigateToPhone: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PhoneLoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Divider
                  const Divider(height: 1),

                  const SizedBox(height: 24),

                  // Google sign-in
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
                        'Sign in with Google',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: _loading ? null : _signInWithGoogle,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Don\'t have an account? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/auth/signup');
                          },
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Become Affiliate CTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Become an Affiliate'),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/affiliate/intro');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.primaryColor, width: 1.5),
                      ),
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

/// Email login form widget
class _EmailLoginForm extends StatelessWidget {
  final TextEditingController emailCtl;
  final TextEditingController pwdCtl;
  final bool obscurePassword;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;

  const _EmailLoginForm({
    required this.emailCtl,
    required this.pwdCtl,
    required this.obscurePassword,
    required this.loading,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('authEmailField'),
          controller: emailCtl,
          enabled: !loading,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('authPasswordField'),
          controller: pwdCtl,
          enabled: !loading,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            key: const Key('authSubmitSignIn'),
            onPressed: loading ? null : onSignIn,
            child: loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }
}

/// Phone login form widget
class _PhoneLoginForm extends StatelessWidget {
  final bool loading;
  final VoidCallback onNavigateToPhone;

  const _PhoneLoginForm({
    required this.loading,
    required this.onNavigateToPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.phone_in_talk_outlined,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        const Text(
          'Sign in with OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Receive a one-time password (OTP) via SMS to your phone number',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onNavigateToPhone,
            icon: const Icon(Icons.phone_android_outlined),
            label: const Text('Continue with Phone'),
          ),
        ),
      ],
    );
  }
}
