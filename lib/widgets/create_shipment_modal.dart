import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mock_affiliate_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/affiliate_api_provider.dart';

class CreateShipmentModal extends ConsumerStatefulWidget {
  final String affiliateId;
  final MockAffiliateService service;
  const CreateShipmentModal(
      {super.key, required this.affiliateId, required this.service});

  @override
  ConsumerState<CreateShipmentModal> createState() =>
      _CreateShipmentModalState();
}

class _CreateShipmentModalState extends ConsumerState<CreateShipmentModal> {
  bool _isGenerating = false;
  String? _generatedUrl;
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _itemCtl = TextEditingController();
  final _quantityCtl = TextEditingController(text: '1');
  final _addressCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  bool _sendingOnBehalf = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _itemCtl.dispose();
    _quantityCtl.dispose();
    _addressCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create shipment link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Generate a private link to share with your client. The client will fill a short form.'),
              const SizedBox(height: 12),
              if (_generatedUrl == null) ...[
                TextField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'Client name (optional)'),
                  key: const Key('client_name_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(
                      labelText: 'Client email (optional)'),
                  key: const Key('client_email_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtl,
                  decoration: const InputDecoration(
                      labelText: 'Client phone (optional)'),
                  key: const Key('client_phone_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _itemCtl,
                  decoration: const InputDecoration(labelText: 'Item'),
                  key: const Key('item_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityCtl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  key: const Key('quantity_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressCtl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  key: const Key('address_field'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtl,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 3,
                  key: const Key('notes_field'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  key: const Key('create_shipment_button'),
                  onPressed: _isGenerating ? null : _onCreate,
                  icon: const Icon(Icons.link),
                  label:
                      Text(_isGenerating ? 'Generating...' : 'Generate link'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('preview_shipment_button'),
                  onPressed: _isGenerating ? null : _onPreview,
                  child: const Text('Preview form'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  key: const Key('send_on_behalf_button'),
                  onPressed: _sendingOnBehalf ? null : _onSendOnBehalf,
                  icon: const Icon(Icons.send),
                  label:
                      Text(_sendingOnBehalf ? 'Sending...' : 'Send on behalf'),
                ),
              ] else ...[
                SelectableText(_generatedUrl!,
                    key: const Key('generated_link_text')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('copy_link_button'),
                        onPressed: () => _copyToClipboard(
                            _generatedUrl!, ScaffoldMessenger.of(context)),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy link'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('share_link_button'),
                        onPressed: () => _shareLink(_generatedUrl!,
                            messenger: ScaffoldMessenger.of(context)),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // QR placeholder; replace with qr_flutter for a real QR
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Center(
                      child:
                          Text('QR preview (install qr_flutter for real QR)')),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('close_generated_button'),
                  onPressed: () => Navigator.of(context).pop(_generatedUrl),
                  child: const Text('Done'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSendOnBehalf() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingOnBehalf = true);
    final client = {
      'name': _nameCtl.text.trim(),
      'email': _emailCtl.text.trim(),
      'phone': _phoneCtl.text.trim(),
      'item': _itemCtl.text.trim(),
      'quantity': int.tryParse(_quantityCtl.text) ?? 1,
      'address': _addressCtl.text.trim(),
      'notes': _notesCtl.text.trim(),
    };
    try {
      Map<String, dynamic> resp;
      final api = ref.read(affiliateApiProvider);
      if (kDebugMode) {
        try {
          resp = await api.createShipmentOnBehalf(
              affiliateId: widget.affiliateId, client: client);
        } catch (_) {
          resp = await widget.service.createShipmentOnBehalf(
              affiliateId: widget.affiliateId, client: client);
        }
      } else {
        resp = await widget.service.createShipmentOnBehalf(
            affiliateId: widget.affiliateId, client: client);
      }

      final link = resp['link'] as String? ?? resp['url'] as String?;
      if (link != null && mounted) {
        await _shareLink(link, messenger: messenger);
        setState(() => _generatedUrl = link);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sendingOnBehalf = false);
    }
  }

  Future<void> _onCreate() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGenerating = true);
    String url;
    try {
      final api = ref.read(affiliateApiProvider);
      if (kDebugMode) {
        try {
          url = await api.createShipmentLink(affiliateId: widget.affiliateId);
        } catch (_) {
          url = await widget.service
              .createShipmentLink(affiliateId: widget.affiliateId);
        }
      } else {
        url = await widget.service
            .createShipmentLink(affiliateId: widget.affiliateId);
      }
      setState(() {
        _isGenerating = false;
        _generatedUrl = url;
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Generate failed: $e')));
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _onPreview() {
    Future<void> openPreview() async {
      final messenger = ScaffoldMessenger.of(context);
      String? url = _generatedUrl;
      if (url == null) {
        // generate one quickly
        final api = ref.read(affiliateApiProvider);
        try {
          url = await api.createShipmentLink(affiliateId: widget.affiliateId);
          if (mounted) setState(() => _generatedUrl = url);
        } catch (_) {
          url = null;
        }
      }
      if (url == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Unable to generate preview')));
        return;
      }

      // instead of navigating away, show a preview dialog with current fields
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preview shipment request'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client: ${_nameCtl.text}'),
                Text('Email: ${_emailCtl.text}'),
                Text('Phone: ${_phoneCtl.text}'),
                const SizedBox(height: 8),
                Text('Item: ${_itemCtl.text}'),
                Text('Quantity: ${_quantityCtl.text}'),
                const SizedBox(height: 8),
                Text('Address: ${_addressCtl.text}'),
                const SizedBox(height: 8),
                Text('Notes: ${_notesCtl.text}'),
                const SizedBox(height: 12),
                SelectableText(url ?? '',
                    key: const Key('preview_generated_link')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close')),
            ElevatedButton(
                onPressed: () {
                  // open public form in app (extract token)
                  final uri = Uri.tryParse(url!);
                  final token = uri?.queryParameters['token'];
                  Navigator.of(ctx).pop();
                  if (token != null && mounted) {
                    Navigator.of(context).pushNamed('/public/shipment-request',
                        arguments: {'token': token});
                  } else {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Preview navigation not available')));
                  }
                },
                child: const Text('Open public form'))
          ],
        ),
      );
    }

    openPreview();
  }

  Future<void> _copyToClipboard(
      String link, ScaffoldMessengerState messenger) async {
    await Clipboard.setData(ClipboardData(text: link));
    messenger.showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')));
  }

  Future<void> _shareLink(String link,
      {required ScaffoldMessengerState messenger}) async {
    // Try to open native share via URL launcher as a fallback to mailto for email.
    final encoded =
        Uri.encodeComponent('Please fill this short shipment request: $link');
    final mailto = Uri.parse('mailto:?subject=Shipment request&body=$encoded');
    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
      return;
    }
    // Last-resort: copy to clipboard
    await _copyToClipboard(link, messenger);
  }
}
