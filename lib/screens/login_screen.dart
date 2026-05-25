import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:shopsnports/screens/auth/forgot_password_screen.dart';
// registration_screen.dart is not used here; keep import commented to avoid unused import analyzer warning
// import 'package:shopsnports/screens/auth/registration_screen.dart';
import 'package:shopsnports/screens/auth/registration_type_screen.dart';
import 'package:shopsnports/screens/phone_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    Object? error;
    try {
      final user = await ref
          .read(authActionsProvider)
          .signIn(_emailCtl.text.trim(), _passCtl.text);
      if (user != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Signed in')));
        if (mounted) {
          navigator.pop();
        }
      } else {
        error = 'Unable to sign in';
      }
    } catch (e) {
      // detect our email-not-verified FirebaseAuthException
      if (e is FirebaseAuthException && e.code == 'email-not-verified') {
        // offer to resend verification
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final shouldResend = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Email not verified'),
            content: const Text(
                'Your email is not verified. Would you like us to resend the verification email?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Resend')),
            ],
          ),
        );
        if (shouldResend == true) {
          try {
            await ref.read(authActionsProvider).resendEmailVerification();
            if (mounted) {
              messenger.showSnackBar(const SnackBar(
                  content:
                      Text('Verification email resent. Check your inbox.')));
            }
          } catch (inner) {
            if (mounted) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Error: ${inner.toString()}')));
            }
          }
          return;
        }
      }
      error = e;
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      onNavTap: (_) {},
      // Use a compact AppBar with title and back button (default behavior)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Login', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App logo
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Image.asset('assets/images/logo.png',
                                  height: 224, fit: BoxFit.contain),
                            ),
                          ),
                          TextFormField(
                            controller: _emailCtl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = v ?? '';
                              if (s.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(s)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtl,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (v) {
                              if ((v ?? '').isEmpty) {
                                return 'Please enter your password';
                              }
                              if ((v ?? '').length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen())),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign in'),
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Alternative sign-in options
                          // Google sign-in button (uses google_sign_in package)
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white,
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700),
                                ),
                              ),
                              label: const Text('Sign in with Google'),
                              onPressed: () async {
                                setState(() => _loading = true);
                                Object? err;
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                try {
                                  final user = await ref
                                      .read(authActionsProvider)
                                      .signInWithGoogle();
                                  if (user != null) {
                                    messenger.showSnackBar(const SnackBar(
                                        content: Text('Signed in')));
                                    if (mounted) {
                                      navigator.pop();
                                    }
                                  } else {
                                    err = 'Google sign-in aborted';
                                  }
                                } catch (e) {
                                  err = e;
                                }
                                if (!mounted) return;
                                if (err != null) {
                                  messenger.showSnackBar(
                                      SnackBar(content: Text(err.toString())));
                                }
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.phone_android_outlined),
                              label: const Text('Sign in with phone'),
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PhoneLoginScreen())),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Small hint and link to create account
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
                                child: const Text('Sign up'),
                              )
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
      ),
    );
  }
}
