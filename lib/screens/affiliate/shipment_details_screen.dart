import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/shipping_request.dart';
import '../../models/enums.dart';
import '../../providers/affiliate_shipment_providers.dart';
import '../../widgets/main_scaffold.dart';

class ShipmentDetailsScreen extends ConsumerWidget {
  final String shipmentId;

  const ShipmentDetailsScreen({
    super.key,
    required this.shipmentId,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
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
  Widget build(BuildContext context, WidgetRef ref) {
    return MainScaffold(
      appBarTitle: 'Shipment Details',
      showBackOnly: true,
      body: FutureBuilder<ShippingRequest?>(
        future: ref.read(affiliateServiceProvider).getShipment(shipmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Shipment not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final shipment = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipment header
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shipment.id,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(shipment.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(shipment.status),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _getStatusText(shipment.status),
                                style: TextStyle(
                                  color: _getStatusColor(shipment.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Created: ${_formatDate(shipment.createdAt)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Client information
                if (shipment.clientName != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Client Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Name',
                            value: shipment.clientName!,
                          ),
                          if (shipment.clientEmail != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: shipment.clientEmail!,
                            ),
                          ],
                          if (shipment.clientPhone != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: shipment.clientPhone!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Shipping details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping,
                                color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Shipping Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.arrow_upward,
                          label: 'Origin',
                          value: shipment.origin,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.arrow_downward,
                          label: 'Destination',
                          value: shipment.destination,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.inventory_2,
                          label: 'Description',
                          value: shipment.description,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.scale,
                          label: 'Weight',
                          value: '${shipment.weight} kg',
                        ),
                        if (shipment.volume > 0) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.square_foot,
                            label: 'Dimensions',
                            value:
                                '${shipment.length} × ${shipment.width} × ${shipment.height} cm',
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.flag,
                          label: 'Type',
                          value: shipment.type.name.toUpperCase(),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.speed,
                          label: 'Priority',
                          value: shipment.priority.name.toUpperCase(),
                        ),
                        if (shipment.trackingNumber != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.qr_code,
                            label: 'Tracking Number',
                            value: shipment.trackingNumber!,
                          ),
                        ],
                        if (shipment.carrier != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.business,
                            label: 'Carrier',
                            value: shipment.carrier!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Financial Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Estimated Cost',
                          value: _formatCurrency(shipment.estimatedCost),
                        ),
                        if (shipment.actualCost > 0) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Actual Cost',
                            value: _formatCurrency(shipment.actualCost),
                          ),
                        ],
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Your Commission',
                          value: _formatCurrency(shipment.affiliateCommission),
                          isBold: true,
                          valueColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery timeline
                if (shipment.estimatedDelivery != null ||
                    shipment.actualDelivery != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Timeline',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (shipment.estimatedDelivery != null) ...[
                            _InfoRow(
                              icon: Icons.access_time,
                              label: 'Estimated Delivery',
                              value: _formatDate(shipment.estimatedDelivery!),
                            ),
                          ],
                          if (shipment.actualDelivery != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.check_circle,
                              label: 'Delivered On',
                              value: _formatDate(shipment.actualDelivery!),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.hourglass_bottom,
                              label: 'Days in Transit',
                              value: '${shipment.daysInTransit} days',
                            ),
                          ],
                          if (shipment.updatedAt != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.update,
                              label: 'Last Updated',
                              value: _formatDate(shipment.updatedAt!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Special requirements
                if (shipment.requiresInsurance ||
                    shipment.requiresCustomsClearance)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Special Requirements',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (shipment.requiresInsurance)
                            Row(
                              children: [
                                Icon(Icons.verified_user,
                                    size: 18, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                const Text('Insurance Required'),
                              ],
                            ),
                          if (shipment.requiresInsurance &&
                              shipment.requiresCustomsClearance)
                            const SizedBox(height: 12),
                          if (shipment.requiresCustomsClearance)
                            Row(
                              children: [
                                Icon(Icons.public,
                                    size: 18, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                const Text('Customs Clearance Required'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
