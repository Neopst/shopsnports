import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/auth_provider.dart';

class AuthSignInScreen extends ConsumerStatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  ConsumerState<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends ConsumerState<AuthSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      onNavTap: (_) {},
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                enabled: !_loading,
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(s)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: !_loading,
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Password is required';
                  if (s.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        setState(() {
                          _loading = true;
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        User? user;
                        Object? error;
                        try {
                          user = await ref.read(authActionsProvider).signIn(
                              _email.text.trim(), _password.text.trim());
                        } on FirebaseAuthException catch (e) {
                          error = e;
                        } catch (e) {
                          error = e;
                        }

                        if (!mounted) return;

                        if (error != null) {
                          if (error is FirebaseAuthException) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(error.message ?? error.code)),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        } else if (user != null) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Signed in')),
                          );
                          nav.maybePop();
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Unable to sign in')),
                          );
                        }

                        if (mounted) {
                          setState(() {
                            _loading = false;
                          });
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
