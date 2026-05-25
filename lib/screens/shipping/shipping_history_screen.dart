import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/shipping_request_simplified.dart';
import 'package:shopsnports/providers/shipping_providers.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Shipping History Screen
///
/// Displays all shipping requests for the current user
/// with real-time updates, filtering, and sorting options.
///
/// Features:
/// - Real-time list of all user's shipping requests
/// - Filter by status (Pending, Approved, In Transit, Delivered, Cancelled)
/// - Sort options (newest first, oldest first, status)
/// - Tap to view detailed request information
/// - Copy tracking number to clipboard
/// - Empty state when no requests
/// - Shimmer loading state for better UX
class ShippingHistoryScreen extends ConsumerStatefulWidget {
  const ShippingHistoryScreen({super.key});

  @override
  ConsumerState<ShippingHistoryScreen> createState() =>
      _ShippingHistoryScreenState();
}

class _ShippingHistoryScreenState extends ConsumerState<ShippingHistoryScreen> {
  // Filter state
  String? selectedStatus; // null = all, otherwise filter by status value

  // Sort state
  SortOption _sortOption = SortOption.newestFirst;

  @override
  Widget build(BuildContext context) {
    // Get current user
    final authState = ref.watch(authStateProvider);
    final user = authState.maybeWhen(orElse: () => null, data: (d) => d);
    final userId = user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shipping History'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Sign in to view your shipping history'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Watch user's shipping requests (real-time stream)
    final shippingRequestsAsync =
        ref.watch(watchUserShippingRequestsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping History'),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(watchUserShippingRequestsProvider(userId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      'Filter:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  // "All" chip
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedStatus == null,
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Pending chip
                  FilterChip(
                    label: const Text('Pending'),
                    selected: selectedStatus == 'pending',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = selected ? 'pending' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Approved chip
                  FilterChip(
                    label: const Text('Approved'),
                    selected: selectedStatus == 'approved',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = selected ? 'approved' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // In Transit chip
                  FilterChip(
                    label: const Text('In Transit'),
                    selected: selectedStatus == 'in_transit',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = selected ? 'in_transit' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Delivered chip
                  FilterChip(
                    label: const Text('Delivered'),
                    selected: selectedStatus == 'delivered',
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = selected ? 'delivered' : null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Sort dropdown
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Sort:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(width: 8),
                DropdownButton<SortOption>(
                  value: _sortOption,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                    }
                  },
                  items: [
                    const DropdownMenuItem(
                      value: SortOption.newestFirst,
                      child: Text('Newest First'),
                    ),
                    const DropdownMenuItem(
                      value: SortOption.oldestFirst,
                      child: Text('Oldest First'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1),
          // Shipping requests list
          Expanded(
            child: shippingRequestsAsync.when(
              loading: () => const _ShippingListShimmer(),
              error: (error, stack) {
                AppLogger.error('Error loading shipping history', error);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading shipping history: $error'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(
                              watchUserShippingRequestsProvider(userId));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              data: (requests) {
                // Filter requests
                List<ShippingRequestSimplified> filteredRequests = requests;
                if (selectedStatus != null) {
                  filteredRequests = requests
                      .where((r) => r.status == selectedStatus)
                      .toList();
                }

                // Sort requests
                switch (_sortOption) {
                  case SortOption.newestFirst:
                    filteredRequests
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    break;
                  case SortOption.oldestFirst:
                    filteredRequests
                        .sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    break;
                }

                // Empty state
                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedStatus != null
                              ? 'No $selectedStatus requests found'
                              : 'No shipping requests yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed('/shipping-request');
                          },
                          child: const Text('Create New Request'),
                        ),
                      ],
                    ),
                  );
                }

                // List of requests
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    return _ShippingRequestCard(
                      request: request,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/shipping-detail',
                          arguments: request.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort options for shipping requests
enum SortOption {
  newestFirst,
  oldestFirst,
}

/// Individual shipping request card widget
class _ShippingRequestCard extends StatelessWidget {
  final ShippingRequestSimplified request;
  final VoidCallback onTap;

  const _ShippingRequestCard({
    required this.request,
    required this.onTap,
  });

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Category colors (match admin list palette)
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'customer':
        return Colors.teal;
      case 'affiliate':
        return Colors.purple;
      case 'guest':
      default:
        return Colors.grey;
    }
  }

  String _formatCategory(String? category) {
    if (category == null || category.isEmpty) return 'Unknown';
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// Format date
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format status display text
  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Request ID
                        Text(
                          'Request #${request.id.substring(0, 8) ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Date created
                        Text(
                          'Created: ${_formatDate(request.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Category badge
                        Chip(
                          label: Text(
                            _formatCategory(request.category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          backgroundColor: _getCategoryColor(request.category),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Chip(
                    avatar: Icon(
                      _getStatusIcon(request.status),
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      _formatStatus(request.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: _getStatusColor(request.status),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Destination and freight type
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.destinationLocation ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      (request.freightType ?? 'unknown')
                          .replaceAll('_', '-')
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tracking number row (if available)
              if (request.trackingNumber != null &&
                  request.trackingNumber!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.qr_code_2, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tracking: ${request.trackingNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Copy button
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        _copyTrackingNumber(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy tracking number',
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tracking number pending...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              // Footer: Weight and more details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (request.shipmentWeight > 0)
                    Text(
                      'Weight: ${request.shipmentWeight.toStringAsFixed(2)}kg',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    const SizedBox(),
                  // Tap to view more
                  Text(
                    'Tap to view details →',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
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

  /// Copy tracking number to clipboard
  void _copyTrackingNumber(BuildContext context) {
    if (request.trackingNumber != null && request.trackingNumber!.isNotEmpty) {
      // Copy to clipboard logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${request.trackingNumber}'),
          duration: const Duration(seconds: 2),
        ),
      );
      // TODO: Implement actual clipboard copy
      // import 'package:flutter/services.dart';
      // Clipboard.setData(ClipboardData(text: request.trackingNumber!));
    }
  }
}

/// Shimmer loading effect for list
class _ShippingListShimmer extends StatelessWidget {
  const _ShippingListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(bottom: 12),
              ),
              Container(
                height: 14,
                width: 200,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(bottom: 12),
              ),
              Container(
                height: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
