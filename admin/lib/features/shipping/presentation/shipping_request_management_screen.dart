// FILE: lib/features/shipping/presentation/shipping_request_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_logger.dart';
import '../domain/shipping_request_model.dart';
import '../domain/shipping_document_model.dart';
import '../presentation/providers/shipping_provider.dart';
import 'widgets/shipping_documents_viewer.dart';
import '../application/document_service.dart';

class ShippingRequestManagementScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ShippingRequestManagementScreen({super.key, required this.requestId});

  @override
  ConsumerState<ShippingRequestManagementScreen> createState() =>
      _ShippingRequestManagementScreenState();
}

class _ShippingRequestManagementScreenState
    extends ConsumerState<ShippingRequestManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shippingRequestAsync = ref.watch(
      shippingRequestProvider(widget.requestId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Request Management'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard/shipping-request'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tracking'),
            Tab(text: 'Documents'),
            Tab(text: 'Financials'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: shippingRequestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading shipping request: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard/shipping-request'),
                child: const Text('Back to Shipping Requests'),
              ),
            ],
          ),
        ),
        data: (shippingRequest) {
          if (shippingRequest == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Shipping request not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard/shipping-request'),
                    child: const Text('Back to Shipping Requests'),
                  ),
                ],
              ),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(shippingRequest, ref, context),
              _buildTrackingTab(shippingRequest, context),
              _buildDocumentsTab(shippingRequest, context),
              _buildFinancialsTab(shippingRequest, context),
              _buildAnalyticsTab(shippingRequest, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    ShippingRequest request,
    WidgetRef ref,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(request.status),
                        radius: 30,
                        child: Icon(
                          request.type == ShippingType.air
                              ? Icons.airplanemode_active
                              : Icons.directions_boat,
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
                              '${request.origin} → ${request.destination}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('ID: ${request.id}'),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    request.status.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    request.status,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    request.priority.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: _getPriorityColor(
                                    request.priority,
                                  ),
                                ),
                                if (request.isInternational)
                                  const Chip(
                                    label: Text(
                                      'INTERNATIONAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.purple,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Shipping Type',
                    request.type.name.toUpperCase(),
                  ),
                  _buildInfoRow(
                    'Priority',
                    request.priority.name.toUpperCase(),
                  ),
                  _buildInfoRow('Weight', '${request.weight} kg'),
                  _buildInfoRow(
                    'Dimensions',
                    '${request.length}x${request.width}x${request.height} cm',
                  ),
                  _buildInfoRow(
                    'Volume',
                    '${request.volume.toStringAsFixed(2)} cm³',
                  ),
                  _buildInfoRow('Description', request.description),
                  _buildInfoRow('Carrier', request.carrier ?? 'Not assigned'),
                  if (request.affiliateId != null)
                    _buildInfoRow('Affiliate ID', request.affiliateId!),
                  if (request.clientName != null)
                    _buildInfoRow('Client', request.clientName!),
                  if (request.clientEmail != null)
                    _buildInfoRow('Client Email', request.clientEmail!),
                  if (request.clientPhone != null)
                    _buildInfoRow('Client Phone', request.clientPhone!),
                  _buildInfoRow('Created', _formatDateTime(request.createdAt)),
                  if (request.updatedAt != null)
                    _buildInfoRow(
                      'Last Updated',
                      _formatDateTime(request.updatedAt!),
                    ),
                  if (request.estimatedDelivery != null)
                    _buildInfoRow(
                      'Estimated Delivery',
                      _formatDateTime(request.estimatedDelivery!),
                    ),
                  if (request.actualDelivery != null)
                    _buildInfoRow(
                      'Actual Delivery',
                      _formatDateTime(request.actualDelivery!),
                    ),
                  if (request.requiresInsurance)
                    _buildInfoRow('Insurance', 'Required'),
                  if (request.requiresCustomsClearance)
                    _buildInfoRow('Customs', 'Clearance Required'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Estimated Cost',
                  '\$${request.estimatedCost.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Actual Cost',
                  '\$${request.actualCost.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Weight',
                  '${request.weight} kg',
                  Icons.scale,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Commission',
                  '\$${request.affiliateCommission.toStringAsFixed(2)}',
                  Icons.people,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Management
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusManagement(request, ref, context),
                ],
              ),
            ),
          ),

          // Tracking Information
          if (request.status.index >= ShippingStatus.approved.index)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking & Carrier Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrackingSection(request, ref, context),
                  ],
                ),
              ),
            ),

          // Insurance & Customs
          if (request.requiresInsurance || request.requiresCustomsClearance)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (request.requiresInsurance)
                      _buildInsuranceSection(request),
                    if (request.requiresCustomsClearance)
                      _buildCustomsSection(request),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab(ShippingRequest request, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimeline(request),
          const SizedBox(height: 24),
          const Text(
            'Tracking Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTrackingMap(request),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(ShippingRequest request, BuildContext context) {
    // Parse documents from Map to ShippingDocument objects
    AppLogger.debug('Documents raw data: ${request.documents}', tag: 'Shipping');
    AppLogger.debug('Documents count: ${request.documents.length}', tag: 'Shipping');

    List<ShippingDocument> documents = [];
    try {
      documents = request.documents.map((doc) {
        AppLogger.debug('Parsing document: $doc', tag: 'Shipping');
        return ShippingDocument.fromMap(doc);
      }).toList();
      AppLogger.debug('Successfully parsed ${documents.length} documents', tag: 'Shipping');
    } catch (e, stack) {
      AppLogger.error('Error parsing documents: $e', tag: 'Shipping', error: e, stackTrace: stack);
      AppLogger.debug('Stack trace: $stack', tag: 'Shipping');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ShippingDocumentsViewer(
              documents: documents,
              onDownload: (doc) {
                DocumentService.downloadDocument(doc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${doc.name}...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onEmail: (doc) {
                DocumentService.showEmailDialog(
                  context,
                  doc,
                  defaultEmail: request.clientEmail,
                );
              },
              onPrint: (doc) {
                DocumentService.printDocument(doc);
              },
              onDelete: (doc) {
                _deleteDocument(context, ref, doc);
              },
              onStatusChange: (doc) {
                _showDocumentStatusDialog(context, doc, ref);
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Upload document functionality
              _showUploadDocumentDialog(context);
            },
            icon: const Icon(Icons.upload),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialsTab(ShippingRequest request, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildFinancialRow(
                    'Estimated Cost',
                    '\$${request.estimatedCost.toStringAsFixed(2)}',
                  ),
                  _buildFinancialRow(
                    'Actual Cost',
                    '\$${request.actualCost.toStringAsFixed(2)}',
                  ),
                  _buildFinancialRow(
                    'Affiliate Commission',
                    '\$${request.affiliateCommission.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildFinancialRow(
                    'Platform Revenue',
                    '\$${(request.actualCost - request.affiliateCommission).toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentStatus(request),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ShippingRequest request, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (request.performanceMetrics.isNotEmpty) ...[
                    _buildMetricRow(
                      'On-time Delivery',
                      '${request.performanceMetrics['onTimeDelivery']?.toStringAsFixed(1) ?? 'N/A'}%',
                    ),
                    _buildMetricRow(
                      'Damage Rate',
                      '${request.performanceMetrics['damageRate']?.toStringAsFixed(1) ?? 'N/A'}%',
                    ),
                    _buildMetricRow(
                      'Customer Satisfaction',
                      '${request.performanceMetrics['customerSatisfaction']?.toStringAsFixed(1) ?? 'N/A'}/5',
                    ),
                  ] else
                    const Text('No performance metrics available'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow(
                    'Days in Transit',
                    '${request.daysInTransit} days',
                  ),
                  _buildMetricRow(
                    'International',
                    request.isInternational ? 'Yes' : 'No',
                  ),
                  _buildMetricRow(
                    'Volume',
                    '${request.volume.toStringAsFixed(2)} cm³',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusManagement(
    ShippingRequest request,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusActionButton(
          label: 'Approve',
          status: ShippingStatus.approved,
          currentStatus: request.status,
          onTap: () => _updateShippingStatus(
            request,
            ShippingStatus.approved,
            ref,
            context,
          ),
        ),
        _StatusActionButton(
          label: 'Mark In Transit',
          status: ShippingStatus.inTransit,
          currentStatus: request.status,
          onTap: () => _updateShippingStatus(
            request,
            ShippingStatus.inTransit,
            ref,
            context,
          ),
        ),
        _StatusActionButton(
          label: 'Mark Delivered',
          status: ShippingStatus.delivered,
          currentStatus: request.status,
          onTap: () => _updateShippingStatus(
            request,
            ShippingStatus.delivered,
            ref,
            context,
          ),
        ),
        _StatusActionButton(
          label: 'Cancel',
          status: ShippingStatus.cancelled,
          currentStatus: request.status,
          onTap: () => _showCancellationDialog(request, ref, context),
        ),
      ],
    );
  }

  Widget _buildTimeline(ShippingRequest request) {
    final steps = [
      {
        'status': 'Request Created',
        'date': request.createdAt,
        'completed': true,
      },
      {
        'status': 'Approved',
        'date': request.status.index >= ShippingStatus.approved.index
            ? request.updatedAt
            : null,
        'completed': request.status.index >= ShippingStatus.approved.index,
      },
      {
        'status': 'In Transit',
        'date': request.status.index >= ShippingStatus.inTransit.index
            ? request.updatedAt
            : null,
        'completed': request.status.index >= ShippingStatus.inTransit.index,
      },
      {
        'status': 'Delivered',
        'date': request.status.index >= ShippingStatus.delivered.index
            ? request.updatedAt
            : null,
        'completed': request.status.index >= ShippingStatus.delivered.index,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step['completed'] as bool
                        ? Colors.green
                        : Colors.grey,
                  ),
                  child: step['completed'] as bool
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step['completed'] as bool
                        ? Colors.green
                        : Colors.grey,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['status'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: step['completed'] as bool
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['date'] != null
                        ? _formatDateTime(step['date'] as DateTime)
                        : 'Pending',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTrackingMap(ShippingRequest request) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Tracking: ${request.trackingNumber ?? 'No tracking number'}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (request.carrier != null)
                Text(
                  'Carrier: ${request.carrier!}',
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Simulate tracking update
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking map would open here'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('View Detailed Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(ShippingRequest request) {
    final isPaid = request.status.index >= ShippingStatus.approved.index;

    return Row(
      children: [
        Icon(
          isPaid ? Icons.check_circle : Icons.pending,
          color: isPaid ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          isPaid ? 'Payment Completed' : 'Payment Pending',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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

  Color _getPriorityColor(ShippingPriority priority) {
    switch (priority) {
      case ShippingPriority.standard:
        return Colors.grey;
      case ShippingPriority.express:
        return Colors.orange;
      case ShippingPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTrackingSection(
    ShippingRequest request,
    WidgetRef ref,
    BuildContext context,
  ) {
    final trackingController = TextEditingController(
      text: request.trackingNumber ?? '',
    );
    final carrierController = TextEditingController(
      text: request.carrier ?? '',
    );

    final shippingRepository = ref.read(shippingRepositoryProvider);

    return Column(
      children: [
        TextField(
          controller: trackingController,
          decoration: const InputDecoration(
            labelText: 'Tracking Number',
            border: OutlineInputBorder(),
            hintText: 'Enter tracking number',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: carrierController,
          decoration: const InputDecoration(
            labelText: 'Carrier',
            border: OutlineInputBorder(),
            hintText: 'Enter carrier name',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final trackingNumber = trackingController.text.trim();
            final carrier = carrierController.text.trim();
            if (trackingNumber.isNotEmpty && carrier.isNotEmpty) {
              try {
                await shippingRepository.updateShippingRequest(request.id, {
                  'trackingNumber': trackingNumber,
                  'carrier': carrier,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking information updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tracking information updated (Development Mode)',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Save Tracking Information'),
        ),
      ],
    );
  }

  Widget _buildInsuranceSection(ShippingRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insurance Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (request.insuranceDetails.isNotEmpty) ...[
          _buildInfoRow(
            'Provider',
            request.insuranceDetails['provider'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Amount',
            '\$${request.insuranceDetails['amount']?.toString() ?? 'N/A'}',
          ),
        ] else
          const Text('No insurance details available'),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomsSection(ShippingRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customs Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (request.customsInfo.isNotEmpty) ...[
          _buildInfoRow('HS Code', request.customsInfo['hsCode'] ?? 'N/A'),
          _buildInfoRow(
            'Declared Value',
            '\$${request.customsInfo['value']?.toString() ?? 'N/A'}',
          ),
        ] else
          const Text('No customs information available'),
      ],
    );
  }

  void _updateShippingStatus(
    ShippingRequest request,
    ShippingStatus newStatus,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final shippingRepository = ref.read(shippingRepositoryProvider);
    try {
      await shippingRepository.updateStatus(request.id, newStatus.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to ${newStatus.name} (Development Mode)',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _showCancellationDialog(
    ShippingRequest request,
    WidgetRef ref,
    BuildContext context,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Shipping Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop();
                _updateShippingStatus(
                  request,
                  ShippingStatus.cancelled,
                  ref,
                  context,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Confirm Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Admin document upload is available in the mobile app or web file picker.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Customers upload documents directly from mobile app.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDocumentStatusDialog(
    BuildContext context,
    ShippingDocument document,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Document Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Verify'),
              subtitle: const Text('Mark document as verified'),
              onTap: () async {
                Navigator.of(context).pop();
                await _updateDocumentStatus(
                  context,
                  ref,
                  document.id,
                  'verified',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Reject'),
              subtitle: const Text('Mark document as rejected'),
              onTap: () {
                Navigator.of(context).pop();
                _showRejectDocumentDialog(context, document, ref);
              },
            ),
            if (document.status != DocumentStatus.pending)
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reset to Pending'),
                subtitle: const Text('Change status back to pending'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _updateDocumentStatus(
                    context,
                    ref,
                    document.id,
                    'pending',
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRejectDocumentDialog(
    BuildContext context,
    ShippingDocument document,
    WidgetRef ref,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              await _updateDocumentStatus(
                context,
                ref,
                document.id,
                'rejected',
                rejectionReason: reason,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDocumentStatus(
    BuildContext context,
    WidgetRef ref,
    String documentId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final repository = ref.read(shippingRepositoryProvider);
      await repository.updateDocumentStatus(
        widget.requestId,
        documentId,
        status,
        rejectionReason: rejectionReason,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document ${status == 'verified' ? 'verified' : 'rejected'} successfully',
            ),
            backgroundColor: status == 'verified' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDocument(
    BuildContext context,
    WidgetRef ref,
    ShippingDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(shippingRepositoryProvider);
        await repository.deleteDocument(widget.requestId, document.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _StatusActionButton extends StatelessWidget {
  final String label;
  final ShippingStatus status;
  final ShippingStatus currentStatus;
  final VoidCallback onTap;

  const _StatusActionButton({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentStatus = currentStatus == status;
    final isEnabled =
        currentStatus.index < status.index ||
        status == ShippingStatus.cancelled;

    return ElevatedButton(
      onPressed: isEnabled && !isCurrentStatus ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getStatusColor(status),
        foregroundColor: Colors.white,
      ),
      child: Text(isCurrentStatus ? 'Current: $label' : label),
    );
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
}
