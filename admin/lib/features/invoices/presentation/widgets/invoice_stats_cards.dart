import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoice_providers.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class InvoiceStatsCards extends ConsumerWidget {
  const InvoiceStatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(invoiceStatsProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    return statsAsync.when(
      data: (stats) => _buildStatsCards(stats, formatter),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatsCards(
    Map<String, dynamic> stats,
    CurrencyFormatter formatter,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Invoices',
            value: '${stats['totalInvoices'] ?? 0}',
            icon: Icons.description,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Total Revenue',
            value: formatter.format(
              stats['totalRevenue'] ?? 0,
              decimalDigits: 2,
            ),
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Pending Amount',
            value: formatter.format(
              stats['pendingAmount'] ?? 0,
              decimalDigits: 2,
            ),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Paid Invoices',
            value: '${stats['paidInvoices'] ?? 0}',
            icon: Icons.check_circle,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
