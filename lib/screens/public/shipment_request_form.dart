import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShipmentRequestFormScreen extends StatefulWidget {
  static const routeName = '/public/shipment-request';
  final String token;
  const ShipmentRequestFormScreen({super.key, required this.token});

  @override
  State<ShipmentRequestFormScreen> createState() =>
      _ShipmentRequestFormScreenState();
}

class _ShipmentRequestFormScreenState extends State<ShipmentRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sender Info
  final _senderNameCtrl = TextEditingController();
  final _senderEmailCtrl = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();
  final _senderAddressCtrl = TextEditingController();

  // Receiver Info
  final _receiverNameCtrl = TextEditingController();
  final _receiverEmailCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _receiverAddressCtrl = TextEditingController();

  // Package Info
  final _descriptionCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  String _freightType = 'air';
  String _priority = 'standard';

  bool _submitting = false;
  String? _trackingNumber;

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderEmailCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _senderAddressCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverEmailCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _receiverAddressCtrl.dispose();
    _descriptionCtrl.dispose();
    _weightCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  /// Generate tracking number: SHP-YYMMDD-XXXXXX
  String _generateTrackingNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix =
        (now.millisecondsSinceEpoch % 1000000).toRadixString(36).toUpperCase();
    return 'SHP-$dateStr-$randomSuffix';
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final trackingNumber = _generateTrackingNumber();
      final now = DateTime.now();

      // Create shipping request document
      await _firestore.collection('shippingRequests').add({
        'trackingNumber': trackingNumber,
        'requesterId': 'guest', // Guest user marker
        'requesterEmail': _senderEmailCtrl.text.trim(),
        'category': 'guest',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),

        // Freight details
        'type': _freightType,
        'priority': _priority,
        'itemDescription': _descriptionCtrl.text.trim(),
        'origin': _originCtrl.text.trim(),
        'destination': _destinationCtrl.text.trim(),
        'weight': double.tryParse(_weightCtrl.text) ?? 0.0,

        // Sender
        'senderName': _senderNameCtrl.text.trim(),
        'senderEmail': _senderEmailCtrl.text.trim(),
        'senderPhone': _senderPhoneCtrl.text.trim(),
        'senderAddress': _senderAddressCtrl.text.trim(),

        // Receiver
        'receiverName': _receiverNameCtrl.text.trim(),
        'receiverEmail': _receiverEmailCtrl.text.trim(),
        'receiverPhone': _receiverPhoneCtrl.text.trim(),
        'receiverAddress': _receiverAddressCtrl.text.trim(),
      });

      setState(() {
        _trackingNumber = trackingNumber;
      });

      if (!mounted) return;
      setState(() => _submitting = false);

      // Show success dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Request Submitted!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Your shipping request has been received. You will receive email updates as your shipment progresses.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tracking Number',
                      style: TextStyle(
                          color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trackingNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Save this tracking number to check your shipment status.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _clearForm() {
    _senderNameCtrl.clear();
    _senderEmailCtrl.clear();
    _senderPhoneCtrl.clear();
    _senderAddressCtrl.clear();
    _receiverNameCtrl.clear();
    _receiverEmailCtrl.clear();
    _receiverPhoneCtrl.clear();
    _receiverAddressCtrl.clear();
    _descriptionCtrl.clear();
    _weightCtrl.clear();
    _originCtrl.clear();
    _destinationCtrl.clear();
    _trackingNumber = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Shipping'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Freight Type Selection
                const Text('Freight Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Air'),
                        value: 'air',
                        groupValue: _freightType,
                        onChanged: (v) =>
                            setState(() => _freightType = v ?? 'air'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Sea'),
                        value: 'sea',
                        groupValue: _freightType,
                        onChanged: (v) =>
                            setState(() => _freightType = v ?? 'sea'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sender Section
                _buildSectionHeader('Sender Information'),
                TextFormField(
                  controller: _senderNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderAddressCtrl,
                  decoration: const InputDecoration(labelText: 'Pickup Address *'),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Receiver Section
                _buildSectionHeader('Receiver Information'),
                TextFormField(
                  controller: _receiverNameCtrl,
                  decoration: const InputDecoration(labelText: 'Receiver Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Receiver Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'Receiver Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverAddressCtrl,
                  decoration: const InputDecoration(labelText: 'Delivery Address *'),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Package Section
                _buildSectionHeader('Package Details'),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Package Description *'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg) *', prefixIcon: Icon(Icons.scale)),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _originCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Origin City/Country *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destinationCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Destination City/Country *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A66),
                      foregroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Shipping Request',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A2A66),
        ),
      ),
    );
  }
}
