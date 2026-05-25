import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/index.dart';

class ShippingZoneFormDialog extends ConsumerStatefulWidget {
  final ShippingZone? zone;

  const ShippingZoneFormDialog({super.key, this.zone});

  @override
  ConsumerState<ShippingZoneFormDialog> createState() =>
      _ShippingZoneFormDialogState();
}

class _ShippingZoneFormDialogState
    extends ConsumerState<ShippingZoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late bool _isActive;
  late List<String> _regions;
  final _regionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone?.name ?? '');
    _rateController = TextEditingController(
      text: widget.zone?.shippingRate.toString() ?? '',
    );
    _isActive = widget.zone?.isActive ?? true;
    _regions = List.from(widget.zone?.regions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _addRegion() {
    final region = _regionController.text.trim();
    if (region.isNotEmpty && !_regions.contains(region)) {
      setState(() {
        _regions.add(region);
        _regionController.clear();
      });
    }
  }

  void _removeRegion(String region) {
    setState(() {
      _regions.remove(region);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.zone == null
                        ? 'Add Shipping Zone'
                        : 'Edit Shipping Zone',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Zone Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          hintText: 'e.g., Lagos & Surroundings',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Shipping Rate
                      TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Shipping Rate *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_exchange),
                          hintText: '2500',
                          suffixText: 'NGN',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Rate is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Active Status
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Make this zone available'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                      const Divider(height: 32),
                      // Regions Section
                      const Text(
                        'Regions in this Zone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Add Region Field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _regionController,
                              decoration: const InputDecoration(
                                labelText: 'Add Region',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., Lagos Island, Ikeja',
                              ),
                              onSubmitted: (_) => _addRegion(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addRegion,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Regions List
                      if (_regions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No regions added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _regions.map((region) {
                              return Chip(
                                label: Text(region),
                                onDeleted: () => _removeRegion(region),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveZone,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Zone'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveZone() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_regions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one region'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final zone = ShippingZone(
        id: widget.zone?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        regions: _regions,
        shippingRate: double.parse(_rateController.text),
        isActive: _isActive,
      );

      Navigator.pop(context, zone);
    }
  }
}
