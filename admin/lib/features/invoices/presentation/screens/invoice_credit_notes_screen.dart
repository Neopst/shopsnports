import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/invoice_credit_note.dart';
import '../../data/repositories/invoice_credit_note_repository.dart';

final creditNoteRepositoryProvider = Provider<InvoiceCreditNoteRepository>((ref) {
  return InvoiceCreditNoteRepository();
});

final creditNotesProvider = FutureProvider<List<InvoiceCreditNote>>((ref) async {
  final repository = ref.watch(creditNoteRepositoryProvider);
  return repository.getAllCreditNotes();
});

final creditNotesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(creditNoteRepositoryProvider);
  return repository.getCreditNotesStatistics();
});

class InvoiceCreditNotesScreen extends ConsumerStatefulWidget {
  const InvoiceCreditNotesScreen({super.key});

  @override
  ConsumerState<InvoiceCreditNotesScreen> createState() => _InvoiceCreditNotesScreenState();
}

class _InvoiceCreditNotesScreenState extends ConsumerState<InvoiceCreditNotesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  CreditNoteStatus? _filterStatus;
  CreditNoteReason? _filterReason;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InvoiceCreditNote> _filterCreditNotes(List<InvoiceCreditNote> creditNotes) {
    var filtered = creditNotes;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((cn) =>
              cn.creditNoteNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (cn.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((cn) => cn.status == _filterStatus).toList();
    }

    if (_filterReason != null) {
      filtered = filtered.where((cn) => cn.reason == _filterReason).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final creditNotesAsync = ref.watch(creditNotesProvider);
    final statsAsync = ref.watch(creditNotesStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Credit Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(creditNotesProvider);
              ref.invalidate(creditNotesStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(statsAsync),
          _buildSearchAndFilter(),
          Expanded(
            child: creditNotesAsync.when(
              data: (creditNotes) {
                final filtered = _filterCreditNotes(creditNotes);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No credit notes found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildCreditNoteCard(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCreditNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsHeader(AsyncValue<Map<String, dynamic>> snapshot) {
    if (!snapshot.hasValue) {
      return const SizedBox.shrink();
    }

    final stats = snapshot.value!;
    final totalAmount = stats['totalAmount'] as double;
    final appliedAmount = stats['appliedAmount'] as double;
    final pendingAmount = stats['pendingAmount'] as double;
    final totalNotes = stats['totalCreditNotes'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Notes', totalNotes.toString(), Colors.blue),
          _buildStatItem('Total Amount', '\$${totalAmount.toStringAsFixed(2)}', Colors.green),
          _buildStatItem('Applied', '\$${appliedAmount.toStringAsFixed(2)}', Colors.orange),
          _buildStatItem('Pending', '\$${pendingAmount.toStringAsFixed(2)}', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search credit notes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CreditNoteStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterStatus,
                  items: CreditNoteStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<CreditNoteReason>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Reason',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterReason,
                  items: CreditNoteReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterReason = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditNoteCard(InvoiceCreditNote creditNote) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creditNote.creditNoteNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Invoice: ${creditNote.invoiceId}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '\$${creditNote.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            _buildStatusChip(creditNote),
            const SizedBox(width: 8),
            Chip(
              label: Text(creditNote.reason.value),
              backgroundColor: Colors.blue.shade100,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (creditNote.canBeApplied)
              IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: () => _showApplyDialog(creditNote),
                tooltip: 'Apply',
              ),
            if (creditNote.canBeVoided)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _showVoidDialog(creditNote),
                tooltip: 'Void',
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCreditNoteDialog(creditNote),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(creditNote),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (creditNote.description != null) ...[
                  Text('Description: ${creditNote.description}'),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Text('Issue Date: '),
                    Text(creditNote.issueDate.toString().split(' ')[0]),
                  ],
                ),
                if (creditNote.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Due Date: '),
                      Text(creditNote.dueDate.toString().split(' ')[0]),
                    ],
                  ),
                ],
                if (creditNote.appliedDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Applied Date: '),
                      Text(creditNote.appliedDate.toString().split(' ')[0]),
                    ],
                  ),
                ],
                if (creditNote.lineItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Line Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...creditNote.lineItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.productName ?? item.description ?? 'Item')),
                        Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                        Text('=\$${item.totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(InvoiceCreditNote creditNote) {
    Color color;
    String label;

    switch (creditNote.status) {
      case CreditNoteStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case CreditNoteStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case CreditNoteStatus.approved:
        color = Colors.green;
        label = 'Approved';
        break;
      case CreditNoteStatus.applied:
        color = Colors.blue;
        label = 'Applied';
        break;
      case CreditNoteStatus.voided:
        color = Colors.red;
        label = 'Voided';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color,
    );
  }

  void _showCreateCreditNoteDialog() {
    _showCreditNoteDialog();
  }

  void _showEditCreditNoteDialog(InvoiceCreditNote creditNote) {
    _showCreditNoteDialog(creditNote: creditNote);
  }

  void _showCreditNoteDialog({InvoiceCreditNote? creditNote}) {
    final isEditing = creditNote != null;
    final formKey = GlobalKey<FormState>();
    final invoiceIdController = TextEditingController(text: creditNote?.invoiceId ?? '');
    final customerIdController = TextEditingController(text: creditNote?.customerId ?? '');
    final orderIdController = TextEditingController(text: creditNote?.orderId ?? '');
    final totalAmountController = TextEditingController(text: creditNote?.totalAmount.toString() ?? '');
    final currencyController = TextEditingController(text: creditNote?.currency ?? 'USD');
    final descriptionController = TextEditingController(text: creditNote?.description ?? '');

    CreditNoteReason reason = creditNote?.reason ?? CreditNoteReason.refund;
    CreditNoteStatus status = creditNote?.status ?? CreditNoteStatus.draft;
    DateTime? issueDate = creditNote?.issueDate;
    DateTime? dueDate = creditNote?.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Credit Note' : 'Create Credit Note'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: invoiceIdController,
                    decoration: const InputDecoration(labelText: 'Invoice ID'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: customerIdController,
                    decoration: const InputDecoration(labelText: 'Customer ID'),
                  ),
                  TextFormField(
                    controller: orderIdController,
                    decoration: const InputDecoration(labelText: 'Order ID'),
                  ),
                  TextFormField(
                    controller: totalAmountController,
                    decoration: const InputDecoration(labelText: 'Total Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                  DropdownButtonFormField<CreditNoteReason>(
                    value: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: CreditNoteReason.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.value));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => reason = value!);
                    },
                  ),
                  DropdownButtonFormField<CreditNoteStatus>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: CreditNoteStatus.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.value));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => status = value!);
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  ListTile(
                    title: const Text('Issue Date'),
                    subtitle: Text(issueDate?.toString() ?? 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: issueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() => issueDate = date);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Due Date'),
                    subtitle: Text(dueDate?.toString() ?? 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() => dueDate = date);
                        }
                      },
                    ),
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final repository = ref.read(creditNoteRepositoryProvider);
                  final nextNumber = isEditing
                      ? creditNote!.creditNoteNumber
                      : await repository.getNextCreditNoteNumber();

                  final newCreditNote = InvoiceCreditNote(
                    id: creditNote?.id ?? '',
                    invoiceId: invoiceIdController.text,
                    creditNoteNumber: nextNumber,
                    customerId: customerIdController.text.isNotEmpty
                        ? customerIdController.text
                        : null,
                    orderId: orderIdController.text.isNotEmpty ? orderIdController.text : null,
                    totalAmount: double.parse(totalAmountController.text),
                    currency: currencyController.text,
                    reason: reason,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    status: status,
                    lineItems: creditNote?.lineItems ?? [],
                    issueDate: issueDate ?? DateTime.now(),
                    dueDate: dueDate,
                    appliedDate: creditNote?.appliedDate,
                    appliedToInvoiceId: creditNote?.appliedToInvoiceId,
                    createdBy: creditNote?.createdBy,
                    approvedBy: creditNote?.approvedBy,
                    approvedAt: creditNote?.approvedAt,
                    createdAt: creditNote?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                    metadata: creditNote?.metadata,
                  );

                  if (isEditing) {
                    await repository.updateCreditNote(newCreditNote);
                  } else {
                    await repository.createCreditNote(newCreditNote);
                  }

                  ref.invalidate(creditNotesProvider);
                  ref.invalidate(creditNotesStatsProvider);
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyDialog(InvoiceCreditNote creditNote) {
    final invoiceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Credit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Credit Note: ${creditNote.creditNoteNumber}'),
            Text('Amount: \$${creditNote.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: invoiceIdController,
              decoration: const InputDecoration(
                labelText: 'Apply to Invoice ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (invoiceIdController.text.isNotEmpty) {
                final repository = ref.read(creditNoteRepositoryProvider);
                await repository.applyCreditNote(creditNote.id, invoiceIdController.text);
                ref.invalidate(creditNotesProvider);
                ref.invalidate(creditNotesStatsProvider);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showVoidDialog(InvoiceCreditNote creditNote) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Credit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Credit Note: ${creditNote.creditNoteNumber}'),
            Text('Amount: \$${creditNote.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(creditNoteRepositoryProvider);
              await repository.voidCreditNote(
                creditNote.id,
                reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              ref.invalidate(creditNotesProvider);
              ref.invalidate(creditNotesStatsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Void'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(InvoiceCreditNote creditNote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credit Note'),
        content: Text('Are you sure you want to delete "${creditNote.creditNoteNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(creditNoteRepositoryProvider);
              await repository.deleteCreditNote(creditNote.id);
              ref.invalidate(creditNotesProvider);
              ref.invalidate(creditNotesStatsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}