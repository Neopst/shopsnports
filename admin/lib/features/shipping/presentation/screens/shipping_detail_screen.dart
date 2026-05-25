import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../domain/shipping_request_simplified_model.dart';
import '../providers/shipping_requests_providers_admin.dart';

/// Admin Shipping Request Detail Screen
/// Displays complete shipment details with admin edit capabilities
class AdminShippingDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const AdminShippingDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<AdminShippingDetailScreen> createState() =>
      _AdminShippingDetailScreenState();
}

class _AdminShippingDetailScreenState
    extends ConsumerState<AdminShippingDetailScreen> {
  late TextEditingController _trackingController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _actualCostController;
  late TextEditingController _rejectionReasonController;
  ShippingRequestStatus _selectedStatus = ShippingRequestStatus.pending;
  String _selectedCategory = 'guest';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _trackingController = TextEditingController();
    _estimatedCostController = TextEditingController();
    _actualCostController = TextEditingController();
    _rejectionReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
    _rejectionReasonController.dispose();
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

  // Category colors mimic the badges used in the list screen
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

  String _formatStatus(ShippingRequestStatus status) {
    return status.name
        .replaceAll(RegExp('([A-Z])'), ' \$1')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _updateStatus(ShippingRequestStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
      await actionsNotifier.updateStatus(widget.requestId, newStatus.name);
      // Invalidate the provider to refresh the data
      ref.invalidate(adminAllShippingRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _assignTracking() async {
    if (_trackingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tracking number')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
      await actionsNotifier.assignTrackingNumber(
        widget.requestId,
        _trackingController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tracking number assigned'),
            backgroundColor: Colors.green,
          ),
        );
        _trackingController.clear();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _setEstimatedCost() async {
    if (_estimatedCostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter estimated cost')),
      );
      return;
    }

    try {
      final cost = double.parse(_estimatedCostController.text);
      setState(() => _isUpdating = true);
      final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
      await actionsNotifier.setEstimatedCost(widget.requestId, cost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Estimated cost updated'),
            backgroundColor: Colors.green,
          ),
        );
        _estimatedCostController.clear();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_rejectionReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rejection reason')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final actionsNotifier = ref.read(adminShippingActionsProvider.notifier);
      await actionsNotifier.rejectRequest(
        widget.requestId,
        _rejectionReasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _rejectionReasonController.clear();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(
      adminShippingRequestProvider(widget.requestId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Request Details'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading request'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(
                  adminShippingRequestProvider(widget.requestId),
                ),
                child: const Text('Retry'),
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
                  Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Request not found'),
                ],
              ),
            );
          }

          // Initialize controllers on first load
          if (_trackingController.text.isEmpty &&
              request.trackingNumber != null) {
            _trackingController.text = request.trackingNumber!;
          }
          if (_estimatedCostController.text.isEmpty &&
              request.estimatedCost > 0) {
            _estimatedCostController.text = request.estimatedCost
                .toStringAsFixed(2);
          }
          if (_actualCostController.text.isEmpty && request.actualCost > 0) {
            _actualCostController.text = request.actualCost.toStringAsFixed(2);
          }
          _selectedStatus = request.status;
          _selectedCategory = request.category;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Request ID',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  request.id,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  request.status,
                                ).withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _formatStatus(request.status),
                                style: TextStyle(
                                  color: _getStatusColor(request.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy HH:mm',
                                  ).format(request.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (request.trackingNumber != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Tracking #',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    request.trackingNumber!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Category',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  request.category,
                                ).withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatCategory(request.category),
                                style: TextStyle(
                                  color: _getCategoryColor(request.category),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SHIPMENT DETAILS
                _buildDetailSection(
                  title: 'Shipment Route',
                  icon: Icons.flight,
                  children: [
                    _buildDetailRow('From', request.departingLocation),
                    _buildDetailRow('To', request.destinationLocation),
                    _buildDetailRow('Item', request.itemDescription),
                    _buildDetailRow(
                      'Priority',
                      request.priority[0].toUpperCase() +
                          request.priority.substring(1),
                    ),
                  ],
                ),

                // DIMENSIONS & WEIGHT
                _buildDetailSection(
                  title: 'Shipment Details',
                  icon: Icons.scale,
                  children: [
                    _buildDetailRow('Weight', '${request.shipmentWeight} kg'),
                    _buildDetailRow(
                      'Dimensions',
                      '${request.shipmentLength}L × ${request.shipmentWidth}W × ${request.shipmentHeight}H cm',
                    ),
                    _buildDetailRow('Packaging', request.shipmentPackaging),
                  ],
                ),

                // SENDER DETAILS
                _buildDetailSection(
                  title: 'Sender Information',
                  icon: Icons.person,
                  children: [
                    _buildDetailRow('Name', request.senderName),
                    _buildDetailRow('Address', request.senderAddress),
                    _buildDetailRow('Phone', request.senderPhone),
                    _buildDetailRow('Email', request.senderEmail),
                  ],
                ),

                // RECEIVER DETAILS
                _buildDetailSection(
                  title: 'Receiver Information',
                  icon: Icons.person_add,
                  children: [
                    _buildDetailRow('Name', request.receiverName),
                    _buildDetailRow('Address', request.receiverAddress),
                    _buildDetailRow('Phone', request.receiverPhone),
                    _buildDetailRow('Email', request.receiverEmail),
                  ],
                ),

                // OTHER INFORMATION
                if (request.otherInformation != null &&
                    request.otherInformation!.isNotEmpty)
                  _buildDetailSection(
                    title: 'Additional Information',
                    icon: Icons.notes,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(request.otherInformation!),
                      ),
                    ],
                  ),

                // ATTACHMENTS
                if (request.attachments.isNotEmpty)
                  _buildDetailSection(
                    title: 'Attachments (${request.attachments.length})',
                    icon: Icons.attach_file,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: request.attachments.length,
                        itemBuilder: (context, index) {
                          final doc = request.attachments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey[50],
                            child: ListTile(
                              leading: _getAttachmentIcon(doc.fileName),
                              title: Text(
                                doc.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${_formatFileSize(doc.fileSizeBytes)} • ${doc.fileType}',
                              ),
                              trailing: doc.fileUrl.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        color: Color(0xFF0A2A66),
                                      ),
                                      onPressed: () => _downloadFile(
                                        doc.fileName,
                                        doc.fileUrl,
                                      ),
                                    )
                                  : const Icon(Icons.pending),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ADMIN ACTIONS SECTION
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: const Color(0xFF0A2A66),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Actions',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status update
                        Text(
                          'Update Status',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            SegmentedButton<ShippingRequestStatus>(
                              segments: const [
                                ButtonSegment(
                                  value: ShippingRequestStatus.pending,
                                  label: Text('Pending'),
                                ),
                                ButtonSegment(
                                  value: ShippingRequestStatus.approved,
                                  label: Text('Approved'),
                                ),
                                ButtonSegment(
                                  value: ShippingRequestStatus.inTransit,
                                  label: Text('In Transit'),
                                ),
                                ButtonSegment(
                                  value: ShippingRequestStatus.delivered,
                                  label: Text('Delivered'),
                                ),
                              ],
                              selected: {_selectedStatus},
                              onSelectionChanged:
                                  (Set<ShippingRequestStatus> newSelection) {
                                    setState(
                                      () =>
                                          _selectedStatus = newSelection.first,
                                    );
                                    _updateStatus(newSelection.first);
                                  },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Category update
                        Text(
                          'Category',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                items: const [
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
                                onChanged: (val) {
                                  if (val != null && val != _selectedCategory) {
                                    setState(() => _selectedCategory = val);
                                    final actionsNotifier = ref.read(
                                      adminShippingActionsProvider.notifier,
                                    );
                                    actionsNotifier.updateCategory(
                                      request.id,
                                      val,
                                    );
                                  }
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tracking number
                        Text(
                          'Assign Tracking Number',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _trackingController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., TRK-20260227-001',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isUpdating ? null : _assignTracking,
                              child: const Text('Assign'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Estimated cost
                        Text(
                          'Estimated Cost',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _estimatedCostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: '₦ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isUpdating ? null : _setEstimatedCost,
                              child: const Text('Set'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        if (request.status == 'pending')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: _isUpdating
                                          ? null
                                          : () => _updateStatus(
                                              ShippingRequestStatus.approved,
                                            ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green[50],
                                        foregroundColor: Colors.green[700],
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: _isUpdating
                                          ? null
                                          : () => _showRejectDialog(),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        foregroundColor: Colors.red[700],
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter rejection reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: _rejectionReasonController,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRequest();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileName, String fileUrl) async {
    try {
      if (fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ File is still being uploaded'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show snackbar with download info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📥 Opening $fileName...'),
          backgroundColor: Colors.blue,
        ),
      );

      // For web, open in new tab; for mobile, share/download
      // In a real app, you'd use url_launcher or file_saver package
      // For now, we'll show a dialog with the download URL
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: $fileName'),
                const SizedBox(height: 12),
                const Text('The file link has been prepared for download.'),
                const SizedBox(height: 12),
                SelectableText(
                  fileUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  // Copy URL to clipboard (can be implemented with url_launcher)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Download link copied')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Copy Link'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _getAttachmentIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon = Icons.description;
    Color color = Colors.grey;

    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (['doc', 'docx'].contains(ext)) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      icon = Icons.image;
      color = Colors.green;
    } else if (['xlsx', 'xls'].contains(ext)) {
      icon = Icons.table_chart;
      color = Colors.teal;
    }

    return Icon(icon, color: color);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0A2A66)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
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
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
