import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/screens/phone_login_screen.dart';
import 'package:shopsnports/widgets/stylish_widgets.dart';
import 'package:shopsnports/styles/colors.dart';

/// Stylish Unified Login Screen with gradient buttons and social login
class StylishLoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/login';

  const StylishLoginScreen({super.key});

  @override
  ConsumerState<StylishLoginScreen> createState() => _StylishLoginScreenState();
}

class _StylishLoginScreenState extends ConsumerState<StylishLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _pwdCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Reset Password'),
          ],
        ),
        content: StylishTextField(
          controller: resetEmailCtl,
          label: 'Email Address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GradientButton(
            text: 'Send',
            onPressed: () async {
              final email = resetEmailCtl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email')),
                );
                return;
              }

              Navigator.of(ctx).pop();

              try {
                await ref.read(authActionsProvider).sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent. Check your inbox.'),
                      backgroundColor: Colors.green,
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
            width: 100,
            height: 44,
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
          const SnackBar(
            content: Text('Sign in successful'),
            backgroundColor: Colors.green,
          ),
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
    setState(() => _googleLoading = true);

    try {
      final user = await ref.read(authActionsProvider).signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in successful'),
            backgroundColor: Colors.green,
          ),
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

                    // Welcome text
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue shipping',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Tab bar for Email and Phone
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Email'),
                          Tab(text: 'Phone'),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.muted,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tab content
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
                      child: SizedBox(
                        height: 280,
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
                    ),

                    const SizedBox(height: 28),

                    // Or divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google sign-in
                    SocialLoginButton(
                      label: 'Sign in with Google',
                      icon: Icons.g_translate,
                      color: Colors.red.shade700,
                      onPressed: _signInWithGoogle,
                      isLoading: _googleLoading,
                    ),

                    const SizedBox(height: 20),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/auth/signup');
                          },
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Become Affiliate CTA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.accent.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.trending_up, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Become an Affiliate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Earn commissions on every referral',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/affiliate/intro');
                            },
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
        StylishTextField(
          controller: emailCtl,
          label: 'Email Address',
          hint: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: !loading,
        ),
        const SizedBox(height: 16),
        StylishTextField(
          controller: pwdCtl,
          label: 'Password',
          prefixIcon: Icons.lock_outlined,
          obscureText: obscurePassword,
          enabled: !loading,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.muted,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: Text(
              'Forgot password?',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
        const Spacer(),
        GradientButton(
          text: 'Sign In',
          onPressed: loading ? null : onSignIn,
          isLoading: loading,
          icon: Icons.login,
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_in_talk_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sign in with OTP',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Receive a one-time password (OTP) via SMS',
          style: TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GradientButton(
          text: 'Continue with Phone',
          onPressed: loading ? null : onNavigateToPhone,
          isLoading: loading,
          icon: Icons.phone_android,
        ),
      ],
    );
  }
}