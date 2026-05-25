import 'package:flutter/material.dart';
import '../domain/order_model.dart';

class OrderEditDrawer extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onClose;
  final Function(OrderStatus) onStatusUpdate;

  const OrderEditDrawer({
    super.key,
    required this.order,
    required this.onClose,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.id}'),
        actions: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status update section
            _buildStatusSection(),
            const SizedBox(height: 24),

            // Order items
            _buildOrderItems(),
            const SizedBox(height: 24),

            // Customer information
            _buildCustomerInfo(),
            const SizedBox(height: 24),

            // Addresses
            _buildAddresses(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: OrderStatus.values
                  .where((status) => status != OrderStatus.all)
                  .map((status) {
                    return ChoiceChip(
                      label: Text(_getStatusText(status)),
                      selected: order.status == status,
                      onSelected: (selected) {
                        if (selected) onStatusUpdate(status);
                      },
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: AssetImage(item.imagePath),
                ),
                title: Text(item.cargoDescription),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${item.cargoType}'),
                    Text('Affiliate: ${item.affiliateName}'),
                    Text('Weight: ${item.weight}kg x ${item.quantity}'),
                  ],
                ),
                trailing: Text('${item.totalWeight.toStringAsFixed(2)}kg'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(order.customerName),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(order.customerEmail),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Affiliates'),
              subtitle: Text(order.affiliateNames),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddresses() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(order.pickupAddress.formatted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(order.deliveryAddress.formatted),
                ],
              ),
            ),
          ),
        ),
      ],
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
}
