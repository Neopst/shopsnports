import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/models/address.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? initial;
  final bool useMainScaffold;

  const AddAddressScreen({super.key})
      : initial = null,
        useMainScaffold = true;

  const AddAddressScreen.edit(
      {super.key, required this.initial, this.useMainScaffold = true});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Home';
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _apt = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _landmark = TextEditingController();
  final _country = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final a = widget.initial!;
      _type = a.type;
      _name.text = a.name;
      _street.text = a.street;
      _apt.text = a.apt;
      _city.text = a.city;
      _state.text = a.state;
      _zip.text = a.zip;
      _landmark.text = a.landmark;
      _country.text = a.country;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    _apt.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _landmark.dispose();
    _country.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = widget.initial?.id ?? '';
    final address = Address(
      id: id,
      type: _type,
      name: _name.text,
      street: _street.text,
      apt: _apt.text,
      city: _city.text,
      state: _state.text,
      zip: _zip.text,
      landmark: _landmark.text,
      country: _country.text,
      phone: null,
      isDefault: widget.initial?.isDefault ?? false,
    );
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final form = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'Home', child: Text('Home')),
                    DropdownMenuItem(value: 'Office', child: Text('Office')),
                    DropdownMenuItem(
                        value: 'Delivery', child: Text('Delivery')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'Home'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _street,
              decoration: const InputDecoration(labelText: 'Street address'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter street address' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _apt,
              decoration: const InputDecoration(
                  labelText: 'Apartment / Suite (optional)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter city' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter state' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zip,
              decoration: const InputDecoration(labelText: 'Zip code'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter zip code' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _landmark,
              decoration:
                  const InputDecoration(labelText: 'Landmark (optional)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _country,
              decoration: const InputDecoration(labelText: 'Country'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter country' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save changes'),
            )
          ],
        ),
      ),
    );

    if (widget.useMainScaffold) {
      return MainScaffold(
        currentIndex: 0,
        onNavTap: (_) {},
        appBarTitle: 'Add address',
        body: form,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add address')),
      body: form,
    );
  }
}
