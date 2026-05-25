import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/core/theme/app_colors.dart';
import 'package:shopsnports/models/shipping_request_simplified.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/shipping_submission_provider.dart';
import 'package:shopsnports/services/file_upload_service.dart';
import 'package:shopsnports/models/enums.dart';

/// Form state notifier for managing shipping request form
class ShippingFormState {
  // 1. FREIGHT TYPE
  String freightType = 'air'; // now only 'air' or 'sea'

  // 2. SHIPMENT DETAILS
  String itemDescription = '';
  String departingLocation = '';
  String destinationLocation = '';
  String shipmentWeight = '';
  String shipmentLength = '';
  String shipmentWidth = '';
  String shipmentHeight = '';
  String shipmentPackaging = '';
  ShippingPriority priority = ShippingPriority.standard;

  // 3. SENDER DETAILS
  String senderName = '';
  String senderAddress = '';
  String senderPhone = '';
  String senderEmail = '';

  // 4. RECEIVER DETAILS
  String receiverName = '';
  String receiverAddress = '';
  String receiverPhone = '';
  String receiverEmail = '';

  // 5. ATTACHMENTS
  List<ShippingDocument> attachments = [];

  // 6. OTHER INFORMATION
  String? otherInformation;

  // Validation errors
  Map<String, String> errors = {};

  bool validate() {
    errors.clear();

    // Validate Freight Type
    if (freightType.isEmpty) {
      errors['freightType'] = 'Please select a freight type';
    }

    // Validate Shipment Details
    if (itemDescription.isEmpty) {
      errors['itemDescription'] = 'Item description is required';
    }
    if (departingLocation.isEmpty) {
      errors['departingLocation'] = 'Origin address is required';
    }
    if (destinationLocation.isEmpty) {
      errors['destinationLocation'] = 'Destination address is required';
    }
    if (shipmentWeight.isEmpty) {
      errors['shipmentWeight'] = 'Weight is required';
    } else {
      try {
        double.parse(shipmentWeight);
      } catch (e) {
        errors['shipmentWeight'] = 'Please enter a valid weight';
      }
    }
    // dimension fields are optional now; only validate if non-empty
    if (shipmentLength.isNotEmpty) {
      try {
        double.parse(shipmentLength);
      } catch (e) {
        errors['shipmentLength'] = 'Please enter a valid length';
      }
    }
    if (shipmentWidth.isNotEmpty) {
      try {
        double.parse(shipmentWidth);
      } catch (e) {
        errors['shipmentWidth'] = 'Please enter a valid width';
      }
    }
    if (shipmentHeight.isNotEmpty) {
      try {
        double.parse(shipmentHeight);
      } catch (e) {
        errors['shipmentHeight'] = 'Please enter a valid height';
      }
    }
    if (shipmentPackaging.isEmpty) {
      errors['shipmentPackaging'] = 'Packaging type is required';
    }

    // Validate Sender Details
    if (senderName.isEmpty) {
      errors['senderName'] = 'Sender name is required';
    }
    if (senderAddress.isEmpty) {
      errors['senderAddress'] = 'Sender address is required';
    }
    if (senderPhone.isEmpty) {
      errors['senderPhone'] = 'Sender phone is required';
    } else if (!_isValidPhone(senderPhone)) {
      errors['senderPhone'] = 'Please enter a valid phone number';
    }
    if (senderEmail.isEmpty) {
      errors['senderEmail'] = 'Sender email is required';
    } else if (!_isValidEmail(senderEmail)) {
      errors['senderEmail'] = 'Please enter a valid email';
    }

    // Validate Receiver Details
    if (receiverName.isEmpty) {
      errors['receiverName'] = 'Receiver name is required';
    }
    if (receiverAddress.isEmpty) {
      errors['receiverAddress'] = 'Receiver address is required';
    }
    if (receiverPhone.isEmpty) {
      errors['receiverPhone'] = 'Receiver phone is required';
    } else if (!_isValidPhone(receiverPhone)) {
      errors['receiverPhone'] = 'Please enter a valid phone number';
    }
    if (receiverEmail.isEmpty) {
      errors['receiverEmail'] = 'Receiver email is required';
    } else if (!_isValidEmail(receiverEmail)) {
      errors['receiverEmail'] = 'Please enter a valid email';
    }

    return errors.isEmpty;
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _isValidPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '').length >= 10;
  }

  ShippingRequestSimplified toModel(String requesterId, {String? affiliateId}) {
    // category derived: affiliate > customer > guest
    final category = affiliateId != null
        ? 'affiliate'
        : (requesterId.isNotEmpty ? 'customer' : 'guest');

    String priorityToString(ShippingPriority p) {
      switch (p) {
        case ShippingPriority.standard:
          return 'regular';
        case ShippingPriority.express:
          return 'express';
        case ShippingPriority.urgent:
          return 'urgent';
      }
    }

    return ShippingRequestSimplified(
      id: '', // Will be generated by Firestore
      requesterId: requesterId,
      affiliateId: affiliateId,
      status: 'pending',
      createdAt: DateTime.now(),
      freightType: freightType, // will be 'air' or 'sea'
      itemDescription: itemDescription,
      departingLocation: departingLocation,
      destinationLocation: destinationLocation,
      shipmentWeight: double.tryParse(shipmentWeight) ?? 0.0,
      shipmentLength: double.tryParse(shipmentLength) ?? 0.0,
      shipmentWidth: double.tryParse(shipmentWidth) ?? 0.0,
      shipmentHeight: double.tryParse(shipmentHeight) ?? 0.0,
      shipmentPackaging: shipmentPackaging,
      priority: priorityToString(priority),
      senderName: senderName,
      senderAddress: senderAddress,
      senderPhone: senderPhone,
      senderEmail: senderEmail,
      receiverName: receiverName,
      receiverAddress: receiverAddress,
      receiverPhone: receiverPhone,
      receiverEmail: receiverEmail,
      attachments: attachments,
      otherInformation: otherInformation,
      category: category,
    );
  }
}

/// Shipping Form Screen - Collect 21-field shipping request
class ShippingRequestFormScreen extends ConsumerStatefulWidget {
  final String? affiliateId;
  final VoidCallback? onSubmitSuccess;

  const ShippingRequestFormScreen({
    super.key,
    this.affiliateId,
    this.onSubmitSuccess,
  });

  @override
  ConsumerState<ShippingRequestFormScreen> createState() =>
      _ShippingRequestFormScreenState();
}

class _ShippingRequestFormScreenState
    extends ConsumerState<ShippingRequestFormScreen> {
  late ShippingFormState _form;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  int _expandedSection = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _form = ShippingFormState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final fields = [
      'itemDescription',
      'departingLocation',
      'destinationLocation',
      'shipmentWeight',
      'shipmentLength',
      'shipmentWidth',
      'shipmentHeight',
      'shipmentPackaging',
      'senderName',
      'senderAddress',
      'senderPhone',
      'senderEmail',
      'receiverName',
      'receiverAddress',
      'receiverPhone',
      'receiverEmail',
      'otherInformation',
    ];

    for (final field in fields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    // Update form from controllers
    _form.itemDescription = _controllers['itemDescription']?.text ?? '';
    _form.departingLocation = _controllers['departingLocation']?.text ?? '';
    _form.destinationLocation = _controllers['destinationLocation']?.text ?? '';
    _form.shipmentWeight = _controllers['shipmentWeight']?.text ?? '';
    _form.shipmentLength = _controllers['shipmentLength']?.text ?? '';
    _form.shipmentWidth = _controllers['shipmentWidth']?.text ?? '';
    _form.shipmentHeight = _controllers['shipmentHeight']?.text ?? '';
    _form.shipmentPackaging = _controllers['shipmentPackaging']?.text ?? '';
    // priority is already part of form state managed separately
    _form.senderName = _controllers['senderName']?.text ?? '';
    _form.senderAddress = _controllers['senderAddress']?.text ?? '';
    _form.senderPhone = _controllers['senderPhone']?.text ?? '';
    _form.senderEmail = _controllers['senderEmail']?.text ?? '';
    _form.receiverName = _controllers['receiverName']?.text ?? '';
    _form.receiverAddress = _controllers['receiverAddress']?.text ?? '';
    _form.receiverPhone = _controllers['receiverPhone']?.text ?? '';
    _form.receiverEmail = _controllers['receiverEmail']?.text ?? '';
    _form.otherInformation = _controllers['otherInformation']?.text;

    if (!_form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please fix ${_form.errors.length} error(s) in the form'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      // Scroll to first error section
      _scrollToFirstError();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Allow both logged-in users and guests to submit shipping requests
      final currentUser = ref.read(currentUserProvider);

      // Determine affiliateId: prefer explicit argument (used by tests
      // or affiliate screens), otherwise fall back to the current user
      // record. This ensures normal affiliates don't need to pass the id
      // everywhere.
      final resolvedAffiliateId = currentUser != null
          ? (widget.affiliateId ?? currentUser.affiliateId)
          : widget.affiliateId;

      // Use user ID if logged in, otherwise generate a guest ID from email
      final requesterId = currentUser?.id ?? 'guest_${_form.senderEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      // Create model from form
      final model = _form.toModel(
        requesterId,
        affiliateId: resolvedAffiliateId,
      );

      // Submit via repository
      final submissionNotifier = ref.read(shippingSubmissionProvider.notifier);
      final requestId = await submissionNotifier.submitShippingRequest(
        requesterId: requesterId,
        request: model,
        affiliateId: resolvedAffiliateId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Shipping request submitted! Tracking number will be emailed soon.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Show success dialog with request ID
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your shipping request has been submitted successfully!',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request ID:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectableText(
                        requestId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You will receive a tracking number via email within 24 hours. You can then track your shipment from the home screen.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSubmitSuccess?.call();
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _scrollToFirstError() {
    final firstErrorField = _form.errors.keys.first;
    // Find which section contains the error
    const sectionFields = {
      0: ['freightType'],
      1: [
        'itemDescription',
        'hsCode',
        'departingLocation',
        'destinationLocation',
        'shipmentWeight',
        'shipmentLength',
        'shipmentWidth',
        'shipmentHeight',
        'shipmentPackaging'
      ],
      2: ['senderName', 'senderAddress', 'senderPhone', 'senderEmail'],
      3: ['receiverName', 'receiverAddress', 'receiverPhone', 'receiverEmail'],
      4: ['attachments'],
      5: ['otherInformation'],
    };

    for (final entry in sectionFields.entries) {
      if (entry.value.contains(firstErrorField)) {
        setState(() => _expandedSection = entry.key);
        break;
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final fileUploadService = FileUploadService();
      final pickedFiles = await fileUploadService.pickFiles(maxFiles: 5);

      if (pickedFiles != null) {
        setState(() {
          // Convert to ShippingDocument objects with placeholder URLs
          // These will be uploaded to Cloud Storage on form submission
          for (final file in pickedFiles) {
            // Check if file already added
            if (_form.attachments.any((doc) => doc.fileName == file.name)) {
              continue;
            }

            _form.attachments.add(
              ShippingDocument(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                fileName: file.name,
                fileUrl: '', // Will be set during upload
                fileType: _detectFileType(file.name),
                fileSizeBytes: file.size,
                uploadedAt: DateTime.now(),
              ),
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${pickedFiles.length} file(s) ready to upload (will upload with form submission)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _form.attachments.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📎 File removed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon = Icons.description;
    Color color = Colors.grey;

    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (['doc', 'docx'].contains(ext)) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      icon = Icons.image;
      color = Colors.green;
    } else if (['xlsx', 'xls'].contains(ext)) {
      icon = Icons.table_chart;
      color = Colors.teal;
    }

    return Icon(icon, color: color);
  }

  String _detectFileType(String fileName) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('invoice')) return 'invoice';
    if (nameLower.contains('proforma') || nameLower.contains('pro forma')) {
      return 'proforma';
    }
    if (nameLower.contains('packing') || nameLower.contains('pack list')) {
      return 'packing_list';
    }
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Shipping Request'),
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete all required fields (marked with *)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: FREIGHT TYPE
            _buildSection(
              index: 0,
              title: 'Freight Type',
              icon: Icons.local_shipping,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Freight Type *',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'air',
                        label: Text('Air'),
                      ),
                      ButtonSegment(
                        value: 'sea',
                        label: Text('Sea'),
                      ),
                    ],
                    selected: {_form.freightType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(
                        () => _form.freightType = newSelection.first,
                      );
                    },
                  ),
                  if (_form.errors['freightType'] != null)
                    _buildErrorText(_form.errors['freightType']!),
                ],
              ),
            ),

            // SECTION 2: SHIPMENT DETAILS
            _buildSection(
              index: 1,
              title: 'Shipment Details',
              icon: Icons.work,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    'itemDescription',
                    'Item Description *',
                    'What are you shipping?',
                    maxLines: 2,
                  ),
                  _buildTextField(
                    'departingLocation',
                    'Origin Address *',
                    'City, State, Country or full address',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Shipping Priority',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ShippingPriority>(
                    segments: const [
                      ButtonSegment(
                        value: ShippingPriority.standard,
                        label: Text('Regular'),
                      ),
                      ButtonSegment(
                        value: ShippingPriority.express,
                        label: Text('Express'),
                      ),
                    ],
                    selected: {_form.priority},
                    onSelectionChanged: (Set<ShippingPriority> sel) {
                      setState(() => _form.priority = sel.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'destinationLocation',
                    'Destination Address *',
                    'City, State, Country or full address',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dimensions & Weight',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'shipmentWeight',
                          'Weight (kg) *',
                          '0.0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          'shipmentLength',
                          'Length (cm)',
                          '0.0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'shipmentWidth',
                          'Width (cm)',
                          '0.0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          'shipmentHeight',
                          'Height (cm)',
                          '0.0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    'shipmentPackaging',
                    'Packaging Type *',
                    'e.g., Box, Pallet, Crate',
                  ),
                ],
              ),
            ),

            // SECTION 3: SENDER DETAILS
            _buildSection(
              index: 2,
              title: 'Sender Details',
              icon: Icons.person,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    'senderName',
                    'Full Name *',
                    'Your name',
                  ),
                  _buildTextField(
                    'senderAddress',
                    'Address *',
                    'Street address',
                  ),
                  _buildTextField(
                    'senderPhone',
                    'Phone Number *',
                    '+234 801 234 5678',
                  ),
                  _buildTextField(
                    'senderEmail',
                    'Email Address *',
                    'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),

            // SECTION 4: RECEIVER DETAILS
            _buildSection(
              index: 3,
              title: 'Receiver Details',
              icon: Icons.person_add,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    'receiverName',
                    'Full Name *',
                    'Recipient name',
                  ),
                  _buildTextField(
                    'receiverAddress',
                    'Address *',
                    'Street address',
                  ),
                  _buildTextField(
                    'receiverPhone',
                    'Phone Number *',
                    '+234 801 234 5678',
                  ),
                  _buildTextField(
                    'receiverEmail',
                    'Email Address *',
                    'recipient@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),

            // SECTION 5: ATTACHMENTS
            _buildSection(
              index: 4,
              title: 'Attachments',
              icon: Icons.attach_file,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload,
                            size: 32, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Documents (Optional)',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoice, packing list, insurance, etc.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => _pickFiles(),
                          child: const Text('Choose Files'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max 10MB per file, up to 50MB total',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),

                  // Display uploaded files
                  if (_form.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Attached Files (${_form.attachments.length})',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _form.attachments.length,
                      itemBuilder: (context, index) {
                        final doc = _form.attachments[index];
                        return Card(
                          child: ListTile(
                            leading: _getFileIcon(doc.fileName),
                            title: Text(doc.fileName,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              FileUploadService.formatFileSize(
                                  doc.fileSizeBytes),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // SECTION 6: OTHER INFORMATION
            _buildSection(
              index: 5,
              title: 'Additional Information',
              icon: Icons.notes,
              child: _buildTextField(
                'otherInformation',
                'Additional Notes (Optional)',
                'Special handling instructions, fragile items, etc.',
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 24),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Shipping Request',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // CANCEL BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isExpanded = _expandedSection == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() => _expandedSection = isExpanded ? -1 : index);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String fieldName,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final hasError = _form.errors.containsKey(fieldName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _controllers[fieldName],
            focusNode: _focusNodes[fieldName],
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.errorRed),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError ? AppColors.errorRed : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          if (hasError) _buildErrorText(_form.errors[fieldName]!),
        ],
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: const TextStyle(
          color: AppColors.errorRed,
          fontSize: 12,
        ),
      ),
    );
  }
}
