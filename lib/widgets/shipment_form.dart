// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
// Note: shipping_request_provider moved to request_shipping_screen.dart as stub

enum ShipmentType { air, sea }

/// A reusable form widget for Air/Sea shipment requests. The form preserves
/// the original visual style (section headers, field layout) from the provided
/// Air form while wiring data into the existing shippingRequestProvider.
class ShipmentForm extends ConsumerStatefulWidget {
  const ShipmentForm({super.key, required this.type});

  final ShipmentType type;

  @override
  ConsumerState<ShipmentForm> createState() => ShipmentFormState();
}

class ShipmentFormState extends ConsumerState<ShipmentForm> {
  final _formKey = GlobalKey<FormState>();

  // Sender
  final TextEditingController _senderName = TextEditingController();
  final TextEditingController _senderCompany = TextEditingController();
  final TextEditingController _senderAddress = TextEditingController();
  final TextEditingController _senderCity = TextEditingController();
  final TextEditingController _senderState = TextEditingController();
  final TextEditingController _senderPostal = TextEditingController();
  final TextEditingController _senderCountry = TextEditingController();
  final TextEditingController _senderPhone = TextEditingController();
  final TextEditingController _senderEmail = TextEditingController();
  final TextEditingController _senderTax = TextEditingController();

  // Recipient
  final TextEditingController _recipientName = TextEditingController();
  final TextEditingController _recipientCompany = TextEditingController();
  final TextEditingController _recipientAddress = TextEditingController();
  final TextEditingController _recipientCity = TextEditingController();
  final TextEditingController _recipientState = TextEditingController();
  final TextEditingController _recipientPostal = TextEditingController();
  final TextEditingController _recipientCountry = TextEditingController();
  final TextEditingController _recipientPhone = TextEditingController();
  final TextEditingController _recipientEmail = TextEditingController();

  // Commodity
  final TextEditingController _commodity = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _dimensions = TextEditingController();
  final TextEditingController _packages = TextEditingController();
  final TextEditingController _value = TextEditingController();
  final TextEditingController _hs = TextEditingController();
  final TextEditingController _waybill = TextEditingController();
  final TextEditingController _otherPackaging = TextEditingController();

  // Pickup/delivery
  final TextEditingController _pickupDate = TextEditingController();
  final TextEditingController _pickupTime = TextEditingController();
  final TextEditingController _deliveryDate = TextEditingController();
  final TextEditingController _pickupAddress = TextEditingController();
  final TextEditingController _deliveryInstructions = TextEditingController();

  // Insurance & misc
  final TextEditingController _insuranceAmount = TextEditingController();
  final TextEditingController _otherHandling = TextEditingController();
  final TextEditingController _comments = TextEditingController();

  bool _hazardous = false;
  String _packagingType = '';
  bool _insurance = false;
  bool _customs = false;
  final List<String> _specialHandling = [];
  bool _agree1 = false;
  bool _agree2 = false;

  List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _senderName.dispose();
    _senderCompany.dispose();
    _senderAddress.dispose();
    _senderCity.dispose();
    _senderState.dispose();
    _senderPostal.dispose();
    _senderCountry.dispose();
    _senderPhone.dispose();
    _senderEmail.dispose();
    _senderTax.dispose();

    _recipientName.dispose();
    _recipientCompany.dispose();
    _recipientAddress.dispose();
    _recipientCity.dispose();
    _recipientState.dispose();
    _recipientPostal.dispose();
    _recipientCountry.dispose();
    _recipientPhone.dispose();
    _recipientEmail.dispose();

    _commodity.dispose();
    _weight.dispose();
    _dimensions.dispose();
    _packages.dispose();
    _value.dispose();
    _hs.dispose();
    _waybill.dispose();
    _otherPackaging.dispose();

    _pickupDate.dispose();
    _pickupTime.dispose();
    _deliveryDate.dispose();
    _pickupAddress.dispose();
    _deliveryInstructions.dispose();

    _insuranceAmount.dispose();
    _otherHandling.dispose();
    _comments.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res != null) {
      setState(() => _attachments = res.files);
      // TODO: Update provider or handle attachments differently
      // ref
      //     .read(shippingRequestProvider.notifier)
      //     .updateDocs(attachments: _attachments);
    }
  }

  bool validateAndSave() {
    if (!_formKey.currentState!.validate()) return false;
    if (!_agree1 || !_agree2) return false;

    // Collect into map and save via updateExtra
    final map = <String, dynamic>{
      'sender': {
        'name': _senderName.text,
        'company': _senderCompany.text,
        'address': _senderAddress.text,
        'city': _senderCity.text,
        'state': _senderState.text,
        'postal': _senderPostal.text,
        'country': _senderCountry.text,
        'phone': _senderPhone.text,
        'email': _senderEmail.text,
        'tax': _senderTax.text,
      },
      'recipient': {
        'name': _recipientName.text,
        'company': _recipientCompany.text,
        'address': _recipientAddress.text,
        'city': _recipientCity.text,
        'state': _recipientState.text,
        'postal': _recipientPostal.text,
        'country': _recipientCountry.text,
        'phone': _recipientPhone.text,
        'email': _recipientEmail.text,
      },
      'commodity': {
        'description': _commodity.text,
        'weight': _weight.text,
        'dimensions': _dimensions.text,
        'packages': _packages.text,
        'value': _value.text,
        'hs': _hs.text,
        'waybill': _waybill.text,
        'packagingOther': _otherPackaging.text,
      },
      'schedule': {
        'pickupDate': _pickupDate.text,
        'pickupTime': _pickupTime.text,
        'deliveryDate': _deliveryDate.text,
        'pickupAddress': _pickupAddress.text,
        'deliveryInstructions': _deliveryInstructions.text,
      },
      'insurance': {
        'required': _insurance,
        'amount': _insuranceAmount.text,
        'otherHandling': _otherHandling.text,
      },
      'specialHandling': _specialHandling,
      'agreements': {'a1': _agree1, 'a2': _agree2},
      'comments': _comments.text,
    };

    // TODO: Update provider or handle data differently
    // ref.read(shippingRequestProvider.notifier).updateExtra(map);

    // Log for debugging
    debugPrint('Shipment form data: $map');
    return true;
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2463))),
      );

  Widget _textField(String label, TextEditingController controller, bool req,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: req
            ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _dateField(
      String label, TextEditingController controller, bool req, bool isPickup) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 1),
              );
              if (picked != null) {
                controller.text =
                    '${picked.day}/${picked.month}/${picked.year}';
              }
            },
          ),
        ),
        validator: req
            ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
            : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 1),
          );
          if (picked != null) {
            controller.text = '${picked.day}/${picked.month}/${picked.year}';
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAir = widget.type == ShipmentType.air;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField('Full Name *', _senderName, true),
          _textField('Company Name (if applicable)', _senderCompany, false),
          _textField('Street Address *', _senderAddress, true),
          Row(children: [
            Expanded(child: _textField('City *', _senderCity, true)),
            const SizedBox(width: 8),
            Expanded(child: _textField('State/Province', _senderState, false)),
          ]),
          Row(children: [
            Expanded(
                child: _textField('Postal/ZIP Code *', _senderPostal, true)),
            const SizedBox(width: 8),
            Expanded(child: _textField('Country *', _senderCountry, true)),
          ]),
          _textField('Contact Phone Number *', _senderPhone, true,
              keyboardType: TextInputType.phone),
          _textField('Email Address *', _senderEmail, true,
              keyboardType: TextInputType.emailAddress),
          _textField('Tax ID/VAT Number (if applicable)', _senderTax, false),
          const SizedBox(height: 12),
          _sectionHeader('2. Recipient Details'),
          _textField('Full Name *', _recipientName, true),
          _textField('Company Name (if applicable)', _recipientCompany, false),
          _textField('Street Address *', _recipientAddress, true),
          Row(children: [
            Expanded(child: _textField('City *', _recipientCity, true)),
            const SizedBox(width: 8),
            Expanded(
                child: _textField('State/Province', _recipientState, false)),
          ]),
          Row(children: [
            Expanded(
                child: _textField('Postal/ZIP Code *', _recipientPostal, true)),
            const SizedBox(width: 8),
            Expanded(child: _textField('Country *', _recipientCountry, true)),
          ]),
          _textField('Contact Phone Number *', _recipientPhone, true,
              keyboardType: TextInputType.phone),
          _textField('Email Address', _recipientEmail, false,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _sectionHeader(isAir
              ? '3. Air Freight Shipment Information'
              : '3. Sea Freight Shipment Information'),
          _textField('Commodity Description *', _commodity, true),
          Row(children: [
            Expanded(
                child: _textField('Total Weight (kg) *', _weight, true,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(
                child: _textField('Number of Packages *', _packages, true,
                    keyboardType: TextInputType.number)),
          ]),
          _textField(
              'Dimensions per Package (L x W x H, cm) *', _dimensions, true),
          _textField('Declared Value (USD or local currency) *', _value, true,
              keyboardType: TextInputType.number),
          if (isAir) ...[
            const Text('Hazardous Materials Declaration (IATA Compliance) *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Column(children: [
              RadioListTile<bool>(
                value: false,
                groupValue: _hazardous,
                title: const Text('No'),
                onChanged: (v) => setState(() => _hazardous = v ?? false),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: _hazardous,
                title: const Text('Yes'),
                onChanged: (v) => setState(() => _hazardous = v ?? false),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            if (_hazardous)
              _textField(
                  'Provide UN Number, Proper Shipping Name, and Class/Division',
                  _otherHandling,
                  true),
            const SizedBox(height: 8),
            const Text('Packaging Type *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Column(children: [
              RadioListTile<String>(
                value: 'pallets',
                groupValue: _packagingType,
                title: const Text('Pallets'),
                onChanged: (v) => setState(() => _packagingType = v ?? ''),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'crates',
                groupValue: _packagingType,
                title: const Text('Crates'),
                onChanged: (v) => setState(() => _packagingType = v ?? ''),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'cartons',
                groupValue: _packagingType,
                title: const Text('Cartons'),
                onChanged: (v) => setState(() => _packagingType = v ?? ''),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'other',
                groupValue: _packagingType,
                title: const Text('Other (Specify):'),
                onChanged: (v) => setState(() => _packagingType = v ?? ''),
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
              ),
              if (_packagingType == 'other')
                _textField('Specify packaging type', _otherPackaging, true),
            ]),
            _textField('Harmonized System (HS) Code *', _hs, true),
            _textField(
                'Air Waybill Instructions (if applicable)', _waybill, false,
                maxLines: 3),
          ] else ...[
            // Sea-specific extra fields
            _textField('Container Type (e.g., 20FT/40FT/Reefer)',
                _otherPackaging, true),
            _textField('FCL or LCL', _waybill, true),
            _textField('Port of Loading', _pickupAddress, true),
            _textField('Port of Discharge', _deliveryInstructions, true),
            _textField('Estimated Sailing Date', _deliveryDate, false),
          ],
          const SizedBox(height: 12),
          _sectionHeader('4. Pickup and Delivery Schedule'),
          _dateField('Requested Pickup Date *', _pickupDate, true, true),
          _textField('Preferred Pickup Time Window', _pickupTime, false),
          _dateField('Requested Delivery Date (if applicable)', _deliveryDate,
              false, false),
          _textField('Pickup Address (if different from Sender Details)',
              _pickupAddress, false,
              maxLines: 3),
          _textField('Delivery Instructions', _deliveryInstructions, false,
              maxLines: 3),
          const SizedBox(height: 12),
          _sectionHeader('5. Additional Services'),
          const Text('Insurance Coverage',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Column(children: [
            RadioListTile<bool>(
              value: false,
              groupValue: _insurance,
              title: const Text('No'),
              onChanged: (v) => setState(() => _insurance = v ?? false),
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _insurance,
              title: const Text('Yes'),
              onChanged: (v) => setState(() => _insurance = v ?? false),
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          if (_insurance)
            _textField('Specify Insurance Amount', _insuranceAmount, true,
                keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          const Text('Customs Clearance Documents *',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Column(children: [
            RadioListTile<bool>(
              value: false,
              groupValue: _customs,
              title: const Text('Not Required'),
              onChanged: (v) => setState(() => _customs = v ?? false),
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _customs,
              title: const Text('Provided'),
              onChanged: (v) => setState(() => _customs = v ?? false),
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 8),
          const Text('Special Handling Requirements',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Checkbox(
                value: _specialHandling.contains('temp'),
                onChanged: (v) => setState(() {
                      if (v!) {
                        _specialHandling.add('temp');
                      } else {
                        _specialHandling.remove('temp');
                      }
                    })),
            const Text('Temperature-Controlled'),
          ]),
          Row(children: [
            Checkbox(
                value: _specialHandling.contains('fragile'),
                onChanged: (v) => setState(() {
                      if (v!) {
                        _specialHandling.add('fragile');
                      } else {
                        _specialHandling.remove('fragile');
                      }
                    })),
            const Text('Fragile'),
          ]),
          Row(children: [
            Checkbox(
                value: _specialHandling.contains('perishable'),
                onChanged: (v) => setState(() {
                      if (v!) {
                        _specialHandling.add('perishable');
                      } else {
                        _specialHandling.remove('perishable');
                      }
                    })),
            const Text('Perishable'),
          ]),
          Row(children: [
            Checkbox(
                value: _specialHandling.contains('other'),
                onChanged: (v) => setState(() {
                      if (v!) {
                        _specialHandling.add('other');
                      } else {
                        _specialHandling.remove('other');
                      }
                    })),
            const Text('Other (Specify):'),
          ]),
          if (_specialHandling.contains('other'))
            _textField(
                'Specify other handling requirements', _otherHandling, true,
                maxLines: 2),
          const SizedBox(height: 12),
          _sectionHeader('6. Additional Comments or Notes'),
          _textField('Additional Comments or Requirements', _comments, false,
              maxLines: 4),
          const SizedBox(height: 12),
          _sectionHeader('7. Attach Supporting Documents'),
          const Text(
              'Upload commercial invoices, packing lists, certificates of origin, or other relevant documents',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('ATTACH SUPPORTING DOCUMENTS'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2463),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
          const SizedBox(height: 8),
          if (_attachments.isNotEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Attached Files:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._attachments.asMap().entries.map((e) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text('Document \\${e.key + 1}'),
                    subtitle: Text(e.value.name),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _attachments.removeAt(e.key))),
                  )),
            ]),
          const SizedBox(height: 12),
          _sectionHeader('8. Declaration and Agreement'),
          Row(children: [
            Checkbox(
                value: _agree1, onChanged: (v) => setState(() => _agree1 = v!)),
            const Expanded(
              child: Text(
                  'I certify that the information provided is accurate and complies with regulations *',
                  style: TextStyle(fontSize: 12)),
            ),
          ]),
          Row(children: [
            Checkbox(
                value: _agree2, onChanged: (v) => setState(() => _agree2 = v!)),
            const Expanded(
              child: Text(
                  'I agree to the Terms of Service and Conditions of Carriage *',
                  style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
