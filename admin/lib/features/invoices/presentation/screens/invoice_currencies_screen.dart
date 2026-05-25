import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice_currency.dart';
import '../../data/repositories/invoice_currency_repository.dart';

final currencyRepositoryProvider = Provider<InvoiceCurrencyRepository>((ref) {
  return InvoiceCurrencyRepository(FirebaseFirestore.instance);
});

final currenciesProvider = StreamProvider<List<InvoiceCurrency>>((ref) {
  return ref.watch(currencyRepositoryProvider).getAllCurrencies();
});

final activeCurrenciesProvider = StreamProvider<List<InvoiceCurrency>>((ref) {
  return ref.watch(currencyRepositoryProvider).getActiveCurrencies();
});

final defaultCurrencyProvider = FutureProvider<InvoiceCurrency?>((ref) async {
  final repository = ref.read(currencyRepositoryProvider);
  return repository.getDefaultCurrency();
});

final currencyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(currencyRepositoryProvider);
  return repository.getCurrencyStatistics();
});

class InvoiceCurrenciesScreen extends ConsumerStatefulWidget {
  const InvoiceCurrenciesScreen({super.key});

  @override
  ConsumerState<InvoiceCurrenciesScreen> createState() =>
      _InvoiceCurrenciesScreenState();
}

class _InvoiceCurrenciesScreenState extends ConsumerState<InvoiceCurrenciesScreen> {
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currenciesAsync = _showActiveOnly
        ? ref.watch(activeCurrenciesProvider)
        : ref.watch(currenciesProvider);
    final defaultCurrencyAsync = ref.watch(defaultCurrencyProvider);
    final statsAsync = ref.watch(currencyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Currencies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCurrencyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: currenciesAsync.when(
              data: (currencies) {
                final filteredCurrencies = _filterCurrencies(currencies);
                if (filteredCurrencies.isEmpty) {
                  return const Center(child: Text('No currencies found'));
                }
                return ListView.builder(
                  itemCount: filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    return _buildCurrencyCard(filteredCurrencies[index],
                        defaultCurrencyAsync.value);
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
          labelText: 'Search currencies',
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

  List<InvoiceCurrency> _filterCurrencies(List<InvoiceCurrency> currencies) {
    if (_searchQuery.isEmpty) return currencies;

    return currencies
        .where((currency) =>
            currency.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            currency.code.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildCurrencyCard(
      InvoiceCurrency currency, InvoiceCurrency? defaultCurrency) {
    final isDefault = defaultCurrency?.id == currency.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(currency.symbol),
        ),
        title: Row(
          children: [
            Text(currency.name),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${currency.code}'),
            const SizedBox(height: 4),
            Text('Example: ${currency.formatAmount(1234.56)}'),
            if (currency.exchangeRate != null) ...[
              const SizedBox(height: 4),
              Text('Exchange Rate: ${currency.exchangeRate} ${currency.baseCurrency ?? ""}'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                currency.isActive ? Icons.visibility : Icons.visibility_off,
                color: currency.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleActiveStatus(currency),
            ),
            if (!isDefault)
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: () => _setAsDefault(currency),
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCurrencyDialog(context, currency),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCurrency(currency),
            ),
          ],
        ),
        onTap: () => _showCurrencyDetails(context, currency),
      ),
    );
  }

  void _showCreateCurrencyDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    final symbolPositionController = TextEditingController(text: 'before');
    final decimalPlacesController = TextEditingController(text: '2');
    final thousandsSeparatorController = TextEditingController(text: ',');
    final decimalSeparatorController = TextEditingController(text: '.');
    final localeController = TextEditingController();
    final exchangeRateController = TextEditingController();
    final baseCurrencyController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code (e.g., USD)'),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(labelText: 'Symbol (e.g., \$)'),
                ),
                DropdownButtonFormField<String>(
                  value: symbolPositionController.text,
                  decoration: const InputDecoration(labelText: 'Symbol Position'),
                  items: const [
                    DropdownMenuItem(value: 'before', child: Text('Before')),
                    DropdownMenuItem(value: 'after', child: Text('After')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      symbolPositionController.text = value!;
                    });
                  },
                ),
                TextField(
                  controller: decimalPlacesController,
                  decoration: const InputDecoration(labelText: 'Decimal Places'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: thousandsSeparatorController,
                  decoration: const InputDecoration(labelText: 'Thousands Separator'),
                ),
                TextField(
                  controller: decimalSeparatorController,
                  decoration: const InputDecoration(labelText: 'Decimal Separator'),
                ),
                TextField(
                  controller: localeController,
                  decoration: const InputDecoration(labelText: 'Locale (e.g., en_US)'),
                ),
                TextField(
                  controller: exchangeRateController,
                  decoration: const InputDecoration(labelText: 'Exchange Rate (optional)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: baseCurrencyController,
                  decoration: const InputDecoration(labelText: 'Base Currency (optional)'),
                ),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() {
                      isDefault = value;
                    });
                  },
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
                if (codeController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    symbolController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Code, name, and symbol are required')),
                  );
                  return;
                }

                final repository = ref.read(currencyRepositoryProvider);
                final currency = InvoiceCurrency(
                  id: '',
                  code: codeController.text.toUpperCase(),
                  name: nameController.text,
                  symbol: symbolController.text,
                  symbolPosition: symbolPositionController.text,
                  decimalPlaces:
                      int.tryParse(decimalPlacesController.text) ?? 2,
                  thousandsSeparator: thousandsSeparatorController.text,
                  decimalSeparator: decimalSeparatorController.text,
                  locale: localeController.text.isNotEmpty
                      ? localeController.text
                      : null,
                  exchangeRate: exchangeRateController.text.isNotEmpty
                      ? double.tryParse(exchangeRateController.text)
                      : null,
                  baseCurrency: baseCurrencyController.text.isNotEmpty
                      ? baseCurrencyController.text.toUpperCase()
                      : null,
                  exchangeRateUpdatedAt: exchangeRateController.text.isNotEmpty
                      ? DateTime.now()
                      : null,
                  isDefault: isDefault,
                  createdAt: DateTime.now(),
                );

                await repository.createCurrency(currency);

                if (isDefault) {
                  await repository.setAsDefault(currency.id);
                }

                Navigator.pop(context);
                ref.invalidate(currenciesProvider);
                ref.invalidate(activeCurrenciesProvider);
                ref.invalidate(defaultCurrencyProvider);
                ref.invalidate(currencyStatsProvider);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCurrencyDialog(
      BuildContext context, InvoiceCurrency currency) {
    final codeController = TextEditingController(text: currency.code);
    final nameController = TextEditingController(text: currency.name);
    final symbolController = TextEditingController(text: currency.symbol);
    final symbolPositionController =
        TextEditingController(text: currency.symbolPosition ?? 'before');
    final decimalPlacesController =
        TextEditingController(text: currency.decimalPlaces?.toString() ?? '2');
    final thousandsSeparatorController =
        TextEditingController(text: currency.thousandsSeparator ?? ',');
    final decimalSeparatorController =
        TextEditingController(text: currency.decimalSeparator ?? '.');
    final localeController = TextEditingController(text: currency.locale ?? '');
    final exchangeRateController =
        TextEditingController(text: currency.exchangeRate?.toString() ?? '');
    final baseCurrencyController =
        TextEditingController(text: currency.baseCurrency ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
                DropdownButtonFormField<String>(
                  value: symbolPositionController.text,
                  decoration: const InputDecoration(labelText: 'Symbol Position'),
                  items: const [
                    DropdownMenuItem(value: 'before', child: Text('Before')),
                    DropdownMenuItem(value: 'after', child: Text('After')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      symbolPositionController.text = value!;
                    });
                  },
                ),
                TextField(
                  controller: decimalPlacesController,
                  decoration: const InputDecoration(labelText: 'Decimal Places'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: thousandsSeparatorController,
                  decoration: const InputDecoration(labelText: 'Thousands Separator'),
                ),
                TextField(
                  controller: decimalSeparatorController,
                  decoration: const InputDecoration(labelText: 'Decimal Separator'),
                ),
                TextField(
                  controller: localeController,
                  decoration: const InputDecoration(labelText: 'Locale'),
                ),
                TextField(
                  controller: exchangeRateController,
                  decoration: const InputDecoration(labelText: 'Exchange Rate'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: baseCurrencyController,
                  decoration: const InputDecoration(labelText: 'Base Currency'),
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
                final repository = ref.read(currencyRepositoryProvider);
                final updatedCurrency = currency.copyWith(
                  code: codeController.text.toUpperCase(),
                  name: nameController.text,
                  symbol: symbolController.text,
                  symbolPosition: symbolPositionController.text,
                  decimalPlaces:
                      int.tryParse(decimalPlacesController.text) ?? currency.decimalPlaces,
                  thousandsSeparator: thousandsSeparatorController.text,
                  decimalSeparator: decimalSeparatorController.text,
                  locale: localeController.text.isNotEmpty
                      ? localeController.text
                      : null,
                  exchangeRate: exchangeRateController.text.isNotEmpty
                      ? double.tryParse(exchangeRateController.text)
                      : null,
                  baseCurrency: baseCurrencyController.text.isNotEmpty
                      ? baseCurrencyController.text.toUpperCase()
                      : null,
                  exchangeRateUpdatedAt: exchangeRateController.text.isNotEmpty
                      ? DateTime.now()
                      : currency.exchangeRateUpdatedAt,
                  updatedAt: DateTime.now(),
                );

                await repository.updateCurrency(updatedCurrency);
                Navigator.pop(context);
                ref.invalidate(currenciesProvider);
                ref.invalidate(activeCurrenciesProvider);
                ref.invalidate(defaultCurrencyProvider);
                ref.invalidate(currencyStatsProvider);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDetails(BuildContext context, InvoiceCurrency currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currency.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code: ${currency.code}'),
              const SizedBox(height: 8),
              Text('Symbol: ${currency.symbol}'),
              const SizedBox(height: 8),
              Text('Symbol Position: ${currency.symbolPosition ?? "before"}'),
              const SizedBox(height: 8),
              Text('Decimal Places: ${currency.decimalPlaces ?? 2}'),
              const SizedBox(height: 8),
              Text('Thousands Separator: ${currency.thousandsSeparator ?? ","}'),
              const SizedBox(height: 8),
              Text('Decimal Separator: ${currency.decimalSeparator ?? "."}'),
              const SizedBox(height: 8),
              Text('Locale: ${currency.locale ?? "None"}'),
              const SizedBox(height: 8),
              Text('Exchange Rate: ${currency.exchangeRate ?? "None"}'),
              const SizedBox(height: 8),
              Text('Base Currency: ${currency.baseCurrency ?? "None"}'),
              if (currency.exchangeRateUpdatedAt != null) ...[
                const SizedBox(height: 8),
                Text('Rate Updated: ${currency.exchangeRateUpdatedAt!.toLocal()}'),
              ],
              const SizedBox(height: 8),
              Text('Active: ${currency.isActive ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Default: ${currency.isDefault ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Created: ${currency.createdAt.toLocal()}'),
              if (currency.updatedAt != null) ...[
                const SizedBox(height: 8),
                Text('Updated: ${currency.updatedAt!.toLocal()}'),
              ],
              const SizedBox(height: 16),
              const Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('1,234.56: ${currency.formatAmount(1234.56)}'),
              Text('10,000.00: ${currency.formatAmount(10000.00)}'),
              Text('0.99: ${currency.formatAmount(0.99)}'),
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

  void _toggleActiveStatus(InvoiceCurrency currency) async {
    final repository = ref.read(currencyRepositoryProvider);
    await repository.toggleActiveStatus(currency.id, !currency.isActive);
    ref.invalidate(currenciesProvider);
    ref.invalidate(activeCurrenciesProvider);
    ref.invalidate(defaultCurrencyProvider);
    ref.invalidate(currencyStatsProvider);
  }

  void _setAsDefault(InvoiceCurrency currency) async {
    final repository = ref.read(currencyRepositoryProvider);
    await repository.setAsDefault(currency.id);
    ref.invalidate(currenciesProvider);
    ref.invalidate(activeCurrenciesProvider);
    ref.invalidate(defaultCurrencyProvider);
    ref.invalidate(currencyStatsProvider);
  }

  void _deleteCurrency(InvoiceCurrency currency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Currency'),
        content: Text('Are you sure you want to delete "${currency.name}"?'),
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
      final repository = ref.read(currencyRepositoryProvider);
      await repository.deleteCurrency(currency.id);
      ref.invalidate(currenciesProvider);
      ref.invalidate(activeCurrenciesProvider);
      ref.invalidate(defaultCurrencyProvider);
      ref.invalidate(currencyStatsProvider);
    }
  }

  void _showStatistics(BuildContext context) {
    final statsAsync = ref.read(currencyStatsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency Statistics'),
        content: statsAsync.when(
          data: (stats) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Currencies: ${stats['totalCurrencies']}'),
              const SizedBox(height: 8),
              Text('Active Currencies: ${stats['activeCurrencies']}'),
              const SizedBox(height: 8),
              Text('Inactive Currencies: ${stats['inactiveCurrencies']}'),
              const SizedBox(height: 8),
              Text('With Exchange Rates: ${stats['currenciesWithExchangeRate']}'),
            ],
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