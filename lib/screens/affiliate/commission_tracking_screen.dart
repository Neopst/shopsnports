import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/shipping_request.dart';
import '../../models/enums.dart';
import '../../services/affiliate_api_service.dart';
import '../../widgets/main_scaffold.dart';

/// Commission Tracking Screen
/// Admin Dashboard compliant - shows commission details for affiliated shipments
class CommissionTrackingScreen extends ConsumerStatefulWidget {
  const CommissionTrackingScreen({super.key});

  @override
  ConsumerState<CommissionTrackingScreen> createState() =>
      _CommissionTrackingScreenState();
}

class _CommissionTrackingScreenState
    extends ConsumerState<CommissionTrackingScreen> {
  final _affiliateService = AffiliateService();
  List<ShippingRequest> _shipments = [];
  bool _isLoading = true;
  String? _error;
  ShippingStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shipments = await _affiliateService.getShipments(
        status: _filterStatus,
      );

      setState(() {
        _shipments = shipments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.delivered:
        return Colors.green;
      case ShippingStatus.inTransit:
        return Colors.blue;
      case ShippingStatus.approved:
        return Colors.teal;
      case ShippingStatus.pending:
        return Colors.orange;
      case ShippingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.delivered:
        return Icons.check_circle;
      case ShippingStatus.inTransit:
        return Icons.local_shipping;
      case ShippingStatus.approved:
        return Icons.verified;
      case ShippingStatus.pending:
        return Icons.pending;
      case ShippingStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCommission = _shipments.fold<double>(
      0,
      (sum, shipment) => sum + shipment.affiliateCommission,
    );

    return MainScaffold(
      appBarTitle: 'Commission Tracking',
      showBackOnly: true,
      body: Column(
        children: [
          // Total Commission Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Commission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${totalCommission.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${_shipments.length} shipments',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ShippingStatus?>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...ShippingStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadShipments();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadShipments,
                ),
              ],
            ),
          ),

          // Shipments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadShipments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _shipments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No shipments yet'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadShipments,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _shipments.length,
                              itemBuilder: (context, index) {
                                final shipment = _shipments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          children: [
                                            Icon(
                                              _getStatusIcon(shipment.status),
                                              color: _getStatusColor(
                                                  shipment.status),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Request #${shipment.id.substring(0, 8)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        shipment.status)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                shipment.status.name
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getStatusColor(
                                                      shipment.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        // Route
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.flight_takeoff,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          shipment.origin,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.flight_land,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          shipment.destination,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Commission
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Commission',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  '\$${shipment.affiliateCommission.toStringAsFixed(2)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Details
                                        Row(
                                          children: [
                                            Icon(Icons.scale,
                                                size: 16,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${shipment.weight} kg',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                                shipment.type ==
                                                        ShippingType.air
                                                    ? Icons.flight
                                                    : Icons.directions_boat,
                                                size: 16,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              shipment.type.name.toUpperCase(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            const Spacer(),
                                            Text(
                                              DateFormat('MMM dd, yyyy')
                                                  .format(shipment.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
