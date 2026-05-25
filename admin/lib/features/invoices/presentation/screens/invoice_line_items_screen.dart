import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_line_item.dart';
import '../../data/repositories/invoice_line_item_repository.dart';

final lineItemRepositoryProvider = Provider<InvoiceLineItemRepository>((ref) {
  return InvoiceLineItemRepository(FirebaseFirestore.instance);
});

final lineItemsProvider = StreamProvider<List<InvoiceLineItem>>((ref) {
  return ref.watch(lineItemRepositoryProvider).getAllLineItems();
});

class InvoiceLineItemsScreen extends ConsumerStatefulWidget {
  const InvoiceLineItemsScreen({super.key});

  @override
  ConsumerState<InvoiceLineItemsScreen> createState() => _InvoiceLineItemsScreenState();
}

class _InvoiceLineItemsScreenState extends ConsumerState<InvoiceLineItemsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final lineItemsAsync = ref.watch(lineItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Items'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _bulkDelete(context),
              tooltip: 'Delete Selected',
            ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateLineItemDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: lineItemsAsync.when(
              data: (lineItems) {
                final filteredItems = _filterItems(lineItems);
                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No line items found'));
                }
                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildLineItemCard(filteredItems[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<String>>(
            future: ref.read(lineItemRepositoryProvider).getCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final categories = ['All', ...snapshot.data!];
              return DropdownButton<String>(
                value: _selectedCategory ?? 'All',
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value == 'All' ? null : value;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search line items...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  List<InvoiceLineItem> _filterItems(List<InvoiceLineItem> lineItems) {
    var filtered = lineItems;

    if (_selectedCategory != null) {
      filtered = filtered.where((item) {
        final category = item.toJson()['category'] as String?;
        return category == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildLineItemCard(InvoiceLineItem lineItem) {
    final isSelected = _selectedItems.contains(lineItem.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedItems.add(lineItem.id);
              } else {
                _selectedItems.remove(lineItem.id);
              }
            });
          },
        ),
        title: Text(lineItem.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${lineItem.quantity}'),
            Text('Unit Price: \$${lineItem.unitPrice.toStringAsFixed(2)}'),
            Text('Total: \$${lineItem.total.toStringAsFixed(2)}',
                 style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _duplicateLineItem(lineItem),
              tooltip: 'Duplicate',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editLineItem(lineItem),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteLineItem(lineItem),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateLineItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateLineItemDialog(),
    );
  }

  void _editLineItem(InvoiceLineItem lineItem) {
    showDialog(
      context: context,
      builder: (context) => EditLineItemDialog(lineItem: lineItem),
    );
  }

  void _deleteLineItem(InvoiceLineItem lineItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Line Item'),
        content: Text('Are you sure you want to delete ${lineItem.description}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(lineItemRepositoryProvider).deleteLineItem(lineItem.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Line item deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateLineItem(InvoiceLineItem lineItem) async {
    try {
      await ref.read(lineItemRepositoryProvider).duplicateLineItem(lineItem.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Line item duplicated')),
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

  void _bulkDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text('Are you sure you want to delete ${_selectedItems.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(lineItemRepositoryProvider).bulkDeleteLineItems(_selectedItems.toList());
              setState(() => _selectedItems.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Items deleted')),
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
    final stats = await ref.read(lineItemRepositoryProvider).getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Line Item Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Items', stats['totalItems'].toString()),
            _buildStatRow('Total Value', '\$${(stats['totalValue'] as double).toStringAsFixed(2)}'),
            _buildStatRow('Average Price', '\$${(stats['averagePrice'] as double).toStringAsFixed(2)}'),
            const Divider(),
            const Text('Category Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(stats['categoryCounts'] as Map<String, int>).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${entry.key}: ${entry.value}'),
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

class CreateLineItemDialog extends ConsumerStatefulWidget {
  const CreateLineItemDialog({super.key});

  @override
  ConsumerState<CreateLineItemDialog> createState() => _CreateLineItemDialogState();
}

class _CreateLineItemDialogState extends ConsumerState<CreateLineItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'General';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Line Item'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value ?? '') == null ? 'Invalid number' : null,
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => double.tryParse(value ?? '') == null ? 'Invalid price' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              FutureBuilder<List<String>>(
                future: ref.read(lineItemRepositoryProvider).getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final categories = ['General', ...snapshot.data!];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  );
                },
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
          onPressed: _createLineItem,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createLineItem() {
    if (!_formKey.currentState!.validate()) return;

    final lineItem = InvoiceLineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
    );

    final data = lineItem.toJson();
    data['category'] = _selectedCategory;

    ref.read(lineItemRepositoryProvider).createLineItem(
      InvoiceLineItem(
        id: lineItem.id,
        description: lineItem.description,
        quantity: lineItem.quantity,
        unitPrice: lineItem.unitPrice,
        imageUrl: lineItem.imageUrl,
      ),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Line item created')),
    );
  }
}

class EditLineItemDialog extends ConsumerStatefulWidget {
  final InvoiceLineItem lineItem;

  const EditLineItemDialog({super.key, required this.lineItem});

  @override
  ConsumerState<EditLineItemDialog> createState() => _EditLineItemDialogState();
}

class _EditLineItemDialogState extends ConsumerState<EditLineItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _imageUrlController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.lineItem.description);
    _quantityController = TextEditingController(text: widget.lineItem.quantity.toString());
    _unitPriceController = TextEditingController(text: widget.lineItem.unitPrice.toString());
    _imageUrlController = TextEditingController(text: widget.lineItem.imageUrl ?? '');
    _selectedCategory = 'General';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Line Item'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value ?? '') == null ? 'Invalid number' : null,
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => double.tryParse(value ?? '') == null ? 'Invalid price' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              FutureBuilder<List<String>>(
                future: ref.read(lineItemRepositoryProvider).getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final categories = ['General', ...snapshot.data!];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  );
                },
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
          onPressed: _updateLineItem,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateLineItem() {
    if (!_formKey.currentState!.validate()) return;

    final updated = InvoiceLineItem(
      id: widget.lineItem.id,
      description: _descriptionController.text,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
    );

    final data = updated.toJson();
    data['category'] = _selectedCategory;

    ref.read(lineItemRepositoryProvider).updateLineItem(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Line item updated')),
    );
  }
}