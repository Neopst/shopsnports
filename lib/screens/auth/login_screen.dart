import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/providers/active_role_provider.dart';
import 'package:shopsnports/screens/auth/registration_type_screen.dart';
import 'package:shopsnports/screens/phone_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailCtl = TextEditingController();
  final TextEditingController pwdCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> showResetDialog() async {
    emailCtl.text = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailCtl,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtl.text.trim();
              if (email.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your email')));
                }
                return;
              }
              Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sending reset email...')));
              }
              try {
                await ref.read(authActionsProvider).sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reset email sent. Check your inbox.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewPadding.bottom + 16,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App logo (slightly reduced so form sits above bottom nav)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Image.asset('assets/images/logo.png',
                                height: 300, fit: BoxFit.contain),
                          ),
                        ),
                        TextField(
                          key: const Key('authEmailField'),
                          controller: emailCtl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            key: const Key('authPasswordField'),
                            controller: pwdCtl,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) async {
                              if (_loading) return;
                              final email = emailCtl.text.trim();
                              final pwd = pwdCtl.text;
                              if (email.isEmpty || pwd.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Enter email and password')));
                                return;
                              }
                              setState(() => _loading = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              try {
                                final user = await ref
                                    .read(authActionsProvider)
                                    .signIn(email, pwd);
                                if (user != null) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text('Signed in')));

                                  // Auto-redirect based on user role
                                  final route =
                                      ref.read(initialRouteAfterLoginProvider);
                                  navigator.pushNamedAndRemoveUntil(
                                      route, (r) => false);
                                } else {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text('Sign in failed')));
                                }
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        'Sign in error: ${e.toString()}')));
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            }),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Centered Sign in button
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  key: const Key('authSubmitSignIn'),
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          final email = emailCtl.text.trim();
                                          final pwd = pwdCtl.text;
                                          if (email.isEmpty || pwd.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Enter email and password')));
                                            return;
                                          }
                                          setState(() => _loading = true);
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final navigator =
                                              Navigator.of(context);
                                          try {
                                            final user = await ref
                                                .read(authActionsProvider)
                                                .signIn(email, pwd);
                                            if (user != null) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                  const SnackBar(
                                                      content:
                                                          Text('Signed in')));

                                              // Auto-redirect based on user role
                                              final route = ref.read(
                                                  initialRouteAfterLoginProvider);
                                              navigator.pushNamedAndRemoveUntil(
                                                  route, (r) => false);
                                            } else {
                                              messenger.showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Sign in failed')));
                                            }
                                          } catch (e) {
                                            messenger.showSnackBar(SnackBar(
                                                content: Text(
                                                    'Sign in error: ${e.toString()}')));
                                          } finally {
                                            if (mounted) {
                                              setState(() => _loading = false);
                                            }
                                          }
                                        },
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Text('Sign in'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Forgot password below Sign in
                              Center(
                                child: TextButton(
                                  onPressed: showResetDialog,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Prominent Google sign-in
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                            icon: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Text('G',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700)),
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              try {
                                final user = await ref
                                    .read(authActionsProvider)
                                    .signInWithGoogle();
                                if (user != null) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text('Signed in')));
                                  navigator.pushNamedAndRemoveUntil(
                                      '/home', (r) => false);
                                } else {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text('Google sign-in aborted')));
                                }
                              } catch (e) {
                                messenger.showSnackBar(
                                    SnackBar(content: Text(e.toString())));
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Phone sign-in option (OTP)
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone_android_outlined),
                            label: const Text('Sign in with phone'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const PhoneLoginScreen()));
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Don\'t have an account?'),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) =>
                                          const RegistrationTypeScreen()));
                                },
                                child: const Text('Sign up')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
