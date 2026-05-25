import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A small screen that polls the current Firebase user for email verification
/// and redirects to [targetRoute] once verified. Useful after registration
/// to auto-advance users once they confirm their email.
class EmailVerifyWaitScreen extends StatefulWidget {
  final String targetRoute;
  const EmailVerifyWaitScreen({super.key, required this.targetRoute});

  @override
  State<EmailVerifyWaitScreen> createState() => _EmailVerifyWaitScreenState();
}

class _EmailVerifyWaitScreenState extends State<EmailVerifyWaitScreen> {
  Timer? _timer;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final updated = FirebaseAuth.instance.currentUser;
      if (updated != null && updated.emailVerified) {
        setState(() => _verified = true);
        _timer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(widget.targetRoute);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Center(
        child: _verified
            ? const Text('Verified — redirecting...')
            : const Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Waiting for email verification...')
              ]),
      ),
    );
  }
}
