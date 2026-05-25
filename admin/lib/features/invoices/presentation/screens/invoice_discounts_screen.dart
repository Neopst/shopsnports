import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_discount.dart';
import '../../data/repositories/invoice_discount_repository.dart';

final discountRepositoryProvider = Provider<InvoiceDiscountRepository>((ref) {
  return InvoiceDiscountRepository(FirebaseFirestore.instance);
});

final discountsProvider = StreamProvider<List<InvoiceDiscount>>((ref) {
  final repository = ref.watch(discountRepositoryProvider);
  return repository.getAllDiscounts();
});

class InvoiceDiscountsScreen extends ConsumerStatefulWidget {
  const InvoiceDiscountsScreen({super.key});

  @override
  ConsumerState<InvoiceDiscountsScreen> createState() => _InvoiceDiscountsScreenState();
}

class _InvoiceDiscountsScreenState extends ConsumerState<InvoiceDiscountsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DiscountType? _filterType;
  bool? _filterActive;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InvoiceDiscount> _filterDiscounts(List<InvoiceDiscount> discounts) {
    var filtered = discounts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((d) =>
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((d) => d.type == _filterType).toList();
    }

    if (_filterActive != null) {
      filtered = filtered.where((d) => d.isActive == _filterActive).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final discountsAsync = ref.watch(discountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Discounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(discountsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: discountsAsync.when(
              data: (discounts) {
                final filtered = _filterDiscounts(discounts);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No discounts found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildDiscountCard(filtered[index]);
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
        onPressed: () => _showCreateDiscountDialog(),
        child: const Icon(Icons.add),
      ),
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
              hintText: 'Search discounts...',
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
                child: DropdownButtonFormField<DiscountType>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterType,
                  items: DiscountType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterActive,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterActive = value;
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

  Widget _buildDiscountCard(InvoiceDiscount discount) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(discount.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(discount),
                const SizedBox(width: 8),
                Chip(
                  label: Text(discount.type.value),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 8),
                Text(
                  discount.isPercentage
                      ? '${discount.value}%'
                      : '${discount.value} ${discount.currency ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (discount.usageLimit != null) ...[
              const SizedBox(height: 4),
              Text('Usage: ${discount.usageCount}/${discount.usageLimit}'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDiscountDialog(discount),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(discount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceDiscount discount) {
    if (!discount.isActive) {
      return const Chip(
        label: Text('Inactive'),
        backgroundColor: Colors.grey,
      );
    }
    if (discount.isExpired) {
      return const Chip(
        label: Text('Expired'),
        backgroundColor: Colors.red,
      );
    }
    if (discount.isNotStarted) {
      return const Chip(
        label: Text('Not Started'),
        backgroundColor: Colors.orange,
      );
    }
    if (discount.isUsageLimitReached) {
      return const Chip(
        label: Text('Limit Reached'),
        backgroundColor: Colors.red,
      );
    }
    return const Chip(
      label: Text('Active'),
      backgroundColor: Colors.green,
    );
  }

  void _showCreateDiscountDialog() {
    _showDiscountDialog();
  }

  void _showEditDiscountDialog(InvoiceDiscount discount) {
    _showDiscountDialog(discount: discount);
  }

  void _showDiscountDialog({InvoiceDiscount? discount}) {
    final isEditing = discount != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: discount?.name ?? '');
    final descriptionController = TextEditingController(text: discount?.description ?? '');
    final valueController = TextEditingController(text: discount?.value.toString() ?? '');
    final currencyController = TextEditingController(text: discount?.currency ?? 'USD');
    final minOrderController = TextEditingController(text: discount?.minimumOrderAmount?.toString() ?? '');
    final maxDiscountController = TextEditingController(text: discount?.maximumDiscountAmount?.toString() ?? '');
    final usageLimitController = TextEditingController(text: discount?.usageLimit?.toString() ?? '');

    DiscountType type = discount?.type ?? DiscountType.fixed;
    DiscountApplication application = discount?.application ?? DiscountApplication.subtotal;
    bool isPercentage = discount?.isPercentage ?? false;
    bool isActive = discount?.isActive ?? true;
    DateTime? validFrom = discount?.validFrom;
    DateTime? validUntil = discount?.validUntil;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Discount' : 'Create Discount'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  DropdownButtonFormField<DiscountType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: DiscountType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.value));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => type = value!);
                    },
                  ),
                  TextFormField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Value'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SwitchListTile(
                    title: const Text('Percentage'),
                    value: isPercentage,
                    onChanged: (value) {
                      setDialogState(() => isPercentage = value);
                    },
                  ),
                  if (!isPercentage)
                    TextFormField(
                      controller: currencyController,
                      decoration: const InputDecoration(labelText: 'Currency'),
                    ),
                  DropdownButtonFormField<DiscountApplication>(
                    value: application,
                    decoration: const InputDecoration(labelText: 'Application'),
                    items: DiscountApplication.values.map((a) {
                      return DropdownMenuItem(value: a, child: Text(a.value));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => application = value!);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
                    },
                  ),
                  ListTile(
                    title: const Text('Valid From'),
                    subtitle: Text(validFrom?.toString() ?? 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: validFrom ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() => validFrom = date);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Valid Until'),
                    subtitle: Text(validUntil?.toString() ?? 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: validUntil ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setDialogState(() => validUntil = date);
                        }
                      },
                    ),
                  ),
                  TextFormField(
                    controller: minOrderController,
                    decoration: const InputDecoration(labelText: 'Minimum Order Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: maxDiscountController,
                    decoration: const InputDecoration(labelText: 'Maximum Discount Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: usageLimitController,
                    decoration: const InputDecoration(labelText: 'Usage Limit'),
                    keyboardType: TextInputType.number,
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
                  final repository = ref.read(discountRepositoryProvider);
                  final newDiscount = InvoiceDiscount(
                    id: discount?.id ?? '',
                    name: nameController.text,
                    description: descriptionController.text,
                    type: type,
                    value: double.parse(valueController.text),
                    currency: !isPercentage ? currencyController.text : null,
                    application: application,
                    isPercentage: isPercentage,
                    isActive: isActive,
                    validFrom: validFrom,
                    validUntil: validUntil,
                    minimumOrderAmount: minOrderController.text.isNotEmpty
                        ? int.parse(minOrderController.text)
                        : null,
                    maximumDiscountAmount: maxDiscountController.text.isNotEmpty
                        ? int.parse(maxDiscountController.text)
                        : null,
                    usageLimit: usageLimitController.text.isNotEmpty
                        ? int.parse(usageLimitController.text)
                        : null,
                    usageCount: discount?.usageCount ?? 0,
                    createdAt: discount?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    await repository.updateDiscount(newDiscount);
                  } else {
                    await repository.createDiscount(newDiscount);
                  }

                  ref.invalidate(discountsProvider);
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

  void _showDeleteConfirmation(InvoiceDiscount discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount'),
        content: Text('Are you sure you want to delete "${discount.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(discountRepositoryProvider);
              await repository.deleteDiscount(discount.id);
              ref.invalidate(discountsProvider);
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