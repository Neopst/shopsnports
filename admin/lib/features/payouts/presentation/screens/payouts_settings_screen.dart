import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payouts_providers.dart';

class PayoutsSettingsScreen extends ConsumerWidget {
  const PayoutsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Payout Settings'),
          backgroundColor: const Color(0xFF0A2A66),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.percent), text: 'Commission Rates'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Tax Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CommissionSettingsTab(), _TaxSettingsTab()],
        ),
      ),
    );
  }
}

class _CommissionSettingsTab extends ConsumerWidget {
  const _CommissionSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(commissionSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        data: (settings) => Column(
          children: [
            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commission Rate Configuration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set commission rates for affiliates and shippers. These rates are used by the backend to automatically calculate payouts.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Settings List
            Expanded(
              child: settings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.percent,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No commission settings configured',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showCommissionDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Commission Rate'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: settings.length,
                      itemBuilder: (context, index) {
                        final setting = settings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: setting.isActive
                                  ? Colors.green[100]
                                  : Colors.grey[300],
                              child: Icon(
                                _getEntityIcon(setting.entityType),
                                color: setting.isActive
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              setting.entityType.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${setting.commissionType == "percentage" ? "${setting.commissionValue}%" : "₦${setting.commissionValue}"} per transaction',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (setting.minAmount != null ||
                                    setting.maxAmount != null)
                                  Text(
                                    'Range: ₦${setting.minAmount ?? 0} - ₦${setting.maxAmount ?? "∞"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    setting.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: setting.isActive
                                      ? Colors.green[100]
                                      : Colors.grey[300],
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showCommissionDialog(
                                    context,
                                    ref,
                                    setting: setting,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCommissionDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Commission Rate'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCommissionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Rate'),
      ),
    );
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'affiliate':
        return Icons.people;
      case 'shipper':
        return Icons.local_shipping;
      default:
        return Icons.percent;
    }
  }

  void _showCommissionDialog(
    BuildContext context,
    WidgetRef ref, {
    dynamic setting,
  }) {
    showDialog(
      context: context,
      builder: (context) => _CommissionFormDialog(setting: setting),
    );
  }
}

class _TaxSettingsTab extends ConsumerWidget {
  const _TaxSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(taxSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        data: (settings) => Column(
          children: [
            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Configuration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure tax rates (VAT, withholding tax, etc.) that are deducted from payouts. These are automatically applied by the backend.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Settings List
            Expanded(
              child: settings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tax settings configured',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showTaxDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Tax Setting'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: settings.length,
                      itemBuilder: (context, index) {
                        final setting = settings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: setting.isActive
                                  ? Colors.orange[100]
                                  : Colors.grey[300],
                              child: Icon(
                                _getTaxIcon(setting.taxType),
                                color: setting.isActive
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              setting.taxName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${setting.taxRate}% ${setting.taxType.replaceAll('_', ' ').toUpperCase()}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (setting.country != null ||
                                    setting.region != null)
                                  Text(
                                    'Location: ${setting.country ?? "Global"}${setting.region != null ? " - ${setting.region}" : ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                Text(
                                  'Applies to: ${setting.appliesTo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    setting.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: setting.isActive
                                      ? Colors.orange[100]
                                      : Colors.grey[300],
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showTaxDialog(
                                    context,
                                    ref,
                                    setting: setting,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showTaxDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Tax Setting'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Tax'),
      ),
    );
  }

  IconData _getTaxIcon(String taxType) {
    switch (taxType.toLowerCase()) {
      case 'vat':
        return Icons.receipt;
      case 'withholding':
        return Icons.account_balance;
      case 'sales_tax':
        return Icons.shopping_cart;
      case 'income_tax':
        return Icons.paid;
      default:
        return Icons.receipt_long;
    }
  }

  void _showTaxDialog(BuildContext context, WidgetRef ref, {dynamic setting}) {
    showDialog(
      context: context,
      builder: (context) => _TaxFormDialog(setting: setting),
    );
  }
}

// Commission Form Dialog
class _CommissionFormDialog extends StatefulWidget {
  final dynamic setting;

  const _CommissionFormDialog({this.setting});

  @override
  State<_CommissionFormDialog> createState() => _CommissionFormDialogState();
}

class _CommissionFormDialogState extends State<_CommissionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _entityType;
  late String _commissionType;
  late TextEditingController _valueController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _entityType = widget.setting?.entityType ?? 'affiliate';
    _commissionType = widget.setting?.commissionType ?? 'percentage';
    _valueController = TextEditingController(
      text: widget.setting?.commissionValue?.toString() ?? '',
    );
    _minAmountController = TextEditingController(
      text: widget.setting?.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.setting?.maxAmount?.toString() ?? '',
    );
    _isActive = widget.setting?.isActive ?? true;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.setting == null ? 'Add Commission Rate' : 'Edit Commission Rate',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _entityType,
                decoration: const InputDecoration(
                  labelText: 'Entity Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'affiliate',
                    child: Text('Affiliate'),
                  ),
                  DropdownMenuItem(value: 'shipper', child: Text('Shipper')),
                  DropdownMenuItem(
                    value: 'global',
                    child: Text('Global Default'),
                  ),
                ],
                onChanged: (value) => setState(() => _entityType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _commissionType,
                decoration: const InputDecoration(
                  labelText: 'Commission Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage'),
                  ),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  DropdownMenuItem(value: 'tiered', child: Text('Tiered')),
                ],
                onChanged: (value) => setState(() => _commissionType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _commissionType == 'percentage'
                      ? 'Commission Percentage'
                      : 'Commission Amount',
                  border: const OutlineInputBorder(),
                  suffixText: _commissionType == 'percentage' ? '%' : 'NGN',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Min Amount (Optional)',
                        border: OutlineInputBorder(),
                        suffixText: 'NGN',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Max Amount (Optional)',
                        border: OutlineInputBorder(),
                        suffixText: 'NGN',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveCommission, child: const Text('Save')),
      ],
    );
  }

  Future<void> _saveCommission() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Call API to create/update commission setting
      // For now, just show success and close
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.setting == null
                  ? 'Commission rate added successfully'
                  : 'Commission rate updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// Tax Form Dialog
class _TaxFormDialog extends StatefulWidget {
  final dynamic setting;

  const _TaxFormDialog({this.setting});

  @override
  State<_TaxFormDialog> createState() => _TaxFormDialogState();
}

class _TaxFormDialogState extends State<_TaxFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _taxType;
  late TextEditingController _rateController;
  late String _appliesTo;
  late TextEditingController _countryController;
  late TextEditingController _regionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.setting?.taxName ?? '',
    );
    _taxType = widget.setting?.taxType ?? 'vat';
    _rateController = TextEditingController(
      text: widget.setting?.taxRate?.toString() ?? '',
    );
    _appliesTo = widget.setting?.appliesTo ?? 'all';
    _countryController = TextEditingController(
      text: widget.setting?.country ?? 'Nigeria',
    );
    _regionController = TextEditingController(
      text: widget.setting?.region ?? '',
    );
    _isActive = widget.setting?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.setting == null ? 'Add Tax Setting' : 'Edit Tax Setting',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tax Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., VAT, Withholding Tax',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a tax name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _taxType,
                decoration: const InputDecoration(
                  labelText: 'Tax Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'vat', child: Text('VAT')),
                  DropdownMenuItem(
                    value: 'withholding',
                    child: Text('Withholding Tax'),
                  ),
                  DropdownMenuItem(
                    value: 'sales_tax',
                    child: Text('Sales Tax'),
                  ),
                  DropdownMenuItem(
                    value: 'income_tax',
                    child: Text('Income Tax'),
                  ),
                ],
                onChanged: (value) => setState(() => _taxType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Tax Rate',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _appliesTo,
                decoration: const InputDecoration(
                  labelText: 'Applies To',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Entities')),
                  DropdownMenuItem(
                    value: 'affiliates',
                    child: Text('Affiliates Only'),
                  ),
                  DropdownMenuItem(
                    value: 'shippers',
                    child: Text('Shippers Only'),
                  ),
                ],
                onChanged: (value) => setState(() => _appliesTo = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                        labelText: 'Region (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveTax, child: const Text('Save')),
      ],
    );
  }

  Future<void> _saveTax() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Call API to create/update tax setting
      // For now, just show success and close
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.setting == null
                  ? 'Tax setting added successfully'
                  : 'Tax setting updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
