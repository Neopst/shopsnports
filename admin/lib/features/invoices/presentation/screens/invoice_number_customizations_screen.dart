import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_number_customization.dart';
import '../../data/repositories/invoice_number_customization_repository.dart';

final numberCustomizationRepositoryProvider =
    Provider<InvoiceNumberCustomizationRepository>((ref) {
  return InvoiceNumberCustomizationRepository(FirebaseFirestore.instance);
});

final numberCustomizationsProvider =
    StreamProvider<List<InvoiceNumberCustomization>>((ref) {
  return ref.watch(numberCustomizationRepositoryProvider)
      .getAllCustomizations();
});

final activeNumberCustomizationsProvider =
    StreamProvider<List<InvoiceNumberCustomization>>((ref) {
  return ref.watch(numberCustomizationRepositoryProvider)
      .getActiveCustomizations();
});

final numberCustomizationStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(numberCustomizationRepositoryProvider);
  return repository.getCustomizationStatistics();
});

class InvoiceNumberCustomizationsScreen extends ConsumerStatefulWidget {
  const InvoiceNumberCustomizationsScreen({super.key});

  @override
  ConsumerState<InvoiceNumberCustomizationsScreen> createState() =>
      _InvoiceNumberCustomizationsScreenState();
}

class _InvoiceNumberCustomizationsScreenState
    extends ConsumerState<InvoiceNumberCustomizationsScreen> {
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customizationsAsync = _showActiveOnly
        ? ref.watch(activeNumberCustomizationsProvider)
        : ref.watch(numberCustomizationsProvider);
    final statsAsync = ref.watch(numberCustomizationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Number Customizations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCustomizationDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: customizationsAsync.when(
              data: (customizations) {
                final filteredCustomizations =
                    _filterCustomizations(customizations);
                if (filteredCustomizations.isEmpty) {
                  return const Center(child: Text('No customizations found'));
                }
                return ListView.builder(
                  itemCount: filteredCustomizations.length,
                  itemBuilder: (context, index) {
                    return _buildCustomizationCard(
                        filteredCustomizations[index]);
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
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SwitchListTile(
        title: const Text('Active Only'),
        value: _showActiveOnly,
        onChanged: (value) {
          setState(() {
            _showActiveOnly = value;
          });
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search customizations',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  List<InvoiceNumberCustomization> _filterCustomizations(
      List<InvoiceNumberCustomization> customizations) {
    if (_searchQuery.isEmpty) return customizations;

    return customizations
        .where((customization) =>
            customization.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            customization.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildCustomizationCard(
      InvoiceNumberCustomization customization) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(customization.currentNumber.toString()),
        ),
        title: Text(customization.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customization.description),
            const SizedBox(height: 4),
            Text('Format: ${customization.format.name}'),
            const SizedBox(height: 4),
            Text('Next: ${customization.generateNextNumber()}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                customization.isActive ? Icons.visibility : Icons.visibility_off,
                color: customization.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(customization),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _resetNumber(customization),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  _showEditCustomizationDialog(context, customization),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCustomization(customization),
            ),
          ],
        ),
        onTap: () => _showCustomizationDetails(context, customization),
      ),
    );
  }

  void _showCreateCustomizationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final prefixController = TextEditingController();
    final suffixController = TextEditingController();
    final startNumberController = TextEditingController(text: '1');
    final paddingLengthController = TextEditingController();
    final paddingCharacterController = TextEditingController();
    NumberFormat format = NumberFormat.numeric;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Number Customization'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: prefixController,
                  decoration: const InputDecoration(labelText: 'Prefix'),
                ),
                TextField(
                  controller: suffixController,
                  decoration: const InputDecoration(labelText: 'Suffix'),
                ),
                TextField(
                  controller: startNumberController,
                  decoration: const InputDecoration(labelText: 'Start Number'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<NumberFormat>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: NumberFormat.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      format = value!;
                    });
                  },
                ),
                TextField(
                  controller: paddingLengthController,
                  decoration:
                      const InputDecoration(labelText: 'Padding Length (optional)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: paddingCharacterController,
                  decoration: const InputDecoration(
                      labelText: 'Padding Character (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                final repository = ref.read(numberCustomizationRepositoryProvider);
                final customization = InvoiceNumberCustomization(
                  id: '',
                  name: nameController.text,
                  description: descriptionController.text,
                  prefix: prefixController.text,
                  suffix: suffixController.text,
                  startNumber:
                      int.tryParse(startNumberController.text) ?? 1,
                  currentNumber:
                      int.tryParse(startNumberController.text) ?? 1,
                  format: format,
                  paddingLength: paddingLengthController.text.isNotEmpty
                      ? int.tryParse(paddingLengthController.text)
                      : null,
                  paddingCharacter: paddingCharacterController.text.isNotEmpty
                      ? paddingCharacterController.text
                      : null,
                  createdAt: DateTime.now(),
                );

                await repository.createCustomization(customization);
                Navigator.pop(context);
                ref.invalidate(numberCustomizationsProvider);
                ref.invalidate(activeNumberCustomizationsProvider);
                ref.invalidate(numberCustomizationStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomizationDialog(
      BuildContext context, InvoiceNumberCustomization customization) {
    final nameController = TextEditingController(text: customization.name);
    final descriptionController =
        TextEditingController(text: customization.description);
    final prefixController = TextEditingController(text: customization.prefix);
    final suffixController = TextEditingController(text: customization.suffix);
    final startNumberController =
        TextEditingController(text: customization.startNumber.toString());
    final paddingLengthController =
        TextEditingController(text: customization.paddingLength?.toString() ?? '');
    final paddingCharacterController =
        TextEditingController(text: customization.paddingCharacter ?? '');
    NumberFormat format = customization.format;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Number Customization'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: prefixController,
                  decoration: const InputDecoration(labelText: 'Prefix'),
                ),
                TextField(
                  controller: suffixController,
                  decoration: const InputDecoration(labelText: 'Suffix'),
                ),
                TextField(
                  controller: startNumberController,
                  decoration: const InputDecoration(labelText: 'Start Number'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<NumberFormat>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: NumberFormat.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      format = value!;
                    });
                  },
                ),
                TextField(
                  controller: paddingLengthController,
                  decoration:
                      const InputDecoration(labelText: 'Padding Length (optional)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: paddingCharacterController,
                  decoration: const InputDecoration(
                      labelText: 'Padding Character (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repository = ref.read(numberCustomizationRepositoryProvider);
                final updatedCustomization = customization.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  prefix: prefixController.text,
                  suffix: suffixController.text,
                  startNumber:
                      int.tryParse(startNumberController.text) ?? customization.startNumber,
                  format: format,
                  paddingLength: paddingLengthController.text.isNotEmpty
                      ? int.tryParse(paddingLengthController.text)
                      : null,
                  paddingCharacter: paddingCharacterController.text.isNotEmpty
                      ? paddingCharacterController.text
                      : null,
                  updatedAt: DateTime.now(),
                );

                await repository.updateCustomization(updatedCustomization);
                Navigator.pop(context);
                ref.invalidate(numberCustomizationsProvider);
                ref.invalidate(activeNumberCustomizationsProvider);
                ref.invalidate(numberCustomizationStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizationDetails(
      BuildContext context, InvoiceNumberCustomization customization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customization.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${customization.description}'),
              const SizedBox(height: 8),
              Text('Prefix: ${customization.prefix}'),
              const SizedBox(height: 8),
              Text('Suffix: ${customization.suffix}'),
              const SizedBox(height: 8),
              Text('Start Number: ${customization.startNumber}'),
              const SizedBox(height: 8),
              Text('Current Number: ${customization.currentNumber}'),
              const SizedBox(height: 8),
              Text('Format: ${customization.format.name}'),
              const SizedBox(height: 8),
              Text('Padding Length: ${customization.paddingLength ?? "None"}'),
              const SizedBox(height: 8),
              Text('Padding Character: ${customization.paddingCharacter ?? "None"}'),
              const SizedBox(height: 8),
              Text('Next Number: ${customization.generateNextNumber()}'),
              const SizedBox(height: 8),
              Text('Active: ${customization.isActive ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Created: ${customization.createdAt.toLocal()}'),
              if (customization.updatedAt != null) ...[
                const SizedBox(height: 8),
                Text('Updated: ${customization.updatedAt!.toLocal()}'),
              ],
            ],
          ),
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

  void _toggleActiveStatus(InvoiceNumberCustomization customization) async {
    final repository = ref.read(numberCustomizationRepositoryProvider);
    await repository.toggleActiveStatus(
        customization.id, !customization.isActive);
    ref.invalidate(numberCustomizationsProvider);
    ref.invalidate(activeNumberCustomizationsProvider);
    ref.invalidate(numberCustomizationStatsProvider);
  }

  void _resetNumber(InvoiceNumberCustomization customization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Number'),
        content: Text(
            'Are you sure you want to reset the number to ${customization.startNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(numberCustomizationRepositoryProvider);
      await repository.resetNumber(customization.id);
      ref.invalidate(numberCustomizationsProvider);
      ref.invalidate(activeNumberCustomizationsProvider);
      ref.invalidate(numberCustomizationStatsProvider);
    }
  }

  void _deleteCustomization(InvoiceNumberCustomization customization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customization'),
        content: Text(
            'Are you sure you want to delete "${customization.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(numberCustomizationRepositoryProvider);
      await repository.deleteCustomization(customization.id);
      ref.invalidate(numberCustomizationsProvider);
      ref.invalidate(activeNumberCustomizationsProvider);
      ref.invalidate(numberCustomizationStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(numberCustomizationStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number Customization Statistics'),
        content: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Customizations: ${stats['totalCustomizations']}'),
                const SizedBox(height: 8),
                Text('Active Customizations: ${stats['activeCustomizations']}'),
                const SizedBox(height: 8),
                Text('Inactive Customizations: ${stats['inactiveCustomizations']}'),
                const SizedBox(height: 16),
                const Text('Customizations by Format:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(stats['formatCounts'] as Map<String, int>).entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  );
                }),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
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
}