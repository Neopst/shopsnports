import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth/forgot_password';
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() => _loading = true);
    Object? error;
    try {
      await ref.read(authActionsProvider).sendPasswordReset(email);
    } on Exception catch (e) {
      error = e;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Reset email sent. Check your inbox.')));
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
                'Enter your account email to receive reset instructions.'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendReset,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
