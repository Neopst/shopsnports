// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/order_service_enhanced.dart';
import '../domain/order_model.dart';
import 'order_edit_drawer.dart';
import 'order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  OrderStatus _selectedStatus = OrderStatus.all;
  OrderModel? _selectedOrder;

  @override
  void initState() {
    super.initState();
    // Initialize sample data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderServiceProvider).initializeSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderService = ref.watch(orderServiceProvider);
    final orders = orderService.getFilteredOrders(
      status: _selectedStatus,
      searchQuery: _searchController.text,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Main list view
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildOrdersList(orders)),
                ],
              ),
            ),
          ),

          // Edit drawer (like React Admin side panel)
          if (_selectedOrder != null)
            Container(
              width: 600,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: OrderEditDrawer(
                order: _selectedOrder!,
                onClose: () => setState(() => _selectedOrder = null),
                onStatusUpdate: (newStatus) {
                  orderService.updateOrderStatus(_selectedOrder!.id, newStatus);
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Orders',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      children: OrderStatus.values.map((status) {
        return FilterChip(
          label: Text(_getStatusText(status)),
          selected: _selectedStatus == status,
          onSelected: (selected) {
            setState(() {
              _selectedStatus = selected ? status : OrderStatus.all;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return ListView(
      children: [
        // Header row
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Customer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders list
        ...orders.map((order) => _buildOrderRow(order)),
      ],
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedOrder = order),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(order.id),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_formatDate(order.date)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(order.customerName),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('\$${order.total.toStringAsFixed(2)}'),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Chip(
                  label: Text(
                    order.statusText,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: order.statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.all:
        return 'All';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
