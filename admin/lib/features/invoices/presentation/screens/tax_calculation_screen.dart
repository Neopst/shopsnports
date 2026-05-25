import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/tax_calculation.dart';
import '../../data/repositories/tax_calculation_repository.dart';

final taxCalculationRepositoryProvider =
    Provider<TaxCalculationRepository>((ref) {
  return TaxCalculationRepository();
});

final taxCalculationsProvider =
    FutureProvider.family<List<TaxCalculation>, TaxCalculationStatus?>(
  (ref, status) async {
    final repository = ref.read(taxCalculationRepositoryProvider);
    if (status == null) {
      return repository.getAll();
    }
    return repository.getByStatus(status);
  },
);

final taxStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(taxCalculationRepositoryProvider);
  return repository.getStatistics();
});

final taxConfigurationsProvider =
    FutureProvider<List<TaxConfiguration>>((ref) async {
  final repository = ref.read(taxCalculationRepositoryProvider);
  return repository.getAllTaxConfigurations();
});

class TaxCalculationScreen extends ConsumerStatefulWidget {
  const TaxCalculationScreen({super.key});

  @override
  ConsumerState<TaxCalculationScreen> createState() =>
      _TaxCalculationScreenState();
}

class _TaxCalculationScreenState extends ConsumerState<TaxCalculationScreen> {
  TaxCalculationStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final calculationsAsync =
        ref.watch(taxCalculationsProvider(_selectedStatus));
    final statsAsync = ref.watch(taxStatsProvider);
    final configsAsync = ref.watch(taxConfigurationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Calculation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(taxCalculationsProvider(_selectedStatus));
              ref.invalidate(taxStatsProvider);
              ref.invalidate(taxConfigurationsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showTaxConfigurationsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          _buildFilterChips(),
          Expanded(
            child: calculationsAsync.when(
              data: (calculations) {
                if (calculations.isEmpty) {
                  return const Center(
                    child: Text('No tax calculations found'),
                  );
                }
                return ListView.builder(
                  itemCount: calculations.length,
                  itemBuilder: (context, index) {
                    return _buildCalculationCard(calculations[index]);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCalculateTaxDialog(),
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate Tax'),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: statsAsync.when(
        data: (stats) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tax Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('Invoices', stats['totalInvoices'].toString()),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Total Tax',
                    '\$${stats['totalTax'].toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Avg Rate',
                    '${stats['averageTaxRate'].toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip('Pending', stats['pending'] ?? 0, Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatusChip('Calculated', stats['calculated'] ?? 0, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatusChip('Verified', stats['verified'] ?? 0, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusChip('Filed', stats['filed'] ?? 0, Colors.purple),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.2),
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = selected ? null : _selectedStatus;
              });
            },
          ),
          ...TaxCalculationStatus.values.map((status) {
            return FilterChip(
              label: Text(_getStatusLabel(status)),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  String _getStatusLabel(TaxCalculationStatus status) {
    switch (status) {
      case TaxCalculationStatus.pending:
        return 'Pending';
      case TaxCalculationStatus.calculated:
        return 'Calculated';
      case TaxCalculationStatus.verified:
        return 'Verified';
      case TaxCalculationStatus.filed:
        return 'Filed';
      case TaxCalculationStatus.adjusted:
        return 'Adjusted';
    }
  }

  Color _getStatusColor(TaxCalculationStatus status) {
    switch (status) {
      case TaxCalculationStatus.pending:
        return Colors.orange;
      case TaxCalculationStatus.calculated:
        return Colors.blue;
      case TaxCalculationStatus.verified:
        return Colors.green;
      case TaxCalculationStatus.filed:
        return Colors.purple;
      case TaxCalculationStatus.adjusted:
        return Colors.amber;
    }
  }

  Widget _buildCalculationCard(TaxCalculation calculation) {
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
                    calculation.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Invoice: ${calculation.invoiceId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(calculation.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusLabel(calculation.status),
                style: TextStyle(
                  color: _getStatusColor(calculation.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal: \$${calculation.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Tax: \$${calculation.totalTax.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Total: \$${calculation.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Effective Rate: ${calculation.effectiveTaxRate.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Tax Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...calculation.taxItems.map((item) {
                  return _buildTaxItemTile(item);
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (calculation.status == TaxCalculationStatus.calculated)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.verified),
                          label: const Text('Verify'),
                          onPressed: () => _showVerifyDialog(calculation),
                        ),
                      ),
                    if (calculation.status == TaxCalculationStatus.verified) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.file_present),
                          label: const Text('Mark Filed'),
                          onPressed: () => _showFileDialog(calculation),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Adjust'),
                        onPressed: () => _showAdjustDialog(calculation),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxItemTile(TaxItem item) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(_getTaxTypeIcon(item.type)),
      ),
      title: Text(item.name),
      subtitle: Text(
        '${_getTaxTypeLabel(item.type)} • ${item.rate}% ${item.isInclusive ? '(inclusive)' : '(exclusive)'}',
      ),
      trailing: Text(
        '\$${item.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  IconData _getTaxTypeIcon(TaxType type) {
    switch (type) {
      case TaxType.sales:
        return Icons.receipt;
      case TaxType.vat:
        return Icons.percent;
      case TaxType.gst:
        return Icons.account_balance;
      case TaxType.service:
        return Icons.room_service;
      case TaxType.excise:
        return Icons.local_bar;
      case TaxType.customs:
        return Icons.flight_takeoff;
      case TaxType.other:
        return Icons.help_outline;
    }
  }

  String _getTaxTypeLabel(TaxType type) {
    switch (type) {
      case TaxType.sales:
        return 'Sales Tax';
      case TaxType.vat:
        return 'VAT';
      case TaxType.gst:
        return 'GST';
      case TaxType.service:
        return 'Service Tax';
      case TaxType.excise:
        return 'Excise Tax';
      case TaxType.customs:
        return 'Customs Duty';
      case TaxType.other:
        return 'Other Tax';
    }
  }

  void _showCalculateTaxDialog() {
    final invoiceIdController = TextEditingController();
    final invoiceNumberController = TextEditingController();
    final subtotalController = TextEditingController();
    final jurisdictionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate Tax'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: invoiceIdController,
                decoration: const InputDecoration(
                  labelText: 'Invoice ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtotalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Subtotal Amount',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jurisdictionController,
                decoration: const InputDecoration(
                  labelText: 'Jurisdiction (e.g., US, CA, UK)',
                ),
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
              final invoiceId = invoiceIdController.text.trim();
              final invoiceNumber = invoiceNumberController.text.trim();
              final subtotal = double.tryParse(subtotalController.text);
              final jurisdiction = jurisdictionController.text.trim();

              if (invoiceId.isEmpty ||
                  invoiceNumber.isEmpty ||
                  subtotal == null ||
                  jurisdiction.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final repository = ref.read(taxCalculationRepositoryProvider);
                final calculation = await repository.calculateTax(
                  invoiceId: invoiceId,
                  invoiceNumber: invoiceNumber,
                  subtotal: subtotal,
                  jurisdiction: jurisdiction,
                  userId: 'admin',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(taxCalculationsProvider(_selectedStatus));
                  ref.invalidate(taxStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tax calculated: \$${calculation.totalTax.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(TaxCalculation calculation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Tax Calculation'),
        content: Text(
          'Are you sure you want to verify the tax calculation for invoice ${calculation.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(taxCalculationRepositoryProvider);
                await repository.markAsVerified(calculation.id, 'admin');

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(taxCalculationsProvider(_selectedStatus));
                  ref.invalidate(taxStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tax calculation verified')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showFileDialog(TaxCalculation calculation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Filed'),
        content: Text(
          'Are you sure you want to mark the tax calculation for invoice ${calculation.invoiceNumber} as filed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(taxCalculationRepositoryProvider);
                await repository.markAsFiled(calculation.id, 'admin');

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(taxCalculationsProvider(_selectedStatus));
                  ref.invalidate(taxStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tax calculation marked as filed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Mark Filed'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(TaxCalculation calculation) {
    final adjustedItems = List<TaxItem>.from(calculation.taxItems);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Tax Calculation'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: adjustedItems.length,
              itemBuilder: (context, index) {
                final item = adjustedItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Rate: ${item.rate}%'),
                  trailing: SizedBox(
                    width: 120,
                    child: TextField(
                      controller: TextEditingController(text: item.amount.toStringAsFixed(2)),
                      decoration: const InputDecoration(
                        prefixText: '\$',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final newAmount = double.tryParse(value);
                        if (newAmount != null) {
                          setDialogState(() {
                            adjustedItems[index] = item.copyWith(amount: newAmount);
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final repository = ref.read(taxCalculationRepositoryProvider);
                  await repository.recalculateTax(calculation.id, adjustedItems);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(taxCalculationsProvider(_selectedStatus));
                    ref.invalidate(taxStatsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tax calculation adjusted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Adjustments'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaxConfigurationsDialog() {
    final configsAsync = ref.watch(taxConfigurationsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Configurations'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: configsAsync.when(
            data: (configs) {
              if (configs.isEmpty) {
                return const Center(
                  child: Text('No tax configurations found'),
                );
              }
              return ListView.builder(
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  return ListTile(
                    title: Text(config.jurisdiction),
                    subtitle: Text('${config.countryCode} • ${config.rules.length} rules'),
                    trailing: Icon(
                      config.isActive ? Icons.check_circle : Icons.cancel,
                      color: config.isActive ? Colors.green : Colors.grey,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
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
}