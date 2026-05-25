import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../domain/shipping_request_simplified_model.dart';
import '../providers/shipping_requests_providers_admin.dart';

/// Admin Shipping Requests List Screen
/// Shows all shipping requests with filters, sorting, and quick actions
class AdminShippingListScreen extends ConsumerStatefulWidget {
  const AdminShippingListScreen({super.key});

  @override
  ConsumerState<AdminShippingListScreen> createState() =>
      _AdminShippingListScreenState();
}

class _AdminShippingListScreenState
    extends ConsumerState<AdminShippingListScreen> {
  String _selectedStatus = 'all';
  String _selectedFreightType = 'all';
  String _selectedCategory = 'all'; // guest, customer, affiliate
  String _sortBy = 'date_desc';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ShippingRequestStatus status) {
    switch (status) {
      case ShippingRequestStatus.delivered:
        return Colors.green;
      case ShippingRequestStatus.inTransit:
        return Colors.blue;
      case ShippingRequestStatus.approved:
        return Colors.green;
      case ShippingRequestStatus.pending:
        return Colors.orange;
      case ShippingRequestStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ShippingRequestStatus status) {
    switch (status) {
      case ShippingRequestStatus.delivered:
        return Icons.check_circle;
      case ShippingRequestStatus.inTransit:
        return Icons.local_shipping;
      case ShippingRequestStatus.approved:
        return Icons.verified;
      case ShippingRequestStatus.cancelled:
        return Icons.cancel;
      case ShippingRequestStatus.pending:
        return Icons.schedule;
    }
  }

  String _formatStatus(ShippingRequestStatus status) {
    return status.name
        .replaceAll(RegExp('([A-Z])'), ' \$1')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminAllShippingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Requests'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading requests'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(adminAllShippingRequestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          // Filter requests
          List<ShippingRequestSimplified> filtered = requests;

          if (_selectedStatus != 'all') {
            filtered = filtered
                .where((r) => r.status.name == _selectedStatus)
                .toList();
          }

          if (_selectedFreightType != 'all') {
            filtered = filtered
                .where((r) => r.freightType.name == _selectedFreightType)
                .toList();
          }
          if (_selectedCategory != 'all') {
            filtered = filtered
                .where((r) => r.category == _selectedCategory)
                .toList();
          }

          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            filtered = filtered
                .where(
                  (r) =>
                      r.senderName.toLowerCase().contains(query) ||
                      r.receiverName.toLowerCase().contains(query) ||
                      r.id.contains(query) ||
                      (r.trackingNumber?.contains(query) ?? false),
                )
                .toList();
          }

          // Sort requests
          switch (_sortBy) {
            case 'date_asc':
              filtered.sort(
                (ShippingRequestSimplified a, ShippingRequestSimplified b) =>
                    a.createdAt.compareTo(b.createdAt),
              );
              break;
            case 'weight_desc':
              filtered.sort(
                (ShippingRequestSimplified a, ShippingRequestSimplified b) =>
                    b.shipmentWeight.compareTo(a.shipmentWeight),
              );
              break;
            case 'weight_asc':
              filtered.sort(
                (ShippingRequestSimplified a, ShippingRequestSimplified b) =>
                    a.shipmentWeight.compareTo(b.shipmentWeight),
              );
              break;
            case 'date_desc':
            default:
              filtered.sort(
                (ShippingRequestSimplified a, ShippingRequestSimplified b) =>
                    b.createdAt.compareTo(a.createdAt),
              );
          }

          return Column(
            children: [
              // Filters & Search
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name, ID, or tracking number...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Status'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'approved',
                                child: Text('Approved'),
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
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedFreightType,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Freight'),
                              ),
                              DropdownMenuItem(
                                value: 'air',
                                child: Text('Air'),
                              ),
                              DropdownMenuItem(
                                value: 'sea',
                                child: Text('Sea'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFreightType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'guest',
                                child: Text('Guest'),
                              ),
                              DropdownMenuItem(
                                value: 'customer',
                                child: Text('Customer'),
                              ),
                              DropdownMenuItem(
                                value: 'affiliate',
                                child: Text('Affiliate'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'date_desc',
                                child: Text('Newest First'),
                              ),
                              DropdownMenuItem(
                                value: 'date_asc',
                                child: Text('Oldest First'),
                              ),
                              DropdownMenuItem(
                                value: 'weight_desc',
                                child: Text('Heaviest First'),
                              ),
                              DropdownMenuItem(
                                value: 'weight_asc',
                                child: Text('Lightest First'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Results count
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} request${filtered.length != 1 ? 's' : ''} found',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text('No shipping requests found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final request = filtered[index];
                          return _buildRequestCard(context, request);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ShippingRequestSimplified request,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          _showShippingDetailPopup(context, request);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + Status + Tracking
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Request #',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 6),
                            // category badge with color coding
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(request.category),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          request.id.substring(
                            0,
                            8.clamp(0, request.id.length),
                          ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(request.status),
                          size: 16,
                          color: _getStatusColor(request.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatus(request.status),
                          style: TextStyle(
                            color: _getStatusColor(request.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Shipping info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          request.departingLocation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          request.destinationLocation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Priority
              Row(
                children: [
                  Text(
                    'Priority: ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    request.priority[0].toUpperCase() +
                        request.priority.substring(1),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailChip(
                      'Sender',
                      request.senderName,
                      Icons.person,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      'Receiver',
                      request.receiverName,
                      Icons.person_add,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      'Weight',
                      '${request.shipmentWeight.toStringAsFixed(1)} kg',
                      Icons.scale,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Meta info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (request.trackingNumber != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tracking',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          request.trackingNumber!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  Chip(
                    label: Text(
                      request.freightType.name
                          .replaceAll(RegExp('([A-Z])'), ' \$1')
                          .trim(),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _showShippingDetailPopup(context, request);
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  if (request.status == ShippingRequestStatus.pending) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _quickApprove(request);
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _quickReject(request);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'customer':
        return Colors.teal;
      case 'affiliate':
        return Colors.purple;
      case 'guest':
      default:
        return Colors.grey;
    }
  }

  void _showShippingDetailPopup(
    BuildContext context,
    ShippingRequestSimplified request,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Color(0xFF0A2A66)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Shipping Request Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(request.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Request ID & Status
              _buildPopupSection('Request Information', [
                _buildPopupRow('Request ID', request.id),
                _buildPopupRow('Status', _formatStatus(request.status),
                    color: _getStatusColor(request.status)),
                _buildPopupRow(
                    'Created', DateFormat('MMM dd, yyyy HH:mm').format(request.createdAt)),
                if (request.trackingNumber != null)
                  _buildPopupRow('Tracking #', request.trackingNumber!),
                _buildPopupRow('Category', request.category.toUpperCase(),
                    color: _getCategoryColor(request.category)),
              ]),
              const SizedBox(height: 16),
              // Shipment Route
              _buildPopupSection('Shipment Route', [
                _buildPopupRow('From', request.departingLocation),
                _buildPopupRow('To', request.destinationLocation),
                _buildPopupRow('Item', request.itemDescription),
                _buildPopupRow('Priority', request.priority[0].toUpperCase() +
                    request.priority.substring(1)),
                _buildPopupRow(
                  'Freight Type',
                  request.freightType.name.replaceAll(RegExp('([A-Z])'), ' \$1').trim(),
                ),
              ]),
              const SizedBox(height: 16),
              // Shipment Details
              _buildPopupSection('Shipment Details', [
                _buildPopupRow('Weight', '${request.shipmentWeight.toStringAsFixed(1)} kg'),
                _buildPopupRow(
                  'Dimensions',
                  '${request.shipmentLength}L × ${request.shipmentWidth}W × ${request.shipmentHeight}H cm',
                ),
                _buildPopupRow('Packaging', request.shipmentPackaging),
              ]),
              const SizedBox(height: 16),
              // Sender Information
              _buildPopupSection('Sender Information', [
                _buildPopupRow('Name', request.senderName),
                _buildPopupRow('Address', request.senderAddress),
                _buildPopupRow('Phone', request.senderPhone),
                _buildPopupRow('Email', request.senderEmail),
              ]),
              const SizedBox(height: 16),
              // Receiver Information
              _buildPopupSection('Receiver Information', [
                _buildPopupRow('Name', request.receiverName),
                _buildPopupRow('Address', request.receiverAddress),
                _buildPopupRow('Phone', request.receiverPhone),
                _buildPopupRow('Email', request.receiverEmail),
              ]),
              if (request.otherInformation != null &&
                  request.otherInformation!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPopupSection('Additional Information', [
                  Text(request.otherInformation!),
                ]),
              ],
              if (request.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPopupSection(
                  'Attachments (${request.attachments.length})',
                  request.attachments
                      .map((doc) => Row(
                            children: [
                              const Icon(Icons.attach_file, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (request.status == ShippingRequestStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _quickReject(request);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _quickApprove(request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/admin/shipping/${request.id}');
            },
            child: const Text('Full Details & Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2A66),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPopupRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickApprove(ShippingRequestSimplified request) async {
    try {
      final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
      await actionsNotifier.updateStatus(request.id, 'approved');
      // Invalidate the provider to refresh the data
      ref.invalidate(adminAllShippingRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${request.id.substring(0, 8)} approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _quickReject(ShippingRequestSimplified request) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
        await actionsNotifier.rejectRequest(request.id, reasonController.text);
        // Invalidate the provider to refresh the data
        ref.invalidate(adminAllShippingRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request ${request.id.substring(0, 8)} rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
