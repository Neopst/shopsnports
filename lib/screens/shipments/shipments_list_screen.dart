import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsnports/providers/shipping_requests_user_provider.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

/// Shipments List Screen - View all user's shipping requests
/// Displays shipments in a filterable list with status indicators
/// Synced with Firestore shippingRequests collection
class ShipmentsListScreen extends ConsumerStatefulWidget {
  static const routeName = '/shipments';
  const ShipmentsListScreen({super.key});

  @override
  ConsumerState<ShipmentsListScreen> createState() =>
      _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends ConsumerState<ShipmentsListScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    // Use paginated provider if user is logged in
    final shipmentsState = user != null
        ? ref.watch(paginatedShippingRequestsProvider(user.uid))
        : null;

    // Handle loading state
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Shipments')),
        body: const Center(
          child: Text('Please log in to view your shipments'),
        ),
      );
    }

    if (shipmentsState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Shipments')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Initial loading
    if (shipmentsState.requests.isEmpty && shipmentsState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Shipments'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (shipmentsState.error != null && shipmentsState.requests.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Shipments'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shipments',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                shipmentsState.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(paginatedShippingRequestsProvider(user.uid).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter shipments
    final filteredShipments = _selectedFilter == 'All'
        ? shipmentsState.requests
        : shipmentsState.requests
            .where((s) => s['status'] == _selectedFilter)
            .toList();

    if (filteredShipments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Shipments'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No shipments found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your shipment requests will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shipments'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(paginatedShippingRequestsProvider(user.uid).notifier)
              .refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Filter Chips
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterChipDelegate(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),
            // Shipments List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final shipment = filteredShipments[index];
                  return _ShipmentCard(
                    shipment: shipment,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.shipmentDetail,
                        arguments: shipment['id'],
                      );
                    },
                  );
                },
                childCount: filteredShipments.length,
              ),
            ),
            // Load More Button
            if (shipmentsState.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: shipmentsState.isLoading
                        ? null
                        : () => ref
                            .read(paginatedShippingRequestsProvider(user.uid).notifier)
                            .loadMore(),
                    icon: shipmentsState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(shipmentsState.isLoading
                        ? 'Loading...'
                        : 'Load More'),
                  ),
                ),
              ),
            // End of list indicator
            if (!shipmentsState.hasMore && filteredShipments.isNotEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'All shipments loaded',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter Chip Delegate for persistent header
class _FilterChipDelegate extends SliverPersistentHeaderDelegate {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  static final List<String> filters = [
    'All',
    'Processing',
    'In Transit',
    'Delivered',
    'Cancelled'
  ];

  _FilterChipDelegate({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  onFilterChanged(filter);
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(_FilterChipDelegate oldDelegate) {
    return selectedFilter != oldDelegate.selectedFilter;
  }
}

/// Individual Shipment Card Widget
class _ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  final VoidCallback onTap;

  const _ShipmentCard({
    required this.shipment,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.blue;
      case 'In Transit':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Processing':
        return Icons.hourglass_bottom;
      case 'In Transit':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipment #${shipment['id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(shipment['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(shipment['status']),
                          size: 14,
                          color: _getStatusColor(shipment['status']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shipment['status'],
                          style: TextStyle(
                            color: _getStatusColor(shipment['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route
              Row(
                children: [
                  Icon(Icons.flight_takeoff, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${shipment['origin']} → ${shipment['destination']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Recipient
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    shipment['recipient'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tracking Number
              Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shipment['trackingNumber'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    shipment['date'] is DateTime
                        ? DateFormat('MMM dd, yyyy').format(shipment['date'])
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
