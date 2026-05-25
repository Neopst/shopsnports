import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsnports/core/theme/app_colors.dart';
import 'package:shopsnports/providers/shipping_providers.dart';
import 'package:shopsnports/providers/user_providers.dart';

/// Tracking Lookup Screen
/// Allows users (guests, customers, affiliates) to track shipments by tracking number
class TrackingLookupScreen extends ConsumerStatefulWidget {
  final String? trackingNumber;

  const TrackingLookupScreen({
    super.key,
    this.trackingNumber,
  });

  @override
  ConsumerState<TrackingLookupScreen> createState() =>
      _TrackingLookupScreenState();
}

class _TrackingLookupScreenState extends ConsumerState<TrackingLookupScreen> {
  late final TextEditingController _trackingController;
  String? _searchedTracking;

  @override
  void initState() {
    super.initState();
    _trackingController = TextEditingController(text: widget.trackingNumber);
    if (widget.trackingNumber != null && widget.trackingNumber!.isNotEmpty) {
      _searchedTracking = widget.trackingNumber;
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _search() {
    final input = _trackingController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracking number'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    setState(() => _searchedTracking = input);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in_transit':
      case 'intransit':
        return Colors.blue;
      case 'approved':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'in_transit':
      case 'intransit':
        return Icons.local_shipping;
      case 'approved':
        return Icons.verified;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Shipment'),
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // Search Section
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Tracking Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      hintText: 'e.g., TRK-20260227-001',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchedTracking != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _trackingController.clear();
                                setState(() => _searchedTracking = null);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Results Section
          if (_searchedTracking != null)
            SliverFillRemaining(
              child: _buildTrackingResults(
                context,
                _searchedTracking!,
                currentUser?.id,
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Enter a tracking number to get started',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingResults(
    BuildContext context,
    String trackingNumber,
    String? userId,
  ) {
    return ref.watch(trackingLookupProvider(trackingNumber)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tracking information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          data: (request) {
            if (request == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber,
                        size: 80, color: Colors.amber[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Tracking Number Not Found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please verify the tracking number and try again',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            // Check if user can view this request (guest can view any by tracking, customer can view if theirs)
            final canViewFull = userId == request.requesterId;

            return ListView(
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tracking Number',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    request.trackingNumber ?? 'N/A',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
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
                ),
                const SizedBox(height: 16),

                // Status Card
                Card(
                  color: _getStatusColor(request.status).withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(request.status),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                _formatStatus(request.status),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: _getStatusColor(request.status),
                                      fontWeight: FontWeight.bold,
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

                // Route Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipping Route',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // From
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_outlined,
                                  color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    request.departingLocation,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.arrow_downward,
                                  color: Colors.grey[400], size: 24),
                              const SizedBox(height: 8),
                              Text(
                                'In Transit',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // To
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on,
                                  color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    request.destinationLocation,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineItem(
                          context,
                          'Request Submitted',
                          DateFormat('MMM dd, yyyy • HH:mm')
                              .format(request.createdAt),
                          true,
                          Icons.check_circle,
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineItem(
                          context,
                          'Pending Review',
                          request.status == 'pending'
                              ? 'Waiting for approval'
                              : DateFormat('MMM dd, yyyy • HH:mm').format(
                                  request.updatedAt ?? request.createdAt),
                          request.status != 'pending',
                          Icons.schedule,
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineItem(
                          context,
                          'Approved & Processing',
                          request.status == 'approved'
                              ? 'Being prepared'
                              : DateFormat('MMM dd, yyyy • HH:mm').format(
                                  request.updatedAt ?? request.createdAt),
                          request.status == 'in_transit' ||
                              request.status == 'delivered',
                          Icons.verified,
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineItem(
                          context,
                          'In Transit',
                          request.status == 'in_transit'
                              ? 'On its way'
                              : 'Upcoming',
                          request.status == 'delivered',
                          Icons.local_shipping,
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineItem(
                          context,
                          'Delivered',
                          request.status == 'delivered'
                              ? DateFormat('MMM dd, yyyy • HH:mm').format(
                                  request.updatedAt ?? request.createdAt)
                              : 'Upcoming',
                          false,
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Details (only if customer viewing their own or admin viewing)
                if (canViewFull) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipment Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Item', request.itemDescription),
                          _buildDetailRow('Weight',
                              '${request.shipmentWeight.toStringAsFixed(2)} kg'),
                          _buildDetailRow('Dimensions',
                              '${request.shipmentLength.toStringAsFixed(0)}x${request.shipmentWidth.toStringAsFixed(0)}x${request.shipmentHeight.toStringAsFixed(0)} cm'),
                          _buildDetailRow('Freight Type', request.freightType),
                          _buildDetailRow(
                              'Priority',
                              request.priority[0].toUpperCase() +
                                  request.priority.substring(1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sender Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Name', request.senderName),
                          _buildDetailRow('Address', request.senderAddress),
                          _buildDetailRow('Phone', request.senderPhone),
                          _buildDetailRow('Email', request.senderEmail),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receiver Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Name', request.receiverName),
                          _buildDetailRow('Address', request.receiverAddress),
                          _buildDetailRow('Phone', request.receiverPhone),
                          _buildDetailRow('Email', request.receiverEmail),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Limited details available. Sign in to see full shipment information.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String subtitle,
    bool isCompleted,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
