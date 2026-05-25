import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shipping_request_simple.dart';
import '../../services/firestore_shipping_service.dart';
import '../../widgets/main_scaffold.dart';
import 'shipping_request_success_screen.dart';

/// Simplified Shipping Request Form - Easy & Fast
/// Only captures essential information for quick quote generation
class SimpleShippingRequestScreen extends ConsumerStatefulWidget {
  final String? prefilledAffiliateId;

  const SimpleShippingRequestScreen({
    super.key,
    this.prefilledAffiliateId,
  });

  @override
  ConsumerState<SimpleShippingRequestScreen> createState() =>
      _SimpleShippingRequestScreenState();
}

class _SimpleShippingRequestScreenState
    extends ConsumerState<SimpleShippingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreShippingService();
  bool _isSubmitting = false;

  // Form controllers
  late TextEditingController _itemDescController;
  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;
  late TextEditingController _packagingController;
  late TextEditingController _senderNameController;
  late TextEditingController _senderAddressController;
  late TextEditingController _senderPhoneController;
  late TextEditingController _senderEmailController;
  late TextEditingController _receiverNameController;
  late TextEditingController _receiverAddressController;
  late TextEditingController _receiverPhoneController;
  late TextEditingController _receiverEmailController;
  late TextEditingController _otherInfoController;
  late TextEditingController _attachmentsController;

  String _freightType = 'air'; // default to air; only air/sea allowed
  String _priority = 'regular';

  @override
  void initState() {
    super.initState();
    _itemDescController = TextEditingController();
    _fromLocationController = TextEditingController();
    _toLocationController = TextEditingController();
    _weightController = TextEditingController();
    _dimensionsController = TextEditingController();
    _packagingController = TextEditingController();
    _senderNameController = TextEditingController();
    _senderAddressController = TextEditingController();
    _senderPhoneController = TextEditingController();
    _senderEmailController = TextEditingController();
    _receiverNameController = TextEditingController();
    _receiverAddressController = TextEditingController();
    _receiverPhoneController = TextEditingController();
    _receiverEmailController = TextEditingController();
    _otherInfoController = TextEditingController();
    _attachmentsController = TextEditingController();
  }

  @override
  void dispose() {
    _itemDescController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _packagingController.dispose();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _senderPhoneController.dispose();
    _senderEmailController.dispose();
    _receiverNameController.dispose();
    _receiverAddressController.dispose();
    _receiverPhoneController.dispose();
    _receiverEmailController.dispose();
    _otherInfoController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user ID if logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;

      // Generate a document-like ID
      final randomId =
          '${DateTime.now().millisecondsSinceEpoch}${(_senderEmailController.text.hashCode).abs()}';

      // Create SimpleShippingRequest from form fields
      // Determine category for the request
      final resolvedCategory = widget.prefilledAffiliateId != null
          ? 'affiliate'
          : (userId != null ? 'customer' : 'guest');

      final request = SimpleShippingRequest(
        id: randomId, // ✅ Use generated ID
        userId: userId, // ✅ Add current user ID for registered users
        guestEmail: _senderEmailController.text.trim(),
        freightType: _freightType,
        itemDescription: _itemDescController.text.trim(),
        departingLocation: _fromLocationController.text.trim(),
        destinationLocation: _toLocationController.text.trim(),
        shipmentWeightKg: double.tryParse(_weightController.text) ?? 0.0,
        shipmentDimensions: _dimensionsController.text.trim(),
        shipmentPackaging: _packagingController.text.trim(),
        priority: _priority,
        senderName: _senderNameController.text.trim(),
        senderAddress: _senderAddressController.text.trim(),
        senderPhone: _senderPhoneController.text.trim(),
        senderEmail: _senderEmailController.text.trim(),
        receiverName: _receiverNameController.text.trim(),
        receiverAddress: _receiverAddressController.text.trim(),
        receiverPhone: _receiverPhoneController.text.trim(),
        receiverEmail: _receiverEmailController.text.trim(),
        otherInformation: _otherInfoController.text.isEmpty
            ? null
            : _otherInfoController.text.trim(),
        attachmentUrls: [],
        createdAt: DateTime.now(),
        status: 'pending',
        category: resolvedCategory,
      );

      // Submit directly to Firestore (no REST API)
      final requestId = await _firestoreService.submitShippingRequest(request);

      if (mounted) {
        // Show success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShippingRequestSuccessScreen(
              requestId: requestId,
              clientEmail: request.senderEmail,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Request Shipping',
      showBackOnly: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Quick Shipping Request',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the basic details and we\'ll get you a quote',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // ========== SECTION 1: FREIGHT TYPE ==========
              _buildSectionHeader('1. Freight Type'),
              DropdownButtonFormField<String>(
                initialValue: _freightType,
                decoration: InputDecoration(
                  labelText: 'Select Freight Type *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.local_shipping),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'air',
                    child: Text('Air'),
                  ),
                  DropdownMenuItem(
                    value: 'sea',
                    child: Text('Sea'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _freightType = value ?? 'air');
                },
                validator: (value) =>
                    value == null ? 'Please select freight type' : null,
              ),
              const SizedBox(height: 24),

              // ========== SECTION 2: SHIPMENT DETAILS ==========
              _buildSectionHeader('2. Shipment Details'),
              _buildFormField(
                controller: _itemDescController,
                label: 'Item Description',
                hint: 'e.g., Electronics, Textiles, Food Items',
                required: true,
                icon: Icons.description,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _fromLocationController,
                label: 'Origin Address',
                hint: 'e.g., Lagos, Nigeria or full address',
                required: true,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              Text(
                'Shipping Priority',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'regular', label: Text('Regular')),
                  ButtonSegment(value: 'express', label: Text('Express')),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<String> sel) {
                  setState(() => _priority = sel.first);
                },
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _toLocationController,
                label: 'Destination Address',
                hint: 'e.g., New York, USA or full address',
                required: true,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _weightController,
                label: 'Shipment Weight (in kg)',
                hint: 'e.g., 100',
                required: true,
                icon: Icons.scale,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _dimensionsController,
                label: 'Shipment Dimensions (LxWxH in cm)',
                hint: 'e.g., 100x50x30',
                required: false,
                icon: Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _packagingController,
                label: 'Shipment Packaging',
                hint: 'e.g., Carton boxes, Pallets, Crates',
                required: true,
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 24),

              // ========== SECTION 3: SENDER DETAILS ==========
              _buildSectionHeader('3. Sender Details'),
              _buildFormField(
                controller: _senderNameController,
                label: 'Name',
                hint: 'Full name',
                required: true,
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _senderAddressController,
                label: 'Address',
                hint: 'Complete address',
                required: true,
                icon: Icons.home,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _senderPhoneController,
                label: 'Phone Number',
                hint: 'e.g., +234 800 000 0000',
                required: true,
                icon: Icons.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _senderEmailController,
                label: 'Email',
                hint: 'sender@example.com',
                required: true,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // ========== SECTION 4: RECEIVER DETAILS ==========
              _buildSectionHeader('4. Receiver Details'),
              _buildFormField(
                controller: _receiverNameController,
                label: 'Name',
                hint: 'Full name',
                required: true,
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _receiverAddressController,
                label: 'Address',
                hint: 'Complete address',
                required: true,
                icon: Icons.home,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _receiverPhoneController,
                label: 'Phone Number',
                hint: 'e.g., +1 555 000 0000',
                required: true,
                icon: Icons.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _receiverEmailController,
                label: 'Email',
                hint: 'receiver@example.com',
                required: true,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // ========== SECTION 5: ATTACHMENTS ==========
              _buildSectionHeader('5. Attach Relevant Documentation'),
              TextFormField(
                controller: _attachmentsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Attachments (optional)',
                  hintText: 'Describe any attached documents',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.attach_file),
                ),
              ),
              const SizedBox(height: 24),

              // ========== SECTION 6: OTHER INFORMATION ==========
              _buildSectionHeader('6. Other Information'),
              TextFormField(
                controller: _otherInfoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  hintText:
                      'Any special instructions or additional information',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 32),

              // ========== SUBMIT BUTTON ==========
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SEND REQUEST',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Asterisk note
              Text(
                '(*) = Required field',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool required,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (label.contains('Email') &&
            value != null &&
            value.isNotEmpty &&
            !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}
