import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/index.dart';

class PaymentMethodFormDialog extends ConsumerStatefulWidget {
  final PaymentMethod? method;

  const PaymentMethodFormDialog({super.key, this.method});

  @override
  ConsumerState<PaymentMethodFormDialog> createState() =>
      _PaymentMethodFormDialogState();
}

class _PaymentMethodFormDialogState
    extends ConsumerState<PaymentMethodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _secretKeyController;
  late String _type;
  late bool _isEnabled;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method?.name ?? '');
    _apiKeyController = TextEditingController(
      text: widget.method?.apiKey ?? '',
    );
    _secretKeyController = TextEditingController(
      text: widget.method?.secretKey ?? '',
    );
    _type = widget.method?.type ?? 'Stripe';
    _isEnabled = widget.method?.isEnabled ?? true;
    _isDefault = widget.method?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.method == null
                        ? 'Add Payment Method'
                        : 'Edit Payment Method',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider Type
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Payment Provider *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: ['Stripe', 'Paystack', 'Flutterwave']
                            .map(
                              (provider) => DropdownMenuItem(
                                value: provider,
                                child: Text(provider),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _type = value;
                              _nameController.text = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Display Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // API Key / Public Key
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: _type == 'Stripe'
                              ? 'Publishable Key *'
                              : 'Public Key *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.key),
                          hintText: _type == 'Stripe'
                              ? 'pk_live_...'
                              : _type == 'Paystack'
                              ? 'pk_live_...'
                              : 'FLWPUBK-...',
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'API Key is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Secret Key
                      TextFormField(
                        controller: _secretKeyController,
                        decoration: InputDecoration(
                          labelText: 'Secret Key *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          hintText: _type == 'Stripe'
                              ? 'sk_live_...'
                              : _type == 'Paystack'
                              ? 'sk_live_...'
                              : 'FLWSECK-...',
                        ),
                        obscureText: true,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Secret Key is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _type == 'Stripe'
                                    ? 'Get your keys from: dashboard.stripe.com/apikeys'
                                    : _type == 'Paystack'
                                    ? 'Get your keys from: dashboard.paystack.com/#/settings/developer'
                                    : 'Get your keys from: dashboard.flutterwave.com/settings/apis',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Switches
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        subtitle: const Text(
                          'Make this payment method available',
                        ),
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() => _isEnabled = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set as Default'),
                        subtitle: const Text('Primary payment method'),
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() => _isDefault = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveMethod,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Method'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMethod() {
    if (_formKey.currentState?.validate() ?? false) {
      final method = PaymentMethod(
        id:
            widget.method?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _type,
        isEnabled: _isEnabled,
        isDefault: _isDefault,
        apiKey: _apiKeyController.text,
        secretKey: _secretKeyController.text,
        createdAt: widget.method?.createdAt ?? DateTime.now(),
      );

      Navigator.pop(context, method);
    }
  }
}
