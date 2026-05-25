import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_template.dart';
import '../../data/repositories/invoice_template_repository.dart';

final templateRepositoryProvider = Provider<InvoiceTemplateRepository>((ref) {
  return InvoiceTemplateRepository(FirebaseFirestore.instance);
});

final templatesProvider = StreamProvider<List<InvoiceTemplate>>((ref) {
  return ref.watch(templateRepositoryProvider).getAllTemplates();
});

class InvoiceTemplatesScreen extends ConsumerStatefulWidget {
  const InvoiceTemplatesScreen({super.key});

  @override
  ConsumerState<InvoiceTemplatesScreen> createState() => _InvoiceTemplatesScreenState();
}

class _InvoiceTemplatesScreenState extends ConsumerState<InvoiceTemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTemplateDialog(context),
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('No templates found'));
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return _buildTemplateCard(templates[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTemplateCard(InvoiceTemplate template) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            if (template.isDefault)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(template.name)),
            _buildStatusChip(template.isActive),
          ],
        ),
        subtitle: Text(template.description),
        trailing: _buildActionButtons(template),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Company', template.companyName),
                _buildInfoRow('Layout', template.layout.name),
                _buildInfoRow('Color Scheme', template.colorScheme.name),
                _buildInfoRow('Usage Count', template.usageCount.toString()),
                _buildInfoRow('Created', _formatDate(template.createdAt)),
                if (template.updatedAt != null)
                  _buildInfoRow('Updated', _formatDate(template.updatedAt!)),
                const Divider(),
                _buildPreviewSection(template),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive'),
      backgroundColor: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isActive ? Colors.green : Colors.grey,
        fontSize: 12,
      ),
    );
  }

  Widget _buildActionButtons(InvoiceTemplate template) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!template.isDefault)
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: () => _setAsDefault(template),
            tooltip: 'Set as Default',
          ),
        IconButton(
          icon: Icon(template.isActive ? Icons.visibility : Icons.visibility_off),
          onPressed: () => _toggleActive(template),
          tooltip: template.isActive ? 'Deactivate' : 'Activate',
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () => _duplicateTemplate(template),
          tooltip: 'Duplicate',
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editTemplate(template),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteTemplate(template),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildPreviewSection(InvoiceTemplate template) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorForScheme(template.colorScheme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorForScheme(template.colorScheme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template.showLogo && template.logoUrl.isNotEmpty)
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.business, size: 24),
            ),
          if (template.showCompanyInfo) ...[
            const SizedBox(height: 8),
            Text(
              template.companyName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              template.companyAddress,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Sections:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...template.sections.map((section) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  section.isVisible ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: section.isVisible ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(section.name, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getColorForScheme(TemplateColorScheme scheme) {
    switch (scheme) {
      case TemplateColorScheme.blue:
        return Colors.blue;
      case TemplateColorScheme.green:
        return Colors.green;
      case TemplateColorScheme.purple:
        return Colors.purple;
      case TemplateColorScheme.red:
        return Colors.red;
      case TemplateColorScheme.orange:
        return Colors.orange;
      case TemplateColorScheme.gray:
        return Colors.grey;
      case TemplateColorScheme.dark:
        return Colors.black;
      case TemplateColorScheme.custom:
        return Colors.indigo;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTemplateDialog(),
    );
  }

  void _setAsDefault(InvoiceTemplate template) {
    ref.read(templateRepositoryProvider).setAsDefault(template.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.name} set as default')),
    );
  }

  void _toggleActive(InvoiceTemplate template) {
    ref.read(templateRepositoryProvider).toggleActive(template.id, !template.isActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.name} ${template.isActive ? 'deactivated' : 'activated'}')),
    );
  }

  void _duplicateTemplate(InvoiceTemplate template) async {
    try {
      await ref.read(templateRepositoryProvider).duplicateTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template duplicated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating: $e')),
        );
      }
    }
  }

  void _editTemplate(InvoiceTemplate template) {
    showDialog(
      context: context,
      builder: (context) => EditTemplateDialog(template: template),
    );
  }

  void _deleteTemplate(InvoiceTemplate template) {
    if (template.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default template')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete ${template.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(templateRepositoryProvider).deleteTemplate(template.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${template.name} deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) async {
    final stats = await ref.read(templateRepositoryProvider).getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Templates', stats['totalTemplates'].toString()),
            _buildStatRow('Active Templates', stats['activeTemplates'].toString()),
            _buildStatRow('Total Usage', stats['totalUsage'].toString()),
            const Divider(),
            const Text('Layout Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(stats['layoutCounts'] as Map<TemplateLayout, int>).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${entry.key.name}: ${entry.value}'),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class CreateTemplateDialog extends ConsumerStatefulWidget {
  const CreateTemplateDialog({super.key});

  @override
  ConsumerState<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankRoutingController = TextEditingController();
  final _paymentTermsController = TextEditingController(text: 'Net 30');
  final _notesController = TextEditingController();
  final _footerController = TextEditingController();

  TemplateLayout _selectedLayout = TemplateLayout.standard;
  TemplateColorScheme _selectedColorScheme = TemplateColorScheme.blue;
  bool _showLogo = true;
  bool _showCompanyInfo = true;
  bool _showBankDetails = true;
  bool _showTaxId = true;
  bool _showPaymentTerms = true;
  bool _isDefault = false;

  final List<TemplateSection> _sections = [
    TemplateSection(
      id: '1',
      name: 'Header',
      type: SectionType.header,
      order: 0,
    ),
    TemplateSection(
      id: '2',
      name: 'Company Info',
      type: SectionType.companyInfo,
      order: 1,
    ),
    TemplateSection(
      id: '3',
      name: 'Customer Info',
      type: SectionType.customerInfo,
      order: 2,
    ),
    TemplateSection(
      id: '4',
      name: 'Line Items',
      type: SectionType.lineItems,
      order: 3,
    ),
    TemplateSection(
      id: '5',
      name: 'Totals',
      type: SectionType.total,
      order: 4,
    ),
    TemplateSection(
      id: '6',
      name: 'Payment Info',
      type: SectionType.paymentInfo,
      order: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Invoice Template'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Template Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const Divider(),
              const Text('Company Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              TextFormField(
                controller: _companyAddressController,
                decoration: const InputDecoration(labelText: 'Company Address'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _companyPhoneController,
                decoration: const InputDecoration(labelText: 'Company Phone'),
              ),
              TextFormField(
                controller: _companyEmailController,
                decoration: const InputDecoration(labelText: 'Company Email'),
              ),
              TextFormField(
                controller: _companyWebsiteController,
                decoration: const InputDecoration(labelText: 'Company Website'),
              ),
              const Divider(),
              const Text('Bank Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
              TextFormField(
                controller: _bankRoutingController,
                decoration: const InputDecoration(labelText: 'Routing Number'),
              ),
              const Divider(),
              const Text('Template Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<TemplateLayout>(
                value: _selectedLayout,
                decoration: const InputDecoration(labelText: 'Layout'),
                items: TemplateLayout.values.map((layout) {
                  return DropdownMenuItem(
                    value: layout,
                    child: Text(layout.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLayout = value!);
                },
              ),
              DropdownButtonFormField<TemplateColorScheme>(
                value: _selectedColorScheme,
                decoration: const InputDecoration(labelText: 'Color Scheme'),
                items: TemplateColorScheme.values.map((scheme) {
                  return DropdownMenuItem(
                    value: scheme,
                    child: Text(scheme.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedColorScheme = value!);
                },
              ),
              TextFormField(
                controller: _paymentTermsController,
                decoration: const InputDecoration(labelText: 'Payment Terms'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _footerController,
                decoration: const InputDecoration(labelText: 'Footer'),
                maxLines: 2,
              ),
              const Divider(),
              const Text('Display Options', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Show Logo'),
                value: _showLogo,
                onChanged: (value) => setState(() => _showLogo = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Company Info'),
                value: _showCompanyInfo,
                onChanged: (value) => setState(() => _showCompanyInfo = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Bank Details'),
                value: _showBankDetails,
                onChanged: (value) => setState(() => _showBankDetails = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Tax ID'),
                value: _showTaxId,
                onChanged: (value) => setState(() => _showTaxId = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Payment Terms'),
                value: _showPaymentTerms,
                onChanged: (value) => setState(() => _showPaymentTerms = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Set as Default'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
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
        ElevatedButton(
          onPressed: _createTemplate,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final template = InvoiceTemplate(
      id: '',
      name: _nameController.text,
      description: _descriptionController.text,
      companyName: _companyNameController.text,
      companyAddress: _companyAddressController.text,
      companyPhone: _companyPhoneController.text,
      companyEmail: _companyEmailController.text,
      companyWebsite: _companyWebsiteController.text,
      taxId: _taxIdController.text,
      bankName: _bankNameController.text,
      bankAccountNumber: _bankAccountController.text,
      bankRoutingNumber: _bankRoutingController.text,
      layout: _selectedLayout,
      colorScheme: _selectedColorScheme,
      sections: _sections,
      showLogo: _showLogo,
      showCompanyInfo: _showCompanyInfo,
      showBankDetails: _showBankDetails,
      showTaxId: _showTaxId,
      showPaymentTerms: _showPaymentTerms,
      paymentTerms: _paymentTermsController.text,
      notes: _notesController.text,
      footer: _footerController.text,
      isDefault: _isDefault,
      isActive: true,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    );

    ref.read(templateRepositoryProvider).createTemplate(template);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template created')),
    );
  }
}

class EditTemplateDialog extends ConsumerStatefulWidget {
  final InvoiceTemplate template;

  const EditTemplateDialog({super.key, required this.template});

  @override
  ConsumerState<EditTemplateDialog> createState() => _EditTemplateDialogState();
}

class _EditTemplateDialogState extends ConsumerState<EditTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyAddressController;
  late final TextEditingController _companyPhoneController;
  late final TextEditingController _companyEmailController;
  late final TextEditingController _companyWebsiteController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountController;
  late final TextEditingController _bankRoutingController;
  late final TextEditingController _paymentTermsController;
  late final TextEditingController _notesController;
  late final TextEditingController _footerController;

  late TemplateLayout _selectedLayout;
  late TemplateColorScheme _selectedColorScheme;
  late bool _showLogo;
  late bool _showCompanyInfo;
  late bool _showBankDetails;
  late bool _showTaxId;
  late bool _showPaymentTerms;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController = TextEditingController(text: widget.template.description);
    _companyNameController = TextEditingController(text: widget.template.companyName);
    _companyAddressController = TextEditingController(text: widget.template.companyAddress);
    _companyPhoneController = TextEditingController(text: widget.template.companyPhone);
    _companyEmailController = TextEditingController(text: widget.template.companyEmail);
    _companyWebsiteController = TextEditingController(text: widget.template.companyWebsite);
    _taxIdController = TextEditingController(text: widget.template.taxId);
    _bankNameController = TextEditingController(text: widget.template.bankName);
    _bankAccountController = TextEditingController(text: widget.template.bankAccountNumber);
    _bankRoutingController = TextEditingController(text: widget.template.bankRoutingNumber);
    _paymentTermsController = TextEditingController(text: widget.template.paymentTerms);
    _notesController = TextEditingController(text: widget.template.notes);
    _footerController = TextEditingController(text: widget.template.footer);

    _selectedLayout = widget.template.layout;
    _selectedColorScheme = widget.template.colorScheme;
    _showLogo = widget.template.showLogo;
    _showCompanyInfo = widget.template.showCompanyInfo;
    _showBankDetails = widget.template.showBankDetails;
    _showTaxId = widget.template.showTaxId;
    _showPaymentTerms = widget.template.showPaymentTerms;
    _isDefault = widget.template.isDefault;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Invoice Template'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Template Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const Divider(),
              const Text('Company Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              TextFormField(
                controller: _companyAddressController,
                decoration: const InputDecoration(labelText: 'Company Address'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _companyPhoneController,
                decoration: const InputDecoration(labelText: 'Company Phone'),
              ),
              TextFormField(
                controller: _companyEmailController,
                decoration: const InputDecoration(labelText: 'Company Email'),
              ),
              TextFormField(
                controller: _companyWebsiteController,
                decoration: const InputDecoration(labelText: 'Company Website'),
              ),
              const Divider(),
              const Text('Bank Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
              TextFormField(
                controller: _bankRoutingController,
                decoration: const InputDecoration(labelText: 'Routing Number'),
              ),
              const Divider(),
              const Text('Template Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<TemplateLayout>(
                value: _selectedLayout,
                decoration: const InputDecoration(labelText: 'Layout'),
                items: TemplateLayout.values.map((layout) {
                  return DropdownMenuItem(
                    value: layout,
                    child: Text(layout.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLayout = value!);
                },
              ),
              DropdownButtonFormField<TemplateColorScheme>(
                value: _selectedColorScheme,
                decoration: const InputDecoration(labelText: 'Color Scheme'),
                items: TemplateColorScheme.values.map((scheme) {
                  return DropdownMenuItem(
                    value: scheme,
                    child: Text(scheme.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedColorScheme = value!);
                },
              ),
              TextFormField(
                controller: _paymentTermsController,
                decoration: const InputDecoration(labelText: 'Payment Terms'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _footerController,
                decoration: const InputDecoration(labelText: 'Footer'),
                maxLines: 2,
              ),
              const Divider(),
              const Text('Display Options', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Show Logo'),
                value: _showLogo,
                onChanged: (value) => setState(() => _showLogo = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Company Info'),
                value: _showCompanyInfo,
                onChanged: (value) => setState(() => _showCompanyInfo = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Bank Details'),
                value: _showBankDetails,
                onChanged: (value) => setState(() => _showBankDetails = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Tax ID'),
                value: _showTaxId,
                onChanged: (value) => setState(() => _showTaxId = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Show Payment Terms'),
                value: _showPaymentTerms,
                onChanged: (value) => setState(() => _showPaymentTerms = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Set as Default'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
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
        ElevatedButton(
          onPressed: _updateTemplate,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.template.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      companyName: _companyNameController.text,
      companyAddress: _companyAddressController.text,
      companyPhone: _companyPhoneController.text,
      companyEmail: _companyEmailController.text,
      companyWebsite: _companyWebsiteController.text,
      taxId: _taxIdController.text,
      bankName: _bankNameController.text,
      bankAccountNumber: _bankAccountController.text,
      bankRoutingNumber: _bankRoutingController.text,
      layout: _selectedLayout,
      colorScheme: _selectedColorScheme,
      showLogo: _showLogo,
      showCompanyInfo: _showCompanyInfo,
      showBankDetails: _showBankDetails,
      showTaxId: _showTaxId,
      showPaymentTerms: _showPaymentTerms,
      paymentTerms: _paymentTermsController.text,
      notes: _notesController.text,
      footer: _footerController.text,
      isDefault: _isDefault,
      updatedBy: 'admin',
    );

    ref.read(templateRepositoryProvider).updateTemplate(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template updated')),
    );
  }
}