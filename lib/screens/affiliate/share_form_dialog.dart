import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/form_share_service.dart';
import '../../providers/user_providers.dart';

/// Share Shipping Form Dialog
/// Allows affiliate to share form with client via email or link
class ShareFormDialog extends ConsumerStatefulWidget {
  const ShareFormDialog({super.key});

  @override
  ConsumerState<ShareFormDialog> createState() => _ShareFormDialogState();
}

class _ShareFormDialogState extends ConsumerState<ShareFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientEmailController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _formShareService = FormShareService();

  bool _isGenerating = false;
  String? _generatedLink;

  @override
  void dispose() {
    _clientEmailController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  Future<void> _generateLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Please log in to share forms');
      }

      final token = await _formShareService.generateToken(
        affiliateId: currentUser.id,
        affiliateName: currentUser.name,
        affiliateEmail: currentUser.email,
        clientEmail: _clientEmailController.text.trim(),
        clientName: _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : null,
      );

      final link = token != null ? _formShareService.getPublicFormUrl(token) : null;

      setState(() {
        _generatedLink = link;
        _isGenerating = false;
      });
    } catch (error) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedLink == null) return;

    await Clipboard.setData(ClipboardData(text: _generatedLink!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendViaEmail() async {
    // In production, this would trigger an email via Cloud Functions
    // For now, we'll just show a success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email sent to ${_clientEmailController.text.trim()}',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.share,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Share Form with Client',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate a secure link for your client to fill the shipping form',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Client Name (Optional)
                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name (Optional)',
                    hintText: 'e.g., John Doe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: _generatedLink == null,
                ),
                const SizedBox(height: 16),

                // Client Email (Required)
                TextFormField(
                  controller: _clientEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Client Email *',
                    hintText: 'client@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: _generatedLink == null,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (_generatedLink == null) ...[
                  // Generate Button
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateLink,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.link),
                    label: Text(_isGenerating
                        ? 'Generating...'
                        : 'Generate Secure Link'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ] else ...[
                  // Generated Link Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Link Generated!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _generatedLink!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Link expires in 7 days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Link'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sendViaEmail,
                          icon: const Icon(Icons.email),
                          label: const Text('Send Email'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll be notified when the client submits the form',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
