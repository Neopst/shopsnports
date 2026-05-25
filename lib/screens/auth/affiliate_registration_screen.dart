import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/utils/countries.dart';
import 'package:shopsnports/widgets/country_phone_field.dart';

class AffiliateRegistrationScreen extends ConsumerStatefulWidget {
  const AffiliateRegistrationScreen({super.key});

  @override
  ConsumerState<AffiliateRegistrationScreen> createState() =>
      _AffiliateRegistrationScreenState();
}

class _AffiliateRegistrationScreenState
    extends ConsumerState<AffiliateRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _passwordConfirmCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _companyCtl = TextEditingController();
  final _websiteCtl = TextEditingController();
  final _taxCtl = TextEditingController();
  final _bankAcctCtl = TextEditingController();
  final _bankNameCtl = TextEditingController();

  late CountryData _selectedCountry;

  bool _agree = false;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hidePasswordConfirm = true;

  @override
  void initState() {
    super.initState();
    _selectedCountry = getDefaultCountry(); // Default to Nigeria
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _passwordConfirmCtl.dispose();
    _phoneCtl.dispose();
    _companyCtl.dispose();
    _websiteCtl.dispose();
    _taxCtl.dispose();
    _bankAcctCtl.dispose();
    _bankNameCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the affiliate terms.')));
      return;
    }
    if (_passwordCtl.text != _passwordConfirmCtl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    setState(() => _loading = true);
    try {
      // Register affiliate with auto-approval: creates user + affiliate profile immediately
      final repo = ref.read(userRepositoryProvider);

      // Construct full phone with country code if provided
      final fullPhone = _phoneCtl.text.trim().isEmpty
          ? null
          : '${_selectedCountry.code}${_phoneCtl.text.trim()}';

      await repo.registerAsAffiliate(
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
        name: _nameCtl.text.trim(),
        phone: fullPhone,
        businessName:
            _companyCtl.text.trim().isEmpty ? null : _companyCtl.text.trim(),
        taxId: _taxCtl.text.trim().isEmpty ? null : _taxCtl.text.trim(),
        bankName:
            _bankNameCtl.text.trim().isEmpty ? null : _bankNameCtl.text.trim(),
        accountNumber:
            _bankAcctCtl.text.trim().isEmpty ? null : _bankAcctCtl.text.trim(),
        countryCode: _selectedCountry.isoCode,
      );

      if (mounted) {
        // Show success dialog - account is pending approval
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Application Submitted!'),
            content: const Text(
              'Your affiliate application has been submitted successfully. '
              'Your account is currently pending review by our team. '
              'You will receive an email notification once your application is approved. '
              'This typically takes 1-2 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Decorative Lottie animation for affiliate program
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Lottie.asset(
                            'assets/animations/affiliate.json',
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                            // Add a semantic label for accessibility
                            options: LottieOptions(enableMergePaths: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Join our affiliate program',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_name'),
                        controller: _nameCtl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Your legal or business name',
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_email'),
                        controller: _emailCtl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          final s = v ?? '';
                          if (s.isEmpty) return 'Enter your email';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(s)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_password'),
                        controller: _passwordCtl,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'At least 6 characters',
                          suffixIcon: IconButton(
                            icon: Icon(_hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Enter a password';
                          if ((v ?? '').length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_password_confirm'),
                        controller: _passwordConfirmCtl,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Re-enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(_hidePasswordConfirm
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _hidePasswordConfirm = !_hidePasswordConfirm),
                          ),
                        ),
                        obscureText: _hidePasswordConfirm,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Confirm your password';
                          if (v != _passwordCtl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Phone field with country code (searchable)
                      CountryPhoneField(
                        phoneController: _phoneCtl,
                        initialCountry: _selectedCountry,
                        onCountryChanged: (country) {
                          setState(() => _selectedCountry = country);
                        },
                        label: 'Phone (optional)',
                        hintText: 'Enter phone number',
                        readOnly: _loading,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_company'),
                        controller: _companyCtl,
                        decoration: const InputDecoration(
                            labelText: 'Company / Brand (optional)'),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.organizationName],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_website'),
                        controller: _websiteCtl,
                        decoration: const InputDecoration(
                            labelText: 'Website / Social (optional)'),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.url],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_taxid'),
                        controller: _taxCtl,
                        decoration: const InputDecoration(
                            labelText: 'Tax ID / VAT number (optional)'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Payout details',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_bank_name'),
                        controller: _bankNameCtl,
                        decoration: const InputDecoration(
                            labelText: 'Bank name (or PayPal)'),
                        textInputAction: TextInputAction.next,
                        // No reliable autofill hint for bank name across SDKs;
                        // omit autofillHints for wider compatibility.
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('affiliate_bank_account'),
                        controller: _bankAcctCtl,
                        decoration: const InputDecoration(
                            labelText: 'Account number / PayPal email'),
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.username],
                      ),
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
                      Row(children: [
                        Semantics(
                          container: true,
                          label: 'Agree to affiliate terms',
                          child: Checkbox(
                              key: const Key('affiliate_agree'),
                              value: _agree,
                              onChanged: (v) =>
                                  setState(() => _agree = v ?? false)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text(
                                'I agree to the affiliate terms and payouts policy'))
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('affiliate_submit'),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Submit application'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(
                          height: 80), // Extra space to avoid navbar overlap
                    ],
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
