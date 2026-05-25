import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_dashboard/features/settings/presentation/providers/settings_providers.dart';
import 'package:admin_dashboard/features/settings/data/models/index.dart';
import 'package:admin_dashboard/core/models/currency.dart';
import 'package:admin_dashboard/core/providers/currency_provider.dart';
import 'company_details_screen.dart';
import '../widgets/payment_method_form_dialog.dart';
import '../widgets/shipping_zone_form_dialog.dart';

class SettingsDashboardScreen extends ConsumerWidget {
  const SettingsDashboardScreen({super.key});

  static void _addPaymentMethod(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => const PaymentMethodFormDialog(),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment method "${result.name}" added')),
      );
      // TODO: Call ref.read(paymentMethodsProvider.notifier).addMethod(result);
    }
  }

  static void _addShippingZone(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<ShippingZone>(
      context: context,
      builder: (context) => const ShippingZoneFormDialog(),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shipping zone "${result.name}" added')),
      );
      // TODO: Call ref.read(shippingZonesProvider.notifier).addZone(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessSettingsAsync = ref.watch(businessSettingsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final shippingZonesAsync = ref.watch(shippingZonesProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final lastUpdate = ref.watch(ratesLastUpdateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Currency Selector Section
            const _SectionHeader(
              title: 'Currency Settings',
              icon: Icons.currency_exchange,
            ),
            const SizedBox(height: 16),
            _CurrencySettingsCard(
              selectedCurrency: selectedCurrency,
              lastUpdate: lastUpdate,
              onCurrencyChanged: (currency) {
                ref
                    .read(selectedCurrencyProvider.notifier)
                    .setCurrency(currency);
              },
              onRefreshRates: () {
                ref.read(selectedCurrencyProvider.notifier).refreshRates();
              },
            ),
            const SizedBox(height: 32),
            // Configuration Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CompanyDetailsScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.business,
                                size: 32,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Company Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Configure company information for invoices',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        context.push('/dashboard/notifications/preferences');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications,
                                size: 32,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notification Preferences',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your notification settings',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _ConfigCard(
                  title: 'Business Name',
                  value: businessSettingsAsync.maybeWhen(
                    data: (settings) => settings.businessName,
                    orElse: () => 'N/A',
                  ),
                  icon: Icons.store,
                ),
                _ConfigCard(
                  title: 'Tax Rate',
                  value: businessSettingsAsync.maybeWhen(
                    data: (settings) => '${settings.taxRate ?? 0}%',
                    orElse: () => 'N/A',
                  ),
                  icon: Icons.percent,
                ),
                _ConfigCard(
                  title: 'Currency',
                  value: businessSettingsAsync.maybeWhen(
                    data: (settings) => settings.currency ?? 'USD',
                    orElse: () => 'N/A',
                  ),
                  icon: Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Business Settings Section
            const _SectionHeader(
              title: 'Business Settings',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            businessSettingsAsync.when(
              data: (settings) => _BusinessSettingsCard(settings: settings),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
            const SizedBox(height: 32),
            // Shipping Zones Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(
                  title: 'Shipping Zones',
                  icon: Icons.local_shipping,
                ),
                ElevatedButton.icon(
                  onPressed: () => _addShippingZone(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Zone'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            shippingZonesAsync.when(
              data: (zones) => _ShippingZonesTable(zones: zones),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
            const SizedBox(height: 32),
            // Payment Methods Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(
                  title: 'Payment Methods',
                  icon: Icons.payment,
                ),
                ElevatedButton.icon(
                  onPressed: () => _addPaymentMethod(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment Method'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            paymentMethodsAsync.when(
              data: (methods) => _PaymentMethodsTable(methods: methods),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ConfigCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Colors.blue[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _BusinessSettingsCard extends StatelessWidget {
  final BusinessSettings settings;

  const _BusinessSettingsCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingRow(label: 'Business Name', value: settings.businessName),
            const Divider(),
            _SettingRow(label: 'Business Email', value: settings.businessEmail),
            const Divider(),
            _SettingRow(label: 'Business Phone', value: settings.businessPhone),
            const Divider(),
            _SettingRow(label: 'Tax Rate', value: '${settings.taxRate ?? 0}%'),
            const Divider(),
            _SettingRow(label: 'Currency', value: settings.currency ?? 'USD'),
            const Divider(),
            _SettingRow(label: 'Support Email', value: settings.supportEmail),
            const Divider(),
            _SettingRow(
              label: 'Enable Invoices',
              value: settings.enableInvoices ? 'Yes' : 'No',
              valueColor: settings.enableInvoices ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit settings functionality coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SettingRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingZonesTable extends StatelessWidget {
  final List<ShippingZone> zones;

  const _ShippingZonesTable({required this.zones});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Zone Name')),
            DataColumn(label: Text('Countries')),
            DataColumn(label: Text('Base Cost')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: zones.map((zone) {
            return DataRow(
              cells: [
                DataCell(Text(zone.name)),
                DataCell(Text(zone.countries.join(', '))),
                DataCell(Text('\$${zone.baseShippingCost.toStringAsFixed(2)}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: zone.isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      zone.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: zone.isActive
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit zone: ${zone.name}')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delete zone: ${zone.name}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PaymentMethodsTable extends StatelessWidget {
  final List<PaymentMethod> methods;

  const _PaymentMethodsTable({required this.methods});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Method Name')),
            DataColumn(label: Text('Provider')),
            DataColumn(label: Text('Enabled')),
            DataColumn(label: Text('Default')),
            DataColumn(label: Text('Actions')),
          ],
          rows: methods.map((method) {
            return DataRow(
              cells: [
                DataCell(Text(method.name)),
                DataCell(Text(method.type)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: method.isEnabled
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      method.isEnabled ? 'Yes' : 'No',
                      style: TextStyle(
                        color: method.isEnabled
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Icon(
                    method.isDefault
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: method.isDefault
                        ? Colors.blue[700]
                        : Colors.grey[400],
                    size: 20,
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Edit method: ${method.name}'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delete method: ${method.name}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CurrencySettingsCard extends StatelessWidget {
  final Currency selectedCurrency;
  final String lastUpdate;
  final Function(Currency) onCurrencyChanged;
  final VoidCallback onRefreshRates;

  const _CurrencySettingsCard({
    required this.selectedCurrency,
    required this.lastUpdate,
    required this.onCurrencyChanged,
    required this.onRefreshRates,
  });

  @override
  Widget build(BuildContext context) {
    // Available currencies
    final currencies = [
      Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
      Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
      Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
      Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
      Currency(
        code: 'ZAR',
        name: 'South African Rand',
        symbol: 'R',
        flag: '🇿🇦',
      ),
      Currency(
        code: 'KES',
        name: 'Kenyan Shilling',
        symbol: 'KSh',
        flag: '🇰🇪',
      ),
      Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', flag: '🇬🇭'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Display Currency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: onRefreshRates,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Rates'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    initialValue: selectedCurrency,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Row(
                          children: [
                            Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('${currency.code} - ${currency.name}'),
                            const SizedBox(width: 8),
                            Text(
                              currency.symbol,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (currency) {
                      if (currency != null) {
                        onCurrencyChanged(currency);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Selection: ${selectedCurrency.flag} ${selectedCurrency.code}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Exchange rates last updated: $lastUpdate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base currency: 🇳🇬 Nigerian Naira (NGN)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
