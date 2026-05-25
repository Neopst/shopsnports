import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopsnports/models/shipping_request_simple.dart';
import 'package:shopsnports/core/theme/app_colors.dart';
import 'shipping_request_success_screen.dart';

/// Simplified Shipping Request Form - Firebase Only
/// 6 Sections: Freight Type, Shipment Details, Sender, Receiver, Documents, Other Info
class SimpleShippingRequestForm extends StatefulWidget {
  final String? affiliateId; // Optional - for affiliate referrals
  final String? userId; // Optional - for registered users

  const SimpleShippingRequestForm({
    super.key,
    this.affiliateId,
    this.userId,
  });

  @override
  State<SimpleShippingRequestForm> createState() =>
      _SimpleShippingRequestFormState();
}

class _SimpleShippingRequestFormState extends State<SimpleShippingRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isSubmitting = false;
  final List<String> _uploadedFileUrls = [];

  // Form Controllers
  late TextEditingController _itemDescriptionController;
  late TextEditingController _departingLocationController;
  late TextEditingController _destinationLocationController;
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

  // Dropdown & state
  String _freightType = 'air'; // only air or sea now
  String _priority = 'regular';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _itemDescriptionController = TextEditingController();
    _departingLocationController = TextEditingController();
    _destinationLocationController = TextEditingController();
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
  }

  @override
  void dispose() {
    _itemDescriptionController.dispose();
    _departingLocationController.dispose();
    _destinationLocationController.dispose();
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
    super.dispose();
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        for (var file in result.files) {
          final fileBytes = file.bytes;
          if (fileBytes != null) {
            final ref = _storage.ref(
              'shipping_requests/${DateTime.now().millisecondsSinceEpoch}/${file.name}',
            );
            await ref.putData(fileBytes);
            final url = await ref.getDownloadURL();
            setState(() => _uploadedFileUrls.add(url));
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} file(s) uploaded'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current user ID if logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;

      // Generate request ID
      final randomId =
          '${DateTime.now().millisecondsSinceEpoch}${(_senderEmailController.text.hashCode).abs()}';

      // Create SimpleShippingRequest object
      // determine category: affiliate takes precedence
      final category = widget.affiliateId != null
          ? 'affiliate'
          : (userId != null ? 'customer' : 'guest');

      final request = SimpleShippingRequest(
        id: randomId,
        affiliateId: widget.affiliateId,
        userId: userId ?? widget.userId,
        guestEmail: _senderEmailController.text,
        freightType: _freightType,
        itemDescription: _itemDescriptionController.text,
        departingLocation: _departingLocationController.text,
        destinationLocation: _destinationLocationController.text,
        shipmentWeightKg: double.parse(_weightController.text),
        shipmentDimensions: _dimensionsController.text,
        shipmentPackaging: _packagingController.text,
        priority: _priority,
        senderName: _senderNameController.text,
        senderAddress: _senderAddressController.text,
        senderPhone: _senderPhoneController.text,
        senderEmail: _senderEmailController.text,
        receiverName: _receiverNameController.text,
        receiverAddress: _receiverAddressController.text,
        receiverPhone: _receiverPhoneController.text,
        receiverEmail: _receiverEmailController.text,
        attachmentUrls: _uploadedFileUrls,
        otherInformation: _otherInfoController.text.isEmpty
            ? null
            : _otherInfoController.text,
        createdAt: DateTime.now(),
        status: 'pending',
        category: category,
      );

      // Write directly to Firestore
      await _firestore
          .collection('shippingRequests')
          .doc(request.id)
          .set(request.toFirestore());

      debugPrint('✅ Shipping request created: ${request.id}');

      // Navigate to success screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShippingRequestSuccessScreen(
              clientEmail: _senderEmailController.text,
              requestId: request.id,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Shipping'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Freight Type
              _buildSectionHeader('1. FREIGHT TYPE'),
              DropdownButtonFormField<String>(
                initialValue: _freightType,
                decoration: InputDecoration(
                  labelText: 'Freight Type *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.flight),
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
                ]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.value,
                        child: item.child,
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _freightType = value!),
              ),
              const SizedBox(height: 24),

              // Section 2: Shipment Details
              _buildSectionHeader('2. SHIPMENT DETAILS'),
              TextFormField(
                controller: _itemDescriptionController,
                decoration:
                    _inputDecoration('Item Description *', Icons.inventory_2),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departingLocationController,
                decoration:
                    _inputDecoration('Origin Address *', Icons.location_on),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Shipping Priority',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'regular',
                    label: Text('Regular'),
                  ),
                  ButtonSegment(
                    value: 'express',
                    label: Text('Express'),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<String> sel) {
                  setState(() => _priority = sel.first);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationLocationController,
                decoration: _inputDecoration(
                    'Destination Address *', Icons.location_on),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration:
                          _inputDecoration('Weight (kg) *', Icons.scale),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        final weight = double.tryParse(v!);
                        if (weight == null) return 'Invalid number';
                        if (weight <= 0) return 'Weight must be greater than 0';
                        if (weight > 10000) return 'Weight exceeds maximum (10,000 kg)';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dimensionsController,
                      decoration:
                          _inputDecoration('Dimensions (LxWxH)', Icons.crop),
                      // optional field
                      validator: (v) {
                        // no validation necessary
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _packagingController,
                decoration: _inputDecoration(
                    'Packaging Description *', Icons.local_shipping),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Section 3: Sender Details
              _buildSectionHeader('3. SENDER DETAILS'),
              TextFormField(
                controller: _senderNameController,
                decoration: _inputDecoration('Name *', Icons.person),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senderAddressController,
                decoration: _inputDecoration('Address *', Icons.home),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senderPhoneController,
                decoration: _inputDecoration('Phone *', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final phone = v!.replaceAll(RegExp(r'[^\d]'), '');
                  if (phone.length < 10) return 'Invalid phone number (min 10 digits)';
                  if (phone.length > 15) return 'Invalid phone number (max 15 digits)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senderEmailController,
                decoration: _inputDecoration('Email *', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v!)) return 'Invalid email format';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 4: Receiver Details
              _buildSectionHeader('4. RECEIVER DETAILS'),
              TextFormField(
                controller: _receiverNameController,
                decoration: _inputDecoration('Name *', Icons.person),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiverAddressController,
                decoration: _inputDecoration('Address *', Icons.home),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiverPhoneController,
                decoration: _inputDecoration('Phone *', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final phone = v!.replaceAll(RegExp(r'[^\d]'), '');
                  if (phone.length < 10) return 'Invalid phone number (min 10 digits)';
                  if (phone.length > 15) return 'Invalid phone number (max 15 digits)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiverEmailController,
                decoration: _inputDecoration('Email *', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v!)) return 'Invalid email format';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 5: Documentation
              _buildSectionHeader('5. ATTACH RELEVANT DOCUMENTATION'),
              ElevatedButton.icon(
                onPressed: _pickAndUploadFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Upload Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (_uploadedFileUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uploaded Files:'),
                      ..._uploadedFileUrls.map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.successGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  url.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Section 6: Other Information
              _buildSectionHeader('6. OTHER INFORMATION'),
              TextFormField(
                controller: _otherInfoController,
                decoration: _inputDecoration('Additional Notes', Icons.note),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: AppColors.lightGrey,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }
}
