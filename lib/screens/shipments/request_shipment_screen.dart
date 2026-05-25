import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/enums.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

/// Simple Shipping Request Screen
/// Allows customers/affiliates to request shipping for cargo
class RequestShipmentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefill;

  const RequestShipmentScreen({
    super.key,
    this.prefill,
  });

  @override
  ConsumerState<RequestShipmentScreen> createState() =>
      _RequestShipmentScreenState();
}

class _RequestShipmentScreenState extends ConsumerState<RequestShipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Route Information
  late TextEditingController _originController;
  late TextEditingController _destinationController;

  // Shipper Information
  late TextEditingController _shipperNameController;
  late TextEditingController _shipperEmailController;
  late TextEditingController _shipperPhoneController;
  late TextEditingController _shipperAddressController;

  // Recipient Information
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientEmailController;
  late TextEditingController _recipientPhoneController;
  late TextEditingController _recipientAddressController;

  // Cargo Details
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;
  late TextEditingController _contentsController;

  // Shipping Options
  ShippingType _shippingType = ShippingType.air;
  ShippingPriority _priority = ShippingPriority.standard;
  bool _requiresInsurance = false;
  String _insuranceValue = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final prefill = widget.prefill ?? {};

    _originController =
        TextEditingController(text: prefill['origin'] ?? 'United States');
    _destinationController =
        TextEditingController(text: prefill['destination'] ?? '');

    _shipperNameController =
        TextEditingController(text: prefill['senderName'] ?? user?.name ?? '');
    _shipperEmailController = TextEditingController(
        text: prefill['senderEmail'] ?? user?.email ?? '');
    _shipperPhoneController = TextEditingController(text: user?.phone ?? '');
    _shipperAddressController =
        TextEditingController(text: user?.address ?? '');

    _recipientNameController = TextEditingController(text: '');
    _recipientEmailController = TextEditingController(text: '');
    _recipientPhoneController = TextEditingController(text: '');
    _recipientAddressController = TextEditingController(text: '');

    _descriptionController = TextEditingController(text: '');
    _weightController = TextEditingController(text: '');
    _dimensionsController = TextEditingController(text: '');
    _contentsController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _shipperNameController.dispose();
    _shipperEmailController.dispose();
    _shipperPhoneController.dispose();
    _shipperAddressController.dispose();
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _recipientPhoneController.dispose();
    _recipientAddressController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _contentsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Here we would submit the shipping request
    // For now, show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shipping request submitted successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to home
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushNamed(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Shipping'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Route Section
              _buildSection(
                context,
                title: 'Shipping Route',
                icon: Icons.flight_takeoff,
                children: [
                  TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: 'Origin',
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'e.g., New York, USA',
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Please enter origin' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: Icon(Icons.place),
                      hintText: 'e.g., Lagos, Nigeria',
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Please enter destination' : null,
                  ),
                ],
              ),

              // Shipper Information
              _buildSection(
                context,
                title: 'Your Information',
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _shipperNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shipperEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.isEmpty ?? true) || !v!.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shipperPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shipperAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Recipient Information
              _buildSection(
                context,
                title: 'Recipient Information',
                icon: Icons.person_add,
                children: [
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v?.isEmpty ?? true
                        ? 'Please enter recipient name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'Please enter delivery address'
                        : null,
                  ),
                ],
              ),

              // Cargo Details
              _buildSection(
                context,
                title: 'Cargo Details',
                icon: Icons.inventory_2,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      hintText: 'What are you shipping?',
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true
                        ? 'Please describe your cargo'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Please enter weight' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dimensionsController,
                    decoration: const InputDecoration(
                      labelText: 'Dimensions (L x W x H in cm)',
                      prefixIcon: Icon(Icons.straighten),
                      hintText: '100 x 80 x 60',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentsController,
                    decoration: const InputDecoration(
                      labelText: 'Contents/HS Code',
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                ],
              ),

              // Shipping Options
              _buildSection(
                context,
                title: 'Shipping Options',
                icon: Icons.settings,
                children: [
                  Text(
                    'Shipping Type',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ShippingType.values
                        .map(
                          (type) => ChoiceChip(
                            label: Text(type.displayName),
                            selected: _shippingType == type,
                            onSelected: (selected) {
                              setState(() => _shippingType = type);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ShippingPriority.values
                        .map(
                          (priority) => ChoiceChip(
                            label: Text(priority.displayName),
                            selected: _priority == priority,
                            onSelected: (selected) {
                              setState(() => _priority = priority);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _requiresInsurance,
                    onChanged: (v) {
                      setState(() => _requiresInsurance = v ?? false);
                    },
                    title: const Text('Add Insurance'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_requiresInsurance) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _insuranceValue,
                      onChanged: (v) => _insuranceValue = v,
                      decoration: const InputDecoration(
                        labelText: 'Insured Value',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Request'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
