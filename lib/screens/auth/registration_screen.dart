import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopsnports/screens/auth/login_screen.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  static const routeName = '/register';

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _officeCtl = TextEditingController();
  final _mobileCtl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _role = 'customer';

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    _phoneCtl.dispose();
    _officeCtl.dispose();
    _mobileCtl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Object? err;
    try {
      final user = await ref.read(authActionsProvider).register(
            _nameCtl.text.trim(),
            _emailCtl.text.trim(),
            _passCtl.text,
            phone: _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
            officePhone:
                _officeCtl.text.trim().isEmpty ? null : _officeCtl.text.trim(),
            mobilePhone:
                _mobileCtl.text.trim().isEmpty ? null : _mobileCtl.text.trim(),
            role: _role,
          );
      if (user != null) {
        if (mounted) {
          // Show dialog and let user choose next action. If the dialog actions
          // don't perform navigation (just close), we will navigate based on role.
          final navigator = Navigator.of(context);
          final res = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Welcome! Verify your email'),
              content: const Text(
                  'A verification email was sent to your address. Please verify your email before signing in.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Close')),
                if (_role == 'vendor')
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                        Navigator.of(ctx)
                            .pushReplacementNamed('/auth/vendor_register');
                      },
                      child: const Text('Complete vendor profile')),
                if (_role == 'affiliate')
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                        Navigator.of(ctx)
                            .pushReplacementNamed('/auth/affiliate_register');
                      },
                      child: const Text('Complete affiliate profile')),
                TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(true);
                      // Navigate to login screen so the user can sign in after verification
                      Navigator.of(ctx)
                          .pushReplacementNamed(LoginScreen.routeName);
                    },
                    child: const Text('Go to login')),
              ],
            ),
          );

          // If dialog returned false (user just closed), navigate based on role.
          if (res == false) {
            if (_role == 'customer' || _role == 'shipper') {
              navigator.pushReplacementNamed('/profile');
            } else if (_role == 'vendor') {
              navigator.pushReplacementNamed('/vendor/dashboard');
            } else if (_role == 'affiliate') {
              // Affiliates require admin approval before accessing the
              // affiliate dashboard. Send them to a pending screen.
              navigator.pushReplacementNamed('/affiliate/pending');
            }
          }
        }
      } else {
        err = 'Registration failed';
      }
    } on FirebaseAuthException catch (e) {
      // Friendly messages for common auth errors
      switch (e.code) {
        case 'email-already-in-use':
          err = 'An account already exists for that email.';
          break;
        case 'weak-password':
          err = 'The password is too weak. Choose a stronger password.';
          break;
        case 'invalid-email':
          err = 'The email address is invalid.';
          break;
        default:
          err = e.message ?? e.code;
      }
    } catch (e) {
      err = e.toString();
    }
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  String _generatePassword({int length = 12}) {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = '!@#\$%&*()-_=+[]{}<>?';
    const all = upper + lower + digits + symbols;
    final rand = Random.secure();
    final chars = <int>[];
    // ensure at least one of each
    chars.add(upper.codeUnitAt(rand.nextInt(upper.length)));
    chars.add(lower.codeUnitAt(rand.nextInt(lower.length)));
    chars.add(digits.codeUnitAt(rand.nextInt(digits.length)));
    chars.add(symbols.codeUnitAt(rand.nextInt(symbols.length)));
    for (var i = chars.length; i < length; i++) {
      chars.add(all.codeUnitAt(rand.nextInt(all.length)));
    }
    chars.shuffle(rand);
    return String.fromCharCodes(chars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Google Sign-in option (also allow quick signup)
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
                      'Continue with Google',
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
                          messenger.showSnackBar(
                              const SnackBar(content: Text('Signed in')));
                          navigator.pushNamedAndRemoveUntil(
                              '/profile', (r) => false);
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
                // Large centered logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Join ShopsNports',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('authNameField'),
                            controller: _nameCtl,
                            decoration:
                                const InputDecoration(labelText: 'Full name'),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('authEmailField'),
                            controller: _emailCtl,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
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
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('authPasswordField'),
                                  controller: _passCtl,
                                  decoration: InputDecoration(
                                      labelText: 'Password',
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePass
                                            ? Icons.visibility_off
                                            : Icons.visibility),
                                        onPressed: () => setState(() {
                                          _obscurePass = !_obscurePass;
                                        }),
                                      )),
                                  obscureText: _obscurePass,
                                  validator: (v) {
                                    final s = v ?? '';
                                    if (s.isEmpty) {
                                      return 'Enter a password';
                                    }
                                    if (s.length < 6) {
                                      return 'Minimum 6 chars';
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(s)) {
                                      return 'Include at least one uppercase letter';
                                    }
                                    if (!RegExp(r'\d').hasMatch(s)) {
                                      return 'Include at least one number';
                                    }
                                    if (!RegExp(r'[!@#\$%&*()\-_=+\[\]{}<>?]')
                                        .hasMatch(s)) {
                                      return 'Include at least one symbol';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final pw = _generatePassword();
                                  _passCtl.text = pw;
                                  _confirmCtl.text = pw;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Password generated and filled')));
                                },
                                child: const Text('Generate'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('authConfirmField'),
                            controller: _confirmCtl,
                            decoration: InputDecoration(
                                labelText: 'Confirm password',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  }),
                                )),
                            obscureText: _obscureConfirm,
                            validator: (v) {
                              if ((v ?? '') != _passCtl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtl,
                            decoration: const InputDecoration(
                                labelText: 'Phone (optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _officeCtl,
                            decoration: const InputDecoration(
                                labelText: 'Office phone (optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _mobileCtl,
                            decoration: const InputDecoration(
                                labelText: 'Mobile phone (optional)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          // Role selector (Customer / Shipper)
                          SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment(
                                  value: 'customer', label: Text('Customer')),
                              ButtonSegment(
                                  value: 'shipper', label: Text('Shipper')),
                            ],
                            selected: <String>{_role},
                            onSelectionChanged: (newSelection) {
                              if (newSelection.isNotEmpty) {
                                setState(() => _role = newSelection.first);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: Semantics(
                              label: 'Create account',
                              button: true,
                              child: ElevatedButton(
                                key: const Key('authSubmitRegister'),
                                onPressed: _loading ? null : _register,
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Create account'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
