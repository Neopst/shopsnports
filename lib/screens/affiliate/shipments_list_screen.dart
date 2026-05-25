import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/shipping_request.dart';
import '../../models/enums.dart';
import '../../providers/affiliate_shipment_providers.dart';
import 'shipment_details_screen.dart';

class ShipmentsListScreen extends ConsumerStatefulWidget {
  const ShipmentsListScreen({super.key});

  @override
  ConsumerState<ShipmentsListScreen> createState() =>
      _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends ConsumerState<ShipmentsListScreen> {
  ShippingStatus? _selectedStatus;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync =
        ref.watch(affiliateShipmentsByStatusProvider(_selectedStatus));
    final stats = ref.watch(affiliateShipmentStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Shipments'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Stats summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.inversePrimary,
            child: Row(
              children: [
                _StatCard(
                  label: 'Total',
                  value: stats['total']?.toString() ?? '0',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Pending',
                  value: stats['pending']?.toString() ?? '0',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'In Transit',
                  value: stats['inTransit']?.toString() ?? '0',
                  color: Colors.purple,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Delivered',
                  value: stats['delivered']?.toString() ?? '0',
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by shipment ID, client, or tracking...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: stats['total'] ?? 0,
                  isSelected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  count: stats['pending'] ?? 0,
                  isSelected: _selectedStatus == ShippingStatus.pending,
                  onTap: () =>
                      setState(() => _selectedStatus = ShippingStatus.pending),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'In Transit',
                  count: stats['inTransit'] ?? 0,
                  isSelected: _selectedStatus == ShippingStatus.inTransit,
                  onTap: () => setState(
                      () => _selectedStatus = ShippingStatus.inTransit),
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Delivered',
                  count: stats['delivered'] ?? 0,
                  isSelected: _selectedStatus == ShippingStatus.delivered,
                  onTap: () => setState(
                      () => _selectedStatus = ShippingStatus.delivered),
                  color: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shipments list
          Expanded(
            child: shipmentsAsync.when(
              data: (shipments) {
                // Apply search filter
                final filteredShipments = _searchQuery.isEmpty
                    ? shipments
                    : ref
                        .read(affiliateShipmentRepositoryProvider)
                        .searchShipments(
                          shipments,
                          _searchQuery,
                        );

                if (filteredShipments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No shipments found'
                              : 'No shipments yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(affiliateShipmentsByStatusProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredShipments.length,
                    itemBuilder: (context, index) {
                      final shipment = filteredShipments[index];
                      return _ShipmentCard(shipment: shipment);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading shipments',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShippingRequest shipment;

  const _ShipmentCard({required this.shipment});

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.pending:
        return Colors.orange;
      case ShippingStatus.approved:
        return Colors.blue;
      case ShippingStatus.inTransit:
        return Colors.purple;
      case ShippingStatus.delivered:
        return Colors.green;
      case ShippingStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.pending:
        return 'Pending';
      case ShippingStatus.approved:
        return 'Confirmed';
      case ShippingStatus.inTransit:
        return 'In Transit';
      case ShippingStatus.delivered:
        return 'Delivered';
      case ShippingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShipmentDetailsScreen(shipmentId: shipment.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Shipment ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shipment.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(shipment.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(shipment.status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _getStatusText(shipment.status),
                      style: TextStyle(
                        color: _getStatusColor(shipment.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Client name
              if (shipment.clientName != null)
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      shipment.clientName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Route
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${shipment.origin} → ${shipment.destination}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(shipment.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Footer: Weight and Commission
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${shipment.weight} kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Commission',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        _formatCurrency(shipment.affiliateCommission),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Tracking number (if available)
              if (shipment.trackingNumber != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping,
                          size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Tracking: ${shipment.trackingNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
