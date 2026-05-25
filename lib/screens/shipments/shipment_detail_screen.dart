import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsnports/providers/shipping_providers.dart';

/// Shipment Detail Screen - View full details of a single shipment
/// Data from Firestore - Firebase is the single source of truth
class ShipmentDetailScreen extends ConsumerWidget {
  static const routeName = '/shipment-detail';
  final String shipmentId;

  const ShipmentDetailScreen({
    super.key,
    required this.shipmentId,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in_transit':
      case 'intransit':
      case 'shipped':
        return Colors.orange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shipmentAsync = ref.watch(watchShippingRequestProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: shipmentAsync.when(
        data: (shipment) {
          if (shipment == null) {
            return const Center(child: Text('Shipment not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Header
                Container(
                  width: double.infinity,
                  color: _getStatusColor(shipment.status).withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(shipment.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatStatus(shipment.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Shipment #${shipment.id.substring(0, 8)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (shipment.trackingNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          shipment.trackingNumber!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Route Information
                _buildSectionCard(
                  context,
                  title: 'Route',
                  content: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  shipment.departingLocation.isNotEmpty
                                      ? shipment.departingLocation
                                      : 'Not specified',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Icon(Icons.arrow_downward, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  shipment.destinationLocation.isNotEmpty
                                      ? shipment.destinationLocation
                                      : 'Not specified',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sender Information
                _buildSectionCard(
                  context,
                  title: 'Sender',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name', shipment.senderName),
                      const SizedBox(height: 12),
                      _buildInfoRow('Phone', shipment.senderPhone),
                      const SizedBox(height: 12),
                      _buildInfoRow('Email', shipment.senderEmail),
                      const SizedBox(height: 12),
                      _buildInfoRow('Address', shipment.senderAddress),
                    ],
                  ),
                ),

                // Receiver Information
                _buildSectionCard(
                  context,
                  title: 'Receiver',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name', shipment.receiverName),
                      const SizedBox(height: 12),
                      _buildInfoRow('Phone', shipment.receiverPhone),
                      const SizedBox(height: 12),
                      _buildInfoRow('Email', shipment.receiverEmail),
                      const SizedBox(height: 12),
                      _buildInfoRow('Address', shipment.receiverAddress),
                    ],
                  ),
                ),

                // Cargo Details
                _buildSectionCard(
                  context,
                  title: 'Cargo Details',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Type', shipment.freightType.toUpperCase()),
                      const SizedBox(height: 12),
                      _buildInfoRow('Priority', shipment.priority),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          'Weight', '${shipment.shipmentWeight} kg'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Dimensions',
                          '${shipment.shipmentLength}x${shipment.shipmentWidth}x${shipment.shipmentHeight} cm'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Packaging', shipment.shipmentPackaging),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          'Description', shipment.itemDescription),
                    ],
                  ),
                ),

                // Cost Information
                _buildSectionCard(
                  context,
                  title: 'Cost',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Ordered',
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(shipment.createdAt),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Estimated Cost',
                          '\$${shipment.estimatedCost.toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Actual Cost',
                          '\$${shipment.actualCost.toStringAsFixed(2)}'),
                      if (shipment.trackingNumber != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow('Tracking #', shipment.trackingNumber!),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading shipment: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
