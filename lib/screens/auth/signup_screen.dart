import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/providers/active_role_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/signup';
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final pwd = _passCtl.text;
    final phone = _phoneCtl.text.trim();

    if (name.isEmpty || email.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _loading = true);
    Object? err;
    try {
      final user = await ref
          .read(authActionsProvider)
          .register(name, email, pwd, phone: phone.isEmpty ? null : phone);
      if (user != null) {
        if (!mounted) return;
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Welcome! Verify your email'),
            content: const Text(
                'A verification email has been sent. Please verify your email before signing in.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Close')),
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                    Navigator.of(ctx).pushReplacementNamed('/auth/login');
                  },
                  child: const Text('Go to login')),
            ],
          ),
        );
        if (!mounted) return;
        if (res == true) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      err = e;
    }

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.toString())));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
            TextField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
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
                label: const Text('Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    final user =
                        await ref.read(authActionsProvider).signInWithGoogle();
                    if (user != null) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Signed in')));
                      // Auto-redirect based on user role
                      final route = ref.read(initialRouteAfterLoginProvider);
                      navigator.pushNamedAndRemoveUntil(route, (r) => false);
                    } else {
                      messenger.showSnackBar(const SnackBar(
                          content: Text('Google sign-in aborted')));
                    }
                  } catch (e) {
                    messenger
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
            ),
            TextField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextField(
                controller: _passCtl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextField(
                controller: _phoneCtl,
                decoration: const InputDecoration(
                    labelText: 'Phone (optional)', hintText: '+1234567890'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _register()),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const SizedBox(
                        width: double.infinity,
                        child: Center(child: Text('Sign up')))),
            const SizedBox(height: 20),
            // Affiliate CTA
            OutlinedButton.icon(
              icon: const Icon(Icons.trending_up),
              label: const Text('Become an Affiliate Instead'),
              onPressed: () {
                Navigator.of(context).pushNamed('/affiliate/intro');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
