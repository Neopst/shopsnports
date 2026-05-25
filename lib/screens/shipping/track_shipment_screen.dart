import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/tracking_info.dart';
import '../../services/shipping_api_service.dart';
import '../../widgets/main_scaffold.dart';
import '../navigation_shell.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

/// Track Shipment Screen
/// Admin Dashboard compliant - allows users to track their shipments
class TrackShipmentScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String? trackingNumber;

  const TrackShipmentScreen({
    super.key,
    required this.requestId,
    this.trackingNumber,
  });

  @override
  ConsumerState<TrackShipmentScreen> createState() =>
      _TrackShipmentScreenState();
}

class _TrackShipmentScreenState extends ConsumerState<TrackShipmentScreen> {
  final _shippingService = ShippingApiService();
  TrackingInfo? _trackingInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrackingInfo();
  }

  Future<void> _loadTrackingInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracking = await _shippingService.getTracking(widget.requestId);
      setState(() {
        _trackingInfo = tracking;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'intransit':
      case 'in transit':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Track Shipment',
      currentIndex: 2,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => NavigationShell(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: _isLoading
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
                        onPressed: _loadTrackingInfo,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _trackingInfo == null
                  ? const Center(
                      child: Text('No tracking information available'))
                  : RefreshIndicator(
                      onRefresh: _loadTrackingInfo,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Tracking Header
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Tracking Number',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _trackingInfo!.trackingNumber ?? 'N/A',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  if (_trackingInfo!.carrier != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Carrier: ${_trackingInfo!.carrier}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status
                          Card(
                            color: _getStatusColor(_trackingInfo!.status.name)
                                .withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                          _trackingInfo!.status.name),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          _trackingInfo!.status.name
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: _getStatusColor(
                                                    _trackingInfo!.status.name),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Route
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildRoutePoint(
                                    icon: Icons.flight_takeoff,
                                    label: 'Origin',
                                    location: _trackingInfo!.origin,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Icon(Icons.arrow_downward, size: 20),
                                  ),
                                  _buildRoutePoint(
                                    icon: Icons.flight_land,
                                    label: 'Destination',
                                    location: _trackingInfo!.destination,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery Timeline
                          if (_trackingInfo!.estimatedDelivery != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Timeline',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Estimated Delivery'),
                                              Text(
                                                DateFormat('MMM dd, yyyy')
                                                    .format(_trackingInfo!
                                                        .estimatedDelivery!),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_trackingInfo!.actualDelivery !=
                                        null) ...[
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Delivered On'),
                                                Text(
                                                  DateFormat('MMM dd, yyyy')
                                                      .format(_trackingInfo!
                                                          .actualDelivery!),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Tracking Events
                          if (_trackingInfo!.events.isNotEmpty) ...[
                            Text(
                              'Tracking History',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            ...(_trackingInfo!.events.map((event) {
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    child: const Icon(Icons.location_on,
                                        color: Colors.white),
                                  ),
                                  title: Text(event.description),
                                  subtitle: Text(
                                    '${event.location}\n${DateFormat('MMM dd, yyyy • HH:mm').format(event.timestamp)}',
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            }).toList()),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required String label,
    required String location,
  }) {
    return Row(
      children: [
        Icon(icon, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                location,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
