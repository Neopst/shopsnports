// FILE: lib/features/dashboard/presentation/shipping_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shipping/presentation/providers/shipping_requests_providers.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingRequestScreen extends ConsumerStatefulWidget {
  const ShippingRequestScreen({super.key});

  @override
  ConsumerState<ShippingRequestScreen> createState() =>
      _ShippingRequestScreenState();
}

class _ShippingRequestScreenState extends ConsumerState<ShippingRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';
  String? _filterType;
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ShippingRequestsFilter(
      page: _currentPage,
      limit: _limit,
      status: _filterStatus == 'all' ? null : _filterStatus,
      shippingType: _filterType,
    );

    final shippingRequestsAsync = ref.watch(
      shippingRequestsListProvider(filter),
    );
    final shippingStatsAsync = ref.watch(shippingStatsProviderNew);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Requests'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Shipping Requests'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(shippingRequestsListProvider);
              ref.invalidate(shippingStatsProviderNew);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(shippingRequestsAsync, shippingStatsAsync),
          _buildAnalyticsTab(shippingStatsAsync),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(
    AsyncValue<Map<String, dynamic>> requestsAsync,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final formatter = CurrencyFormatter(currencyService, selectedCurrency);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchAndFilterBar(statsAsync),
          const SizedBox(height: 16),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(shippingRequestsListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final requests = (data['shipping_requests'] as List?) ?? [];
                final pagination =
                    data['pagination'] as Map<String, dynamic>? ?? {};
                return _buildRequestsList(requests, pagination, formatter);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search shipping requests...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      // Search query removed
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _filterStatus) {
                      setState(() {
                        _filterStatus = newValue;
                        _currentPage = 1;
                      });
                      // Invalidate to trigger refetch with new filter
                      ref.invalidate(shippingRequestsListProvider);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'reviewing',
                      child: Text('Reviewing'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'carrier_assigned',
                      child: Text('Carrier Assigned'),
                    ),
                    DropdownMenuItem(
                      value: 'in_transit',
                      child: Text('In Transit'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    value: _filterType,
                    hint: const Text('All Shipping Types'),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != _filterType) {
                        setState(() {
                          _filterType = newValue;
                          _currentPage = 1;
                        });
                        // Invalidate to trigger refetch with new filter
                        ref.invalidate(shippingRequestsListProvider);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Types')),
                      DropdownMenuItem(
                        value: 'air',
                        child: Text('Air Shipping'),
                      ),
                      DropdownMenuItem(
                        value: 'sea',
                        child: Text('Sea Shipping'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(shippingRequestsListProvider);
                    ref.invalidate(shippingStatsProviderNew);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            statsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const Text('Error loading stats'),
              data: (stats) => _buildQuickStats(stats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatChip(
            'Total',
            stats['total']?.toString() ?? '0',
            Colors.blue,
          ),
          _buildStatChip(
            'Pending',
            stats['pending']?.toString() ?? '0',
            Colors.orange,
          ),
          _buildStatChip(
            'In Transit',
            stats['in_transit']?.toString() ?? '0',
            Colors.purple,
          ),
          _buildStatChip(
            'Delivered',
            stats['delivered']?.toString() ?? '0',
            Colors.green,
          ),
          _buildStatChip(
            'Air',
            stats['by_type']?['air']?.toString() ?? '0',
            Colors.blue,
          ),
          _buildStatChip(
            'Sea',
            stats['by_type']?['sea']?.toString() ?? '0',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text('$label: $value'),
        backgroundColor: color.withValues(alpha:0.1),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRequestsList(
    List<dynamic> requests,
    Map<String, dynamic> pagination,
    CurrencyFormatter formatter,
  ) {
    if (requests.isEmpty) {
      return const Center(child: Text('No shipping requests found'));
    }

    final totalPages = pagination['total_pages'] as int? ?? 1;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildRequestsTable(requests, formatter),
            ),
          ),
        ),
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildRequestsTable(
    List<dynamic> requests,
    CurrencyFormatter formatter,
  ) {
    return Card(
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => const Color(0xFF0A2A66).withAlpha(25),
        ),
        columns: const [
          DataColumn(label: Text('Order Number')),
          DataColumn(label: Text('Client Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Origin')),
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Weight (kg)'), numeric: true),
          DataColumn(label: Text('Created')),
          DataColumn(label: Text('Actions')),
        ],
        rows: requests.map((request) {
          final req = request as Map<String, dynamic>;
          return _buildRequestRow(req, formatter);
        }).toList(),
      ),
    );
  }

  DataRow _buildRequestRow(
    Map<String, dynamic> request,
    CurrencyFormatter formatter,
  ) {
    final id = request['id'] ?? '';
    final trackingNumber = request['trackingNumber'] ?? 'N/A';
    final clientName = request['clientName'] ?? 'Unknown';
    final clientPhone = request['clientPhone'] ?? 'N/A';
    final clientEmail = request['clientEmail'] ?? 'N/A';
    final origin = request['origin'] ?? 'Unknown';
    final destination = request['destination'] ?? 'Unknown';
    final type = request['type'] ?? 'unknown';
    final status = request['status'] ?? 'unknown';
    final weight = request['weight'] != null
        ? double.tryParse(request['weight'].toString()) ?? 0
        : 0;

    // Handle createdAt - can be Timestamp, DateTime, or String
    DateTime? createdAt;
    final createdAtValue = request['createdAt'];
    if (createdAtValue != null) {
      if (createdAtValue is Timestamp) {
        createdAt = createdAtValue.toDate();
      } else if (createdAtValue is DateTime) {
        createdAt = createdAtValue;
      } else if (createdAtValue is String) {
        createdAt = DateTime.tryParse(createdAtValue);
      }
    }

    return DataRow(
      cells: [
        DataCell(
          Text(
            trackingNumber != 'N/A'
                ? trackingNumber
                : 'TRK-${id.substring(0, 8)}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A2A66),
            ),
          ),
        ),
        DataCell(Text(clientName)),
        DataCell(Text(clientPhone)),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(clientEmail, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(origin)),
        DataCell(Text(destination)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'air' ? Icons.flight : Icons.directions_boat,
                size: 16,
                color: type == 'air' ? Colors.blue : Colors.teal,
              ),
              const SizedBox(width: 4),
              Text(type.toUpperCase()),
            ],
          ),
        ),
        DataCell(
          Chip(
            label: Text(
              status.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: _getStatusColor(status).withValues(alpha:0.2),
            labelStyle: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        DataCell(Text(weight.toStringAsFixed(2))),
        DataCell(
          Text(
            createdAt != null
                ? DateFormat('MMM d, y').format(createdAt)
                : 'N/A',
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 18),
                onPressed: () {
                  context.go('/dashboard/shipping-request/$id');
                },
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text('Page $_currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'carrier_assigned':
        return Colors.purple;
      case 'in_transit':
        return Colors.indigo;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAnalyticsTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (stats) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Shipping Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildAnalyticsCard(
                      'Total Requests',
                      stats['total']?.toString() ?? '0',
                      Icons.local_shipping,
                      Colors.blue,
                    ),
                    _buildAnalyticsCard(
                      'Pending',
                      stats['pending']?.toString() ?? '0',
                      Icons.pending,
                      Colors.orange,
                    ),
                    _buildAnalyticsCard(
                      'In Transit',
                      stats['in_transit']?.toString() ?? '0',
                      Icons.delivery_dining,
                      Colors.purple,
                    ),
                    _buildAnalyticsCard(
                      'Delivered',
                      stats['delivered']?.toString() ?? '0',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
