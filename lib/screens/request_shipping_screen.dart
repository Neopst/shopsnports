import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/shipping_firestore_service.dart';
import '../utils/app_logger.dart';
import '../providers/user_providers.dart';
import '../widgets/shipment_form.dart';
import 'package:shopsnports/providers/firestore_provider.dart';
import '../models/enums.dart';

/// Shipping Request Notifier - saves all shipping requests to Firestore
class _ShippingRequestNotifier extends StateNotifier<Map<String, dynamic>> {
  _ShippingRequestNotifier() : super({'attachments': [], 'products': []});

  void updateBasic({String? freightType}) {
    state = {...state, 'freightType': freightType ?? state['freightType']};
  }

  void updateCustoms({String? purpose, String? hsCode}) {
    state = {...state, 'purpose': purpose ?? state['purpose'], 'hsCode': hsCode ?? state['hsCode']};
  }

  void updateDocs({List<dynamic>? attachments}) {
    state = {...state, 'attachments': attachments ?? []};
  }

  void updateProducts({List<dynamic>? products}) {
    state = {...state, 'products': products ?? []};
  }

  void deleteProduct(int index) {
    final products = List<Map<String, dynamic>>.from(state['products'] ?? []);
    if (index >= 0 && index < products.length) {
      products.removeAt(index);
      state = {...state, 'products': products};
    }
  }

  void updateDangerousGoods({
    bool? containsDangerousGoods,
    bool? isDangerous,
    String? details,
    String? unNumber,
    String? properShippingName,
    String? dgClass,
    String? packingGroup,
  }) {
    state = {
      ...state,
      'containsDangerousGoods': containsDangerousGoods ?? state['containsDangerousGoods'],
      'unNumber': unNumber ?? state['unNumber'],
      'properShippingName': properShippingName ?? state['properShippingName'],
      'dgClass': dgClass ?? state['dgClass'],
      'packingGroup': packingGroup ?? state['packingGroup'],
    };
  }

  void updateExtra(Map<String, dynamic> data) {
    state = {...state, ...data};
  }

  void updateInsuranceAndHandling({
    bool? requiresInsurance,
    bool? insuranceRequired,
    double? insuranceValue,
    String? insuranceType,
    String? specialEquipment,
    String? handlingInstructions,
  }) {
    state = {
      ...state,
      'requiresInsurance': requiresInsurance ?? insuranceRequired ?? state['requiresInsurance'],
      'insuranceValue': insuranceValue ?? state['insuranceValue'],
      'insuranceType': insuranceType ?? state['insuranceType'],
      'specialEquipment': specialEquipment ?? state['specialEquipment'],
      'handlingInstructions': handlingInstructions ?? state['handlingInstructions'],
    };
  }

  /// Submit shipping request to Firestore - Firebase is the single source of truth
  Future<String?> submit({Map<String, dynamic>? requester}) async {
    try {
      final service = ShippingFirestoreService();

      // Determine shipment type from current state
      final freightType = state['freightType'] as String? ?? '';
      final isAir = freightType.toLowerCase().contains('air');
      // Convert to ShippingType (from models/enums.dart)
      final shipmentType = isAir ? ShippingType.air : ShippingType.sea;

      // Extract requester info
      final userId = requester?['userId'] as String?;
      final isGuest = userId == null || requester?['guest'] == true;

      // Get basic info from state
      final origin = state['origin'] as String? ?? 'Not specified';
      final destination = state['destination'] as String? ?? 'Not specified';
      final weight = (state['weight'] as num?)?.toDouble() ?? 0.0;

      // Get products/cargo
      final products = state['products'] as List? ?? [];
      final description = products.isNotEmpty
          ? products.map((p) => p['description'] ?? '').join(', ')
          : (state['purpose'] as String? ?? 'Shipping request');

      // Create the shipping request in Firestore
      final request = await service.createShippingRequest(
        type: shipmentType,
        origin: origin,
        destination: destination,
        weight: weight,
        description: description,
        clientName: requester?['name'] as String? ?? 'Guest',
        clientEmail: requester?['email'] as String? ?? '',
        clientPhone: requester?['phone'] as String? ?? '',
        userId: isGuest ? null : userId,
      );

      // If there's an affiliate ID in state, update the request
      if (state['affiliateId'] != null) {
        final db = FirebaseFirestore.instance;
        await db.collection('shippingRequests').doc(request.id).update({
          'affiliateId': state['affiliateId'],
          'affiliateCommission': 0.0, // Will be calculated later
        });
      }

      AppLogger.info('Shipping request submitted: ${request.id}');
      return request.id;
    } catch (e) {
      AppLogger.error('Failed to submit shipping request: $e');
      rethrow;
    }
  }

  void addProduct(Map<String, dynamic> product) {
    final products = List<Map<String, dynamic>>.from(state['products'] ?? []);
    products.add(product);
    state = {...state, 'products': products};
  }

  void removeProduct(int index) {
    final products = List<Map<String, dynamic>>.from(state['products'] ?? []);
    if (index >= 0 && index < products.length) {
      products.removeAt(index);
      state = {...state, 'products': products};
    }
  }
}

final shippingRequestProvider =
    StateNotifierProvider<_ShippingRequestNotifier, Map<String, dynamic>>(
  (ref) => _ShippingRequestNotifier(),
);

class RequestShippingScreen extends ConsumerStatefulWidget {
  /// Optional prefill map (e.g. {'senderName': 'Alice', 'destination': 'Lagos'})
  const RequestShippingScreen({
    super.key,
    this.useMainScaffold = true,
    this.prefill,
    this.asShipperVerification = false,
    this.initialStep,
    this.autoSubmitOnOpen = false,
  });

  final bool useMainScaffold;
  final Map<String, dynamic>? prefill;
  final bool asShipperVerification;
  final int? initialStep;
  final bool autoSubmitOnOpen;

  @override
  ConsumerState<RequestShippingScreen> createState() =>
      _RequestShippingScreenState();
}

// --- Mini form widgets used inside the stepper (file-scope) ---

typedef ProductAddCallback = void Function(Map<String, dynamic> product);

class ProductMiniForm extends StatefulWidget {
  final ProductAddCallback onAdd;
  const ProductMiniForm({required this.onAdd, super.key});

  @override
  State<ProductMiniForm> createState() => _ProductMiniFormState();
}

class _ProductMiniFormState extends State<ProductMiniForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController desc = TextEditingController();
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController net = TextEditingController(text: '0');
  final TextEditingController gross = TextEditingController(text: '0');
  final TextEditingController dims = TextEditingController();
  final TextEditingController value = TextEditingController(text: '0');
  final TextEditingController hs = TextEditingController();

  @override
  void dispose() {
    desc.dispose();
    qty.dispose();
    net.dispose();
    gross.dispose();
    dims.dispose();
    value.dispose();
    hs.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    final p = {
      'description': desc.text,
      'quantity': int.tryParse(qty.text) ?? 1,
      'netWeight': double.tryParse(net.text) ?? 0.0,
      'grossWeight': double.tryParse(gross.text) ?? 0.0,
      'dimensions': dims.text,
      'value': double.tryParse(value.text) ?? 0.0,
      'hsCode': hs.text,
    };
    widget.onAdd(p);
    _formKey.currentState!.reset();
    desc.clear();
    qty.text = '1';
    net.text = '0';
    gross.text = '0';
    dims.clear();
    value.text = '0';
    hs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: qty,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                        controller: value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        keyboardType: TextInputType.number)),
              ]),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: net,
                        decoration:
                            const InputDecoration(labelText: 'Net Wt (kg)'),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                        controller: gross,
                        decoration:
                            const InputDecoration(labelText: 'Gross Wt (kg)'),
                        keyboardType: TextInputType.number)),
              ]),
              TextFormField(
                  controller: hs,
                  decoration: const InputDecoration(labelText: 'HS Code')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _add, child: const Text('Add product')),
            ],
          ),
        ),
      ),
    );
  }
}

class DangerousGoodsForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSave;
  const DangerousGoodsForm({required this.onSave, super.key});

  @override
  State<DangerousGoodsForm> createState() => _DangerousGoodsFormState();
}

class _DangerousGoodsFormState extends State<DangerousGoodsForm> {
  bool contains = false;
  final unController = TextEditingController();
  final nameController = TextEditingController();
  final classController = TextEditingController();
  final packingController = TextEditingController();

  @override
  void dispose() {
    unController.dispose();
    nameController.dispose();
    classController.dispose();
    packingController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'containsDangerousGoods': contains,
      'unNumber': unController.text,
      'properShippingName': nameController.text,
      'dgClass': classController.text,
      'packingGroup': packingController.text,
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dangerous goods info saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
              value: contains,
              onChanged: (v) => setState(() => contains = v),
              title: const Text('Contains dangerous goods')),
          TextFormField(
              controller: unController,
              decoration: const InputDecoration(labelText: 'UN Number')),
          TextFormField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Proper shipping name')),
          TextFormField(
              controller: classController,
              decoration: const InputDecoration(labelText: 'DG Class')),
          TextFormField(
              controller: packingController,
              decoration: const InputDecoration(labelText: 'Packing group')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _save, child: const Text('Save dangerous goods'))
        ]),
      ),
    );
  }
}

class InsuranceAndHandlingForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSave;
  const InsuranceAndHandlingForm({required this.onSave, super.key});

  @override
  State<InsuranceAndHandlingForm> createState() =>
      _InsuranceAndHandlingFormState();
}

class _InsuranceAndHandlingFormState extends State<InsuranceAndHandlingForm> {
  bool requiredInsurance = false;
  final valueController = TextEditingController();
  final typeController = TextEditingController();
  final specialController = TextEditingController();

  @override
  void dispose() {
    valueController.dispose();
    typeController.dispose();
    specialController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'insuranceRequired': requiredInsurance,
      'insuranceValue': double.tryParse(valueController.text) ?? 0.0,
      'insuranceType': typeController.text,
      'specialEquipment': specialController.text,
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insurance & handling saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          SwitchListTile(
              title: const Text('Require insurance'),
              value: requiredInsurance,
              onChanged: (v) => setState(() => requiredInsurance = v)),
          TextFormField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Insurance value'),
              keyboardType: TextInputType.number),
          TextFormField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Insurance type')),
          TextFormField(
              controller: specialController,
              decoration: const InputDecoration(
                  labelText: 'Special instructions / equipment')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _save, child: const Text('Save insurance & handling')),
        ]),
      ),
    );
  }
}

class _RequestShippingScreenState extends ConsumerState<RequestShippingScreen> {
  // number of steps in the Stepper - keep in sync with the steps list below
  final int _totalSteps = 8;
  int _activeStep = 0;
  ShipmentType _selectedType = ShipmentType.air;
  bool _agreed = false;
  final GlobalKey<ShipmentFormState> _shipmentFormKey =
      GlobalKey<ShipmentFormState>();

  late final List<GlobalKey<FormState>> _formKeys;

  // Example controllers for some fields
  final TextEditingController freightTypeController = TextEditingController();
  final TextEditingController incotermController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController hsCodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // Core controllers required for submission
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController cargoDescriptionController =
      TextEditingController();

  // Mode and freight options (use _selectedType as source of truth)
  static const List<String> _airTypes = [
    'Air Express (IATA Priority)',
    'Air Freight - Standard',
    'Air Charter',
    'Air Courier',
    'Air Economy',
  ];
  static const List<String> _seaTypes = [
    'FCL - Full Container Load (20ft)',
    'FCL - Full Container Load (40ft)',
    'LCL - Less than Container Load',
    'RORO - Roll-on/Roll-off',
    'Break Bulk',
  ];

  @override
  void initState() {
    super.initState();
    _formKeys = List.generate(_totalSteps, (_) => GlobalKey<FormState>());
    // Start at an optional initial step (helps tests navigate directly)
    _activeStep = widget.initialStep ?? 0;

    // Apply optional prefill values into controllers
    final pre = widget.prefill;
    if (pre != null) {
      if (pre['senderName'] != null) {
        senderNameController.text = pre['senderName'] as String;
      }
      if (pre['destination'] != null) {
        destinationController.text = pre['destination'] as String;
      }
      if (pre['description'] != null) {
        cargoDescriptionController.text = pre['description'] as String;
      }
      if (pre['freightType'] != null) {
        freightTypeController.text = pre['freightType'] as String;
      }
      if (pre['phone'] != null) {
        phoneController.text = pre['phone'] as String;
      }
      if (pre['email'] != null) {
        emailController.text = pre['email'] as String;
      }
    }

    // Auto-fill from current user if available (helps reduce typing)
    try {
      final current = ref.read(currentUserProvider);
      if (current != null) {
        if (senderNameController.text.isEmpty) {
          senderNameController.text = current.name;
        }
        if (emailController.text.isEmpty && current.email.isNotEmpty) {
          emailController.text = current.email;
        }
        if (phoneController.text.isEmpty && (current.phone ?? '').isNotEmpty) {
          phoneController.text = current.phone ?? '';
        }
      }
    } catch (_) {}

    // Test helper: optionally auto-submit when the screen is opened at the
    // final step with prefilled data. This keeps tests fast and avoids
    // fragile tapping/scrolling interactions.
    if (widget.autoSubmitOnOpen && _activeStep == _totalSteps - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // In test mode we may want the screen to auto-agree and submit.
        setState(() {
          _agreed = true;
        });
        _submit();
      });
    }
  }

  @override
  void dispose() {
    freightTypeController.dispose();
    incotermController.dispose();
    purposeController.dispose();
    hsCodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    senderNameController.dispose();
    destinationController.dispose();
    cargoDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      ref
          .read(shippingRequestProvider.notifier)
          .updateDocs(attachments: result.files);
    }
  }

  void _nextStep() {
    // Allow skipping steps: simply advance without forcing validation
    if (_activeStep < _totalSteps - 1) {
      setState(() => _activeStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_activeStep > 0) {
      setState(() => _activeStep--);
    }
  }

  Future<void> _submit() async {
    // Debug tracing
    AppLogger.debug(
        '_submit called. agreed=$_agreed, sender=${senderNameController.text}, dest=${destinationController.text}, desc=${cargoDescriptionController.text}, freight=${freightTypeController.text}');
    // Require only core details: sender name, destination, cargo description and freight type
    final freightType = freightTypeController.text;
    if ((senderNameController.text.isEmpty) ||
        (destinationController.text.isEmpty) ||
        (cargoDescriptionController.text.isEmpty) ||
        freightType.isEmpty) {
      AppLogger.debug('missing core fields, aborting submit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please provide Sender, Destination, Cargo description and Freight type before submitting')),
      );
      return;
    }
    // Require the user to agree to terms before final submit
    if (!_agreed) {
      AppLogger.debug('user has not agreed, aborting submit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the agreement before submitting')),
      );
      return;
    }

    // Ask the embedded shipment form to validate and save its extra fields
    final formState = _shipmentFormKey.currentState;
    if (formState != null) {
      final ok = formState.validateAndSave();
      if (!ok) {
        AppLogger.debug('shipment form validation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please complete required fields in shipment details')),
        );
        return;
      }
    }

    // Persist minimal core fields into provider (after extra fields saved)
    ref.read(shippingRequestProvider.notifier).updateBasic(
          freightType: freightType,
        );
    ref.read(shippingRequestProvider.notifier).updateCustoms(
        purpose: cargoDescriptionController.text,
        hsCode: hsCodeController.text);

    // Prepare optional requester metadata if user is logged in
    final current = ref.read(currentUserProvider);
    final requester = current != null
        ? {
            'userId': current.id,
            'name': current.name,
            'email': current.email,
          }
        : {'guest': true};

    // Read current request snapshot from provider for potential inclusion
    final currentRequest = ref.read(shippingRequestProvider);

    // If this screen was opened to request shipper verification, create a
    // lightweight verification doc instead of a shipping request. This keeps
    // the same form UI for both flows (guests and registered users).
    if (widget.asShipperVerification) {
      try {
        final current = ref.read(currentUserProvider);
        // Use Firestore directly for the lightweight verification record
        // so admins can review and approve later.
        final db = ref.read(firestoreProvider);
        // If there are attachments attached to the shipping request, upload
        // them and persist download URLs in the verification record.
        final List<String> uploadedUrls = [];
        try {
          for (final att in (currentRequest['attachments'] as List? ?? [])) {
            if (att.path != null) {
              final file = File(att.path!);
              final url = await uploadFileToStorage(
                  folder: 'verifications', file: file);
              uploadedUrls.add(url);
            }
          }
        } catch (_) {
          // Non-fatal: continue without attachments if upload fails
        }

        final verDoc = await db.collection('shipper_verifications').add({
          'userId': current?.id ?? 'guest',
          'name': current?.name ?? senderNameController.text,
          'email': current?.email ?? (requester['email'] ?? ''),
          'phone': current?.phone ?? '',
          'vehicle': '',
          'attachments': uploadedUrls,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Admin notification
        await db.collection('admin_notifications').add({
          'type': 'shipper_verification',
          'verificationId': verDoc.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Verification submitted (ID: ${verDoc.id}).')));
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
        return;
      }
    }

    final reqId = await ref
            .read(shippingRequestProvider.notifier)
            .submit(requester: requester) ??
        'unknown';
    if (!mounted) return;
    // Show tracking info to the user
    final messenger = ScaffoldMessenger.of(context);
    // Debug: log when showing snackbar (helps widget tests assert presence)
    AppLogger.debug('showing snackbar for reqId=$reqId');
    messenger.showSnackBar(SnackBar(
        content: Text(
            'Request submitted (ID: $reqId). An agent will contact you shortly.')));
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(shippingRequestProvider);

    final Widget stepper = Stepper(
      currentStep: _activeStep,
      onStepContinue: _nextStep,
      onStepCancel: _prevStep,
      onStepTapped: (idx) => setState(() => _activeStep = idx),
      controlsBuilder: (context, details) {
        final isActive = details.currentStep == _activeStep;
        return Row(
          children: [
            ElevatedButton(
                key: isActive ? const Key('request_shipping_next') : null,
                onPressed: details.onStepContinue,
                child: const Text('Next')),
            const SizedBox(width: 8),
            TextButton(
                key: isActive ? const Key('request_shipping_back') : null,
                onPressed: details.onStepCancel,
                child: const Text('Back')),
          ],
        );
      },
      steps: [
        Step(
          title: const Text('Basic Info'),
          content: Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shipment Mode',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Air'),
                      selected: _selectedType == ShipmentType.air,
                      onSelected: (s) =>
                          setState(() => _selectedType = ShipmentType.air),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Sea'),
                      selected: _selectedType == ShipmentType.sea,
                      onSelected: (s) =>
                          setState(() => _selectedType = ShipmentType.sea),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Freight type dropdown based on selected _selectedType
                DropdownButtonFormField<String>(
                  initialValue: freightTypeController.text.isNotEmpty
                      ? freightTypeController.text
                      : null,
                  decoration: const InputDecoration(labelText: 'Freight Type'),
                  items: (_selectedType == ShipmentType.air
                          ? _airTypes
                          : _seaTypes)
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    freightTypeController.text = v ?? '';
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                // Core required fields (sender, destination, cargo description)
                TextFormField(
                  controller: senderNameController,
                  decoration:
                      const InputDecoration(labelText: 'Sender Full Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                      labelText: 'Destination (Country/City) *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: cargoDescriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Cargo Description *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Customs Info'),
          content: Form(
            key: _formKeys[1],
            child: Column(
              children: [
                TextFormField(
                  controller: purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (val) => ref
                      .read(shippingRequestProvider.notifier)
                      .updateCustoms(purpose: val),
                ),
                TextFormField(
                  controller: hsCodeController,
                  decoration: const InputDecoration(labelText: 'HS Code'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (val) => ref
                      .read(shippingRequestProvider.notifier)
                      .updateCustoms(hsCode: val),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Products'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductMiniForm(
                onAdd: (product) {
                  // Convert product Map to cargo format for stub provider
                  ref.read(shippingRequestProvider.notifier).addProduct({
                    'description': product['description'],
                    'quantity': product['quantity'],
                    'value': product['value'],
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text('Added products',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...(request['products'] as List? ?? []).map((p) => ListTile(
                    title: Text(p['description'] ?? ''),
                    subtitle:
                        Text('Qty: ${p['quantity']}, Value: ${p['value']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final idx =
                            (request['products'] as List? ?? []).indexOf(p);
                        ref
                            .read(shippingRequestProvider.notifier)
                            .removeProduct(idx);
                      },
                    ),
                  )),
            ],
          ),
        ),
        Step(
          title: const Text('Shipment Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shipment Mode',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Air'),
                    selected: _selectedType == ShipmentType.air,
                    onSelected: (s) =>
                        setState(() => _selectedType = ShipmentType.air),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sea'),
                    selected: _selectedType == ShipmentType.sea,
                    onSelected: (s) =>
                        setState(() => _selectedType = ShipmentType.sea),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ShipmentForm(key: _shipmentFormKey, type: _selectedType),
            ],
          ),
        ),
        Step(
          title: const Text('Dangerous Goods'),
          content: DangerousGoodsForm(onSave: (map) {
            ref.read(shippingRequestProvider.notifier).updateDangerousGoods(
                  containsDangerousGoods:
                      map['containsDangerousGoods'] as bool?,
                  unNumber: map['unNumber'] as String?,
                  properShippingName: map['properShippingName'] as String?,
                  dgClass: map['dgClass'] as String?,
                  packingGroup: map['packingGroup'] as String?,
                );
          }),
        ),
        Step(
          title: const Text('Insurance & Handling'),
          content: InsuranceAndHandlingForm(onSave: (map) {
            ref
                .read(shippingRequestProvider.notifier)
                .updateInsuranceAndHandling(
                  insuranceRequired: map['insuranceRequired'] as bool?,
                  insuranceValue: map['insuranceValue'] as double?,
                  insuranceType: map['insuranceType'] as String?,
                  specialEquipment: map['specialEquipment'] as String?,
                );
          }),
        ),
        Step(
          title: const Text('Documents'),
          content: Column(
            children: [
              ElevatedButton(
                onPressed: _pickFiles,
                child: const Text('Pick Files'),
              ),
              ...(request['attachments'] as List? ?? [])
                  .map((f) => ListTile(title: Text(f['name'] ?? ''))),
            ],
          ),
        ),
        Step(
          title: const Text('Review & Submit'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review your request: $request'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                        'I confirm that the information provided is accurate and I accept the terms.'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Use the Next button to proceed and submit once you reach the final step.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.useMainScaffold) {
      return stepper;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.maybePop(ctx),
            tooltip: 'Back',
          ),
        ),
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6.0, right: 6.0),
              child: SizedBox(
                width: 55,
                height: 65,
                child: Image.asset(
                  'assets/images/logo.png',
                  key: const Key('eh_logo'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Request Shipping',
                style: TextStyle(color: Colors.black87)),
          ],
        ),
      ),
      body: stepper,
    );
  }
}
