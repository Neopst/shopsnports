import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/mock_shipment_provider.dart';
import 'package:shopsnports/services/mock_shipment_service.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import '../navigation_shell.dart';

class ShipperDashboardScreen extends ConsumerStatefulWidget {
  const ShipperDashboardScreen({super.key});

  @override
  ConsumerState<ShipperDashboardScreen> createState() =>
      _ShipperDashboardScreenState();
}

class _ShipperDashboardScreenState extends ConsumerState<ShipperDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final shipmentsAsync = ref.watch(shipmentsStreamProvider);

    return MainScaffold(
      appBarTitle: 'Shipper Dashboard',
      currentIndex: 4,
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
      body: Column(
        children: [
          // Stats Cards
          _buildStatsSection(shipmentsAsync),

          // Tabs
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: shipmentsAsync.when(
              data: (shipments) => TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableShipments(shipments, user?.id),
                  _buildActiveShipments(shipments, user?.id),
                  _buildCompletedShipments(shipments, user?.id),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading shipments: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(shipmentsStreamProvider),
                      child: const Text('Retry'),
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

  Widget _buildStatsSection(AsyncValue shipmentsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: shipmentsAsync.when(
        data: (shipments) {
          final available =
              shipments.where((s) => s['status'] == 'available').length;
          final active =
              shipments.where((s) => s['status'] == 'accepted').length;
          final completed =
              shipments.where((s) => s['status'] == 'delivered').length;
          final totalEarnings = completed * 500.0; // Mock: ₦500 per delivery

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available',
                  '$available',
                  Icons.inventory_2_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '$active',
                  Icons.local_shipping_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Earnings',
                  '₦${totalEarnings.toStringAsFixed(0)}',
                  Icons.payments_outlined,
                  Colors.green,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 100),
        error: (_, __) => const SizedBox(height: 100),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableShipments(
      List<Map<String, dynamic>> shipments, String? userId) {
    final available =
        shipments.where((s) => s['status'] == 'available').toList();

    if (available.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No available shipments',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new delivery requests',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: available.length,
      itemBuilder: (context, index) {
        final shipment = available[index];
        return _buildShipmentCard(
          shipment,
          userId,
          isAvailable: true,
        );
      },
    );
  }

  Widget _buildActiveShipments(
      List<Map<String, dynamic>> shipments, String? userId) {
    final active = shipments
        .where((s) => s['status'] == 'accepted' && s['shipperId'] == userId)
        .toList();

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active deliveries',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Claim available shipments to start earning',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final shipment = active[index];
        return _buildShipmentCard(
          shipment,
          userId,
          isActive: true,
        );
      },
    );
  }

  Widget _buildCompletedShipments(
      List<Map<String, dynamic>> shipments, String? userId) {
    final completed = shipments
        .where((s) => s['status'] == 'delivered' && s['shipperId'] == userId)
        .toList();

    if (completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No completed deliveries',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completed deliveries will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final shipment = completed[index];
        return _buildShipmentCard(
          shipment,
          userId,
          isCompleted: true,
        );
      },
    );
  }

  Widget _buildShipmentCard(
    Map<String, dynamic> shipment,
    String? userId, {
    bool isAvailable = false,
    bool isActive = false,
    bool isCompleted = false,
  }) {
    final description = shipment['description'] ?? 'No description';
    final destination = shipment['destination'] ?? 'Unknown';
    final senderName = shipment['senderName'] ?? 'Unknown sender';
    final status = shipment['status'] as String? ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isActive
                          ? Icons.local_shipping
                          : Icons.inventory_2,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? Colors.orange
                          : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: $senderName',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                const Text(
                  'Earnings: ₦500',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                if (isAvailable) _buildClaimButton(shipment, userId),
                if (isActive) _buildCompleteButton(shipment),
                if (isCompleted)
                  const Text(
                    'Delivered',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'available':
        color = Colors.blue;
        label = 'Available';
        break;
      case 'accepted':
        color = Colors.orange;
        label = 'In Progress';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildClaimButton(Map<String, dynamic> shipment, String? userId) {
    return ElevatedButton.icon(
      onPressed: () async {
        final shipperId = userId ?? 'demo-shipper';
        final messenger = ScaffoldMessenger.of(context);

        try {
          await MockShipmentService.instance.claimRequest(
            shipment['id'],
            shipperId,
          );
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Shipment claimed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to claim: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: const Icon(Icons.add_task, size: 18),
      label: const Text('Claim'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildCompleteButton(Map<String, dynamic> shipment) {
    return ElevatedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);

        try {
          await MockShipmentService.instance.completeRequest(shipment['id']);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Delivery marked as complete!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to complete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: const Icon(Icons.check_circle, size: 18),
      label: const Text('Complete'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
