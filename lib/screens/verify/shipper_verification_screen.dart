import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/firestore_provider.dart';

class ShipperVerificationScreen extends ConsumerStatefulWidget {
  const ShipperVerificationScreen({super.key});

  @override
  ConsumerState<ShipperVerificationScreen> createState() =>
      _ShipperVerificationScreenState();
}

class _ShipperVerificationScreenState
    extends ConsumerState<ShipperVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String _vehicleType = 'Motorcycle';
  bool _hasInsurance = false;
  bool _submitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _licenseNumberController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final user = ref.read(currentUserProvider);

    try {
      final db = ref.read(firestoreProvider);

      // Create verification request
      final doc = await db.collection('shipper_verifications').add({
        'userId': user?.id ?? 'unknown',
        'name': user?.name ?? '',
        'phone': user?.phone ?? '',
        'email': user?.email ?? '',
        'vehicleType': _vehicleType,
        'vehicleDetails': _vehicleController.text,
        'licenseNumber': _licenseNumberController.text,
        'address': _addressController.text,
        'emergencyContact': _emergencyContactController.text,
        'hasInsurance': _hasInsurance,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create admin notification
      await db.collection('admin_notifications').add({
        'type': 'shipper_verification',
        'userId': user?.id ?? 'unknown',
        'verificationId': doc.id,
        'message': '${user?.name ?? 'User'} requested shipper verification',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your shipper verification request has been submitted successfully!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'What happens next:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Admin will review your application'),
              Text('2. You may be contacted for additional documents'),
              Text('3. Approval typically takes 2-3 business days'),
              SizedBox(height: 16),
              Text(
                'You\'ll receive a notification once your application is reviewed.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Verified Shipper'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: Colors.blue[50],
                elevation: 0,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.blue, size: 40),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipper Benefits',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Earn money by delivering packages in your area',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: user?.name ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: user?.phone ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                  hintText: 'Enter your full address',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(Icons.emergency),
                  border: OutlineInputBorder(),
                  hintText: 'Phone number of next of kin',
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Emergency contact is required'
                    : null,
              ),

              const SizedBox(height: 32),

              // Vehicle Information
              const Text(
                'Vehicle Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Motorcycle', child: Text('Motorcycle')),
                  DropdownMenuItem(value: 'Car', child: Text('Car')),
                  DropdownMenuItem(value: 'Van', child: Text('Van')),
                  DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                  DropdownMenuItem(value: 'Bicycle', child: Text('Bicycle')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _vehicleType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Details',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Make, model, year, color, plate number',
                ),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Vehicle details required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Driver\'s License Number',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: 'Your valid driver\'s license number',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'License number required' : null,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                value: _hasInsurance,
                onChanged: (value) => setState(() => _hasInsurance = value),
                title: const Text('Vehicle Insurance'),
                subtitle: const Text('Do you have valid vehicle insurance?'),
                secondary: const Icon(Icons.verified_user),
              ),

              const SizedBox(height: 32),

              // Additional Information
              Card(
                color: Colors.orange[50],
                elevation: 0,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Required Documents',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                          'After submitting this form, you may be asked to provide:'),
                      SizedBox(height: 8),
                      Text('• Valid driver\'s license (photo)'),
                      Text('• Vehicle registration documents'),
                      Text('• Proof of insurance'),
                      Text('• National ID or passport'),
                      Text('• Recent passport photograph'),
                      SizedBox(height: 8),
                      Text(
                        'These can be uploaded through the admin portal or sent via email.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text(
                          'Submit Verification Request',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'By submitting, you agree to our Terms of Service',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
