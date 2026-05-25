import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/enums.dart';
import '../../widgets/main_scaffold.dart';
import 'shipping_request_success_screen.dart';

/// Shipping Request Screen (for Affiliates)
/// Admin Dashboard compliant - allows affiliates to submit shipping requests
/// Uses Firestore directly - Firebase is the single source of truth
class ShippingRequestScreen extends ConsumerStatefulWidget {
  const ShippingRequestScreen({super.key});

  @override
  ConsumerState<ShippingRequestScreen> createState() =>
      _ShippingRequestScreenState();
}

class _ShippingRequestScreenState extends ConsumerState<ShippingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ShippingType _type = ShippingType.air;
  final ShippingPriority _priority = ShippingPriority.standard;

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();

  bool _requiresInsurance = false;
  bool _requiresCustoms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      final now = DateTime.now();

      // Generate tracking number
      final dateStr = now.toIso8601String().split('T')[0].replaceAll('-', '');
      final randomSuffix =
          DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
      final trackingNumber = 'SHP-${dateStr.substring(2)}-$randomSuffix';

      // Create shipping request document in Firestore
      await _firestore.collection('shippingRequests').add({
        'requesterId': user?.uid ?? 'guest',
        'affiliateId': user?.uid, // Self-referral for affiliate
        'clientName': _clientNameController.text.trim(),
        'clientEmail': _clientEmailController.text.trim(),
        'clientPhone': _clientPhoneController.text.trim(),
        'type': _type.toJson(),
        'status': 'pending',
        'priority': _priority.toJson(),
        'origin': _originController.text.trim(),
        'destination': _destinationController.text.trim(),
        'weight': double.parse(_weightController.text),
        'length': _lengthController.text.isNotEmpty
            ? double.parse(_lengthController.text)
            : 0,
        'width': _widthController.text.isNotEmpty
            ? double.parse(_widthController.text)
            : 0,
        'height': _heightController.text.isNotEmpty
            ? double.parse(_heightController.text)
            : 0,
        'description': _descriptionController.text.trim(),
        'trackingNumber': trackingNumber,
        'estimatedCost': 0,
        'actualCost': 0,
        'requiresInsurance': _requiresInsurance,
        'requiresCustomsClearance': _requiresCustoms,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'category': 'affiliate',
        'submissionType': 'direct',
      });

      // Navigate to success screen with client email for confirmation
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShippingRequestSuccessScreen(
            clientEmail: _clientEmailController.text.trim(),
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'New Shipping Request',
      showBackOnly: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Freight Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Freight Type',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<ShippingType>(
                            title: const Text('Air Freight'),
                            value: ShippingType.air,
                            groupValue: _type,
                            onChanged: (value) =>
                                setState(() => _type = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<ShippingType>(
                            title: const Text('Sea Freight'),
                            value: ShippingType.sea,
                            groupValue: _type,
                            onChanged: (value) =>
                                setState(() => _type = value!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Shipment Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shipment Details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lengthController,
                            decoration: const InputDecoration(
                              labelText: 'Length (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _widthController,
                            decoration: const InputDecoration(
                              labelText: 'Width (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sender Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sender Information',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Sender Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Sender Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Sender Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Requires Insurance'),
                      value: _requiresInsurance,
                      onChanged: (value) =>
                          setState(() => _requiresInsurance = value),
                    ),
                    SwitchListTile(
                      title: const Text('Requires Customs Clearance'),
                      value: _requiresCustoms,
                      onChanged: (value) =>
                          setState(() => _requiresCustoms = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
