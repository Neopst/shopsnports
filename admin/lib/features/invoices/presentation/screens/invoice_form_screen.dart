import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_line_item.dart';
import '../providers/invoice_providers.dart';
import 'invoice_preview_screen.dart';
import '../../../../core/services/email_service.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String? invoiceId; // null for create, non-null for edit

  const InvoiceFormScreen({super.key, this.invoiceId});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Form fields
  late TextEditingController _customerNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _notesController;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;
  InvoiceStatus _status = InvoiceStatus.draft;
  bool _sendEmail = false; // Toggle for sending email on create

  List<_LineItemData> _lineItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _customerEmailController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.invoiceId == null) {
      // Create new - add one empty line item
      _lineItems.add(_LineItemData());
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoiceId != null) {
      return _buildEditForm();
    }
    return _buildCreateForm();
  }

  Widget _buildEditForm() {
    final invoiceAsync = ref.watch(invoiceByIdProvider(widget.invoiceId!));

    return invoiceAsync.when(
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Not Found')),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        // Load invoice data into form (only once)
        if (_lineItems.isEmpty) {
          _loadInvoiceData(invoice);
        }

        return _buildForm('Edit Invoice');
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCreateForm() {
    return _buildForm('Create Invoice');
  }

  void _loadInvoiceData(Invoice invoice) {
    _customerNameController.text = invoice.customerName;
    _customerEmailController.text = invoice.customerEmail;
    _notesController.text = invoice.notes ?? '';
    _invoiceDate = invoice.invoiceDate;
    _dueDate = invoice.dueDate;
    _taxRate = invoice.taxRate;
    _status = invoice.status;

    _lineItems = invoice.lineItems.map((item) {
      return _LineItemData(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        imageUrl: item.imageUrl,
      );
    }).toList();
  }

  Widget _buildForm(String title) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerSection(),
                    const SizedBox(height: 24),
                    _buildDatesSection(),
                    const SizedBox(height: 24),
                    _buildLineItemsSection(),
                    const SizedBox(height: 24),
                    _buildTaxAndStatusSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildTotalsSection(),
                    const SizedBox(height: 24),
                    _buildActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Customer Email *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_invoiceDate.month}/${_invoiceDate.day}/${_invoiceDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Line Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _lineItems.add(_LineItemData())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lineItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No items added'),
                ),
              )
            else
              ..._lineItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildLineItemRow(index, item),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemRow(int index, _LineItemData item) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Qty *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.unitPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _lineItems.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxAndStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _taxRate.toString(),
                decoration: const InputDecoration(
                  labelText: 'Tax Rate (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _taxRate = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<InvoiceStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: InvoiceStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    final subtotal = _lineItems.fold(0.0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * (_taxRate / 100);
    final total = subtotal + taxAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  _buildTotalRow(
                    'Subtotal',
                    '\$${subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'Tax ($_taxRate%)',
                    '\$${taxAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _buildTotalRow(
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Email checkbox (only show for new invoices)
        if (widget.invoiceId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(
                  value: _sendEmail,
                  onChanged: (value) =>
                      setState(() => _sendEmail = value ?? false),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Send invoice email to customer',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Email will be sent from invoices@shopsnports.com',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _saveInvoice(InvoiceStatus.draft),
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.grey[700],
              ),
              label: const Text('Save as Draft'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showPreview,
              icon: const Icon(Icons.visibility),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              label: const Text('Preview'),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = date;
        } else {
          _dueDate = date;
        }
      });
    }
  }

  Future<void> _saveInvoice(InvoiceStatus status) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(invoiceRepositoryProvider);

      final lineItems = _lineItems.map((item) {
        return InvoiceLineItem(
          id: _uuid.v4(),
          description: item.descriptionController.text,
          quantity: int.parse(item.quantityController.text),
          unitPrice: double.parse(item.unitPriceController.text),
          imageUrl: item.imageUrl,
        );
      }).toList();

      // Generate access token for new invoices
      final accessToken = widget.invoiceId != null
          ? (await ref.read(
              invoiceByIdProvider(widget.invoiceId!).future,
            ))!.accessToken
          : EmailService.generateAccessToken();

      final invoice = Invoice(
        id: widget.invoiceId ?? _uuid.v4(),
        invoiceNumber: widget.invoiceId != null
            ? (await ref.read(
                invoiceByIdProvider(widget.invoiceId!).future,
              ))!.invoiceNumber
            : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        customerId: _uuid.v4(),
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        customerAvatar: 'assets/icons/face1.png',
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        lineItems: lineItems,
        taxRate: _taxRate,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        accessToken: accessToken,
      );

      if (widget.invoiceId != null) {
        await repository.updateInvoice(invoice);
      } else {
        await repository.createInvoice(invoice);
      }

      // Send email if requested and not a draft
      if (_sendEmail &&
          status != InvoiceStatus.draft &&
          widget.invoiceId == null) {
        try {
          final emailService = EmailService();
          await emailService.sendInvoiceEmail(
            invoiceId: invoice.id,
            customerEmail: invoice.customerEmail,
            customerName: invoice.customerName,
            invoiceNumber: invoice.invoiceNumber,
            accessToken: invoice.accessToken,
            amount: invoice.total,
            dueDate: invoice.dueDate,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invoice created but email failed: $e')),
            );
          }
        }
      }

      ref.invalidate(invoicesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == InvoiceStatus.draft
                  ? 'Invoice saved as draft'
                  : widget.invoiceId != null
                  ? 'Invoice updated and sent'
                  : 'Invoice created and sent',
            ),
          ),
        );
        context.go('/dashboard/invoices');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPreview() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    final lineItems = _lineItems.map((item) {
      return InvoiceLineItem(
        id: _uuid.v4(),
        description: item.descriptionController.text,
        quantity: int.parse(item.quantityController.text),
        unitPrice: double.parse(item.unitPriceController.text),
        imageUrl: item.imageUrl,
      );
    }).toList();

    final invoice = Invoice(
      id: widget.invoiceId ?? _uuid.v4(),
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      customerId: _uuid.v4(),
      customerName: _customerNameController.text,
      customerEmail: _customerEmailController.text,
      customerAvatar: 'assets/icons/face1.png',
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      lineItems: lineItems,
      taxRate: _taxRate,
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      accessToken: EmailService.generateAccessToken(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(
          invoice: invoice,
          onSend: () {
            Navigator.pop(context);
            _saveInvoice(InvoiceStatus.pending);
          },
          onSaveDraft: () {
            Navigator.pop(context);
            _saveInvoice(InvoiceStatus.draft);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class _LineItemData {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final String? imageUrl;

  _LineItemData({
    String? description,
    int? quantity,
    double? unitPrice,
    this.imageUrl,
  }) : descriptionController = TextEditingController(text: description),
       quantityController = TextEditingController(
         text: quantity?.toString() ?? '1',
       ),
       unitPriceController = TextEditingController(
         text: unitPrice?.toString() ?? '0.00',
       );

  double get total {
    final qty = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0.0;
    return qty * price;
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
