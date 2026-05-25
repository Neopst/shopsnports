import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_providers.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class EnhancedAnalyticsDashboard extends ConsumerStatefulWidget {
  const EnhancedAnalyticsDashboard({super.key});

  @override
  ConsumerState<EnhancedAnalyticsDashboard> createState() =>
      _EnhancedAnalyticsDashboardState();
}

class _EnhancedAnalyticsDashboardState
    extends ConsumerState<EnhancedAnalyticsDashboard> {
  String _selectedPeriod = '30days';

  @override
  Widget build(BuildContext context) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final salesTrends = ref.watch(salesTrendsProvider(_selectedPeriod));
    final bestSellers = ref.watch(bestSellersProvider);
    final vendorPerformance = ref.watch(vendorPerformanceProvider);
    final shippingVolume = ref.watch(shippingVolumeProvider);
    final revenue = ref.watch(revenueProvider(_selectedPeriod));
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final currencyFormatter = CurrencyFormatter(
      currencyService,
      selectedCurrency,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          // Currency indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Chip(
              avatar: Text(
                selectedCurrency.flag,
                style: const TextStyle(fontSize: 16),
              ),
              label: Text(selectedCurrency.code),
              backgroundColor: Colors.white.withValues(alpha:0.2),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            icon: const Icon(Icons.date_range),
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '7days', child: Text('Last 7 days')),
              PopupMenuItem(value: '30days', child: Text('Last 30 days')),
              PopupMenuItem(value: '90days', child: Text('Last 90 days')),
              PopupMenuItem(value: '365days', child: Text('Last year')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(salesTrendsProvider);
              ref.invalidate(bestSellersProvider);
              ref.invalidate(vendorPerformanceProvider);
              ref.invalidate(shippingVolumeProvider);
              ref.invalidate(revenueProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Analytics Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(dashboardStatsProvider);
                    ref.invalidate(revenueProvider);
                  },
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // KPI Cards
            dashboardStats.when(
              data: (stats) => _buildKPICards(stats, currencyFormatter),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorCard(error),
            ),
            const SizedBox(height: 24),

            // Revenue Overview
            revenue.when(
              data: (data) => _buildRevenueCard(data, currencyFormatter),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error),
            ),
            const SizedBox(height: 24),

            // Sales Trends
            const Text(
              'Sales Trends',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            salesTrends.when(
              data: (trends) =>
                  _buildSalesTrendsCard(trends, currencyFormatter),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error),
            ),
            const SizedBox(height: 24),

            // Best Sellers
            const Text(
              'Best Sellers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            bestSellers.when(
              data: (products) =>
                  _buildBestSellersCard(products, currencyFormatter),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error),
            ),
            const SizedBox(height: 24),

            // Vendor Performance
            const Text(
              'Vendor Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            vendorPerformance.when(
              data: (vendors) =>
                  _buildVendorPerformanceCard(vendors, currencyFormatter),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error),
            ),
            const SizedBox(height: 24),

            // Shipping Volume
            const Text(
              'Shipping Volume',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            shippingVolume.when(
              data: (data) => _buildShippingVolumeCard(data, currencyFormatter),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(
    Map<String, dynamic> stats,
    CurrencyFormatter formatter,
  ) {
    final orders = stats['orders'] ?? {};
    final entities = stats['entities'] ?? {};
    final shipping = stats['shipping'] ?? {};
    final payouts = stats['payouts'] ?? {};

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Orders',
          '${orders['total_orders'] ?? 0}',
          Icons.shopping_cart,
          Colors.blue,
          subtitle: '${orders['pending_orders'] ?? 0} pending',
        ),
        _buildKPICard(
          'Total Revenue',
          formatter.format(orders['total_revenue'] ?? 0, decimalDigits: 0),
          Icons.attach_money,
          Colors.green,
        ),
        _buildKPICard(
          'Active Vendors',
          '${entities['active_vendors'] ?? 0}',
          Icons.store,
          Colors.orange,
        ),
        _buildKPICard(
          'Active Products',
          '${entities['active_products'] ?? 0}',
          Icons.inventory,
          Colors.purple,
        ),
        _buildKPICard(
          'Total Customers',
          '${entities['total_customers'] ?? 0}',
          Icons.people,
          Colors.teal,
        ),
        _buildKPICard(
          'Active Affiliates',
          '${entities['active_affiliates'] ?? 0}',
          Icons.person_outline,
          Colors.indigo,
        ),
        _buildKPICard(
          'Shipping Requests',
          '${shipping['total_requests'] ?? 0}',
          Icons.local_shipping,
          Colors.brown,
          subtitle: '${shipping['in_transit_requests'] ?? 0} in transit',
        ),
        _buildKPICard(
          'Pending Payouts',
          formatter.format(payouts['pending_amount'] ?? 0, decimalDigits: 0),
          Icons.payments,
          Colors.red,
          subtitle: '${payouts['pending_payouts'] ?? 0} pending',
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    Map<String, dynamic> data,
    CurrencyFormatter formatter,
  ) {
    final grossRevenue =
        double.tryParse(data['gross_revenue']?.toString() ?? '0') ?? 0;
    final shippingRevenue =
        double.tryParse(data['shipping_revenue']?.toString() ?? '0') ?? 0;
    final avgOrderValue =
        double.tryParse(data['avg_order_value']?.toString() ?? '0') ?? 0;
    final orderCount =
        int.tryParse(data['order_count']?.toString() ?? '0') ?? 0;
    final uniqueCustomers =
        int.tryParse(data['unique_customers']?.toString() ?? '0') ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Gross Revenue',
                    formatter.format(grossRevenue, decimalDigits: 0),
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Shipping Revenue',
                    formatter.format(shippingRevenue, decimalDigits: 0),
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Avg Order Value',
                    formatter.format(avgOrderValue, decimalDigits: 0),
                  ),
                ),
                Expanded(child: _buildMetricColumn('Orders', '$orderCount')),
                Expanded(
                  child: _buildMetricColumn(
                    'Unique Customers',
                    '$uniqueCustomers',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSalesTrendsCard(
    List<Map<String, dynamic>> trends,
    CurrencyFormatter formatter,
  ) {
    if (trends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sales data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...trends.take(7).map((trend) {
              final date = DateTime.parse(trend['date']);
              final orderCount = trend['order_count'] ?? 0;
              final revenue = trend['revenue'] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(DateFormat('MMM d').format(date)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$orderCount orders'),
                          Text(
                            formatter.format(revenue, decimalDigits: 0),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellersCard(
    List<Map<String, dynamic>> products,
    CurrencyFormatter formatter,
  ) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No product data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...products.take(10).map((product) {
              final name = product['name'] ?? 'Unknown Product';
              final unitsSold = product['units_sold'] ?? 0;
              final revenue = product['total_revenue'] ?? 0;

              return ListTile(
                title: Text(name),
                subtitle: Text('$unitsSold units sold'),
                trailing: Text(
                  formatter.format(revenue, decimalDigits: 0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorPerformanceCard(
    List<Map<String, dynamic>> vendors,
    CurrencyFormatter formatter,
  ) {
    if (vendors.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No vendor data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...vendors.take(10).map((vendor) {
              final name = vendor['business_name'] ?? 'Unknown Vendor';
              final products = vendor['total_products'] ?? 0;
              final orders = vendor['total_orders'] ?? 0;
              final revenue = vendor['total_revenue'] ?? 0;
              final rating =
                  double.tryParse(vendor['avg_rating']?.toString() ?? '0') ?? 0;

              return ListTile(
                title: Text(name),
                subtitle: Text(
                  '$products products • $orders orders • ${rating.toStringAsFixed(1)}⭐',
                ),
                trailing: Text(
                  formatter.format(revenue, decimalDigits: 0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingVolumeCard(
    List<Map<String, dynamic>> data,
    CurrencyFormatter formatter,
  ) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No shipping data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...data.map((item) {
              final type = item['shipping_type'] ?? 'unknown';
              final status = item['status'] ?? 'unknown';
              final count = item['request_count'] ?? 0;
              final estimatedCost = item['total_estimated_cost'] ?? 0;

              return ListTile(
                title: Text('${type.toUpperCase()} - ${status.toUpperCase()}'),
                subtitle: Text('$count requests'),
                trailing: Text(
                  formatter.format(estimatedCost, decimalDigits: 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(child: Text('Error: $error')),
          ],
        ),
      ),
    );
  }
}
