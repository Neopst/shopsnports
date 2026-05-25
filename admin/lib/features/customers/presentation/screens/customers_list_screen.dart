import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'customer_detail_screen.dart';
import '../utils/phone_formatter.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  String _searchQuery = '';
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final statsAsync = ref.watch(customerStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.refresh(customersProvider);
                  ref.refresh(customerStatsProvider);
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Cards
          _buildStatsCards(statsAsync),
          const SizedBox(height: 16),

          // Search and Filters
          _buildSearchAndFilters(),
          const SizedBox(height: 16),

          // Customers Table
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref.refresh(customersProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No customers found'),
                        if (_searchQuery.isNotEmpty || _statusFilter != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _statusFilter = null;
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  );
                }

                final filteredCustomers = customers.where((customer) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (customer.phone?.contains(_searchQuery) ?? false);
                  final matchesStatus =
                      _statusFilter == null || customer.status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                return filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No customers match your filters'),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _statusFilter = null;
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    : _buildCustomersTable(filteredCustomers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => Row(
        children: List.generate(4, (_) => const Expanded(child: Card(child: SizedBox(height: 80)))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        return Row(
          children: [
            _StatCard(
              title: 'Total',
              value: (stats['total'] ?? 0).toString(),
              color: Colors.blue,
              icon: Icons.people,
              onTap: () => setState(() => _statusFilter = null),
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Active',
              value: (stats['active'] ?? 0).toString(),
              color: Colors.green,
              icon: Icons.check_circle,
              onTap: () => setState(() => _statusFilter = 'active'),
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Suspended',
              value: (stats['suspended'] ?? 0).toString(),
              color: Colors.orange,
              icon: Icons.pause_circle,
              onTap: () => setState(() => _statusFilter = 'suspended'),
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Banned',
              value: (stats['banned'] ?? 0).toString(),
              color: Colors.red,
              icon: Icons.block,
              onTap: () => setState(() => _statusFilter = 'banned'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (isSelected) {
                    setState(() => _statusFilter = null);
                  },
                ),
                FilterChip(
                  label: const Text('Active'),
                  selected: _statusFilter == 'active',
                  onSelected: (isSelected) {
                    setState(() => _statusFilter = isSelected ? 'active' : null);
                  },
                ),
                FilterChip(
                  label: const Text('Suspended'),
                  selected: _statusFilter == 'suspended',
                  onSelected: (isSelected) {
                    setState(() =>
                        _statusFilter = isSelected ? 'suspended' : null);
                  },
                ),
                FilterChip(
                  label: const Text('Banned'),
                  selected: _statusFilter == 'banned',
                  onSelected: (isSelected) {
                    setState(() =>
                        _statusFilter = isSelected ? 'banned' : null);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTable(List<Customer> customers) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) =>
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ),
          columns: const [
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Orders')),
            DataColumn(label: Text('Spent')),
            DataColumn(label: Text('Joined')),
            DataColumn(label: Text('Actions')),
          ],
          rows: customers.map((customer) => _buildCustomerRow(customer)).toList(),
        ),
      ),
    );
  }

  DataRow _buildCustomerRow(Customer customer) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => _viewCustomerDetail(customer),
            child: Row(
              children: [
                _buildCustomerAvatar(customer),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (customer.businessName != null &&
                        customer.businessName!.isNotEmpty)
                      Text(
                        customer.businessName!,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        DataCell(
          LimitedBox(
            maxWidth: 180,
            child: Text(
              customer.email,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(formatPhoneWithFlag(customer.phone))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(customer.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              customer.displayStatus,
              style: TextStyle(
                color: _getStatusColor(customer.status),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(customer.totalOrders.toString())),
        DataCell(Text('\$${customer.totalSpent.toStringAsFixed(0)}')),
        DataCell(
          Text(
            '${customer.createdAt.month}/${customer.createdAt.day}/${customer.createdAt.year}',
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view') {
                _viewCustomerDetail(customer);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerAvatar(Customer customer) {
    if (customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(customer.avatarUrl!),
        radius: 20,
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }
    final initials = customer.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join('');
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue.shade300,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _viewCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerId: customer.id),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}