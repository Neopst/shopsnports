import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice.dart';
import '../providers/invoice_providers.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final Invoice invoice;

  const PaymentDialog({super.key, required this.invoice});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentMethodController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _paymentNotesController = TextEditingController();
  DateTime? _paymentDate;
  double _amountPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _amountPaid = widget.invoice.total;
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _paymentMethodController.dispose();
    _paymentReferenceController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice: ${widget.invoice.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${widget.invoice.customerName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Due: ₦${widget.invoice.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amount paid
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '₦',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: _amountPaid.toStringAsFixed(2),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > widget.invoice.total) {
                    return 'Amount cannot exceed total due';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amountPaid = double.tryParse(value ?? '0') ?? 0;
                },
              ),
              const SizedBox(height: 12),
              // Payment method
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'Check', child: Text('Check')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select payment method';
                  }
                  return null;
                },
                onChanged: (value) {
                  _paymentMethodController.text = value ?? '';
                },
              ),
              const SizedBox(height: 12),
              // Payment reference
              TextFormField(
                controller: _paymentReferenceController,
                decoration: const InputDecoration(
                  labelText: 'Payment Reference (Optional)',
                  hintText: 'Transaction ID, Receipt #, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Payment date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _paymentDate != null
                        ? '${_paymentDate!.day}/${_paymentDate!.month}/${_paymentDate!.year}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Payment notes
              TextFormField(
                controller: _paymentNotesController,
                decoration: const InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
          onPressed: () => _submitPayment(),
          child: const Text('Record Payment'),
        ),
      ],
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final repository = ref.read(invoiceRepositoryProvider);
      await repository.recordPayment(
        widget.invoice.id,
        paymentMethod: _paymentMethodController.text,
        paymentReference: _paymentReferenceController.text.isEmpty
            ? null
            : _paymentReferenceController.text,
        paymentDate: _paymentDate,
        amountPaid: _amountPaid,
        paymentNotes: _paymentNotesController.text.isEmpty
            ? null
            : _paymentNotesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(invoiceByIdProvider(widget.invoice.id));
        ref.invalidate(invoicesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₦${_amountPaid.toStringAsFixed(2)} recorded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}