import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  bool _loading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneCtl.dispose();
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    final phone = _phoneCtl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')));
      return;
    }

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    Object? error;
    try {
      final vid =
          await ref.read(authActionsProvider).startPhoneVerification(phone);
      if (!mounted) return;
      if (vid == 'AUTO_SIGN_IN') {
        // Auto-signed-in via phone credential; navigate to home
        messenger.showSnackBar(const SnackBar(content: Text('Signed in')));
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        return;
      }
      _verificationId = vid;
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitCode() async {
    final code = _codeCtl.text.trim();
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please request a verification code first')));
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the SMS code')));
      return;
    }

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    Object? error;
    try {
      final user = await ref
          .read(authActionsProvider)
          .signInWithSmsCode(_verificationId!, code);
      if (!mounted) return;
      if (user != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Signed in')));
        // Clear the navigation stack and go to profile
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profile, (r) => false);
      } else {
        messenger
            .showSnackBar(const SnackBar(content: Text('Unable to sign in')));
      }
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.phone_android,
                size: 64,
                color: Color(0xFF0A2463),
              ),
              const SizedBox(height: 24),
              const Text(
                'Phone Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number to receive a verification code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneCtl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1234567890',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _startVerification,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Request Verification Code'),
                        ),
                ),
              ),
              if (_verificationId != null) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeCtl,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitCode,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Verify Code'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
