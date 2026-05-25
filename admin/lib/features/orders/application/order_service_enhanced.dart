import 'package:flutter/foundation.dart';
import '../domain/order_model.dart';

class OrderServiceEnhanced with ChangeNotifier {
  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => _orders;

  void initializeSampleData() {
    _orders.addAll([
      OrderModel(
        id: 'ORD-001',
        date: DateTime(2024, 1, 15, 14, 30),
        customerName: 'John Smith',
        customerEmail: 'john.smith@example.com',
        total: 299.97,
        status: OrderStatus.delivered,
        items: [
          ShippingItem(
            cargoDescription: 'Electronics shipment - Mixed items',
            cargoType: 'Fragile',
            weight: 2.5,
            quantity: 1,
            affiliateName: 'Global Logistics Inc',
            imagePath: 'assets/icons/1.jpg',
          ),
          ShippingItem(
            cargoDescription: 'Accessories and cables',
            cargoType: 'Standard',
            weight: 0.5,
            quantity: 2,
            affiliateName: 'Global Logistics Inc',
            imagePath: 'assets/icons/2.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '123 Warehouse Drive',
          city: 'Los Angeles',
          state: 'CA',
          zipCode: '90001',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '456 Delivery Street',
          city: 'New York',
          state: 'NY',
          zipCode: '10001',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-002',
        date: DateTime(2024, 1, 16, 9, 15),
        customerName: 'Sarah Johnson',
        customerEmail: 'sarah.j@example.com',
        total: 149.50,
        status: OrderStatus.processing,
        items: [
          ShippingItem(
            cargoDescription: 'Software license and documentation',
            cargoType: 'Documents',
            weight: 0.2,
            quantity: 1,
            affiliateName: 'Digital Solutions Co',
            imagePath: 'assets/icons/3.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '456 Oak Avenue',
          city: 'Los Angeles',
          state: 'CA',
          zipCode: '90210',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '789 Market Street',
          city: 'San Francisco',
          state: 'CA',
          zipCode: '94102',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-003',
        date: DateTime(2024, 1, 17, 11, 0),
        customerName: 'Mike Wilson',
        customerEmail: 'mike.wilson@example.com',
        total: 450.00,
        status: OrderStatus.pending,
        items: [
          ShippingItem(
            cargoDescription: 'Heavy machinery and industrial equipment',
            cargoType: 'Heavy',
            weight: 150.0,
            quantity: 1,
            affiliateName: 'Industrial Logistics Corp',
            imagePath: 'assets/icons/4.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '789 Pine Road',
          city: 'Chicago',
          state: 'IL',
          zipCode: '60601',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '100 Industrial Way',
          city: 'Detroit',
          state: 'MI',
          zipCode: '48201',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-004',
        date: DateTime(2024, 1, 18, 16, 45),
        customerName: 'Emily Davis',
        customerEmail: 'emily.davis@example.com',
        total: 89.97,
        status: OrderStatus.shipped,
        items: [
          ShippingItem(
            cargoDescription: 'Fragile electronics and components',
            cargoType: 'Fragile',
            weight: 5.0,
            quantity: 2,
            affiliateName: 'Express Cargo Inc',
            imagePath: 'assets/icons/5.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '321 Elm Street',
          city: 'Houston',
          state: 'TX',
          zipCode: '77001',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '555 Shipping Lane',
          city: 'Austin',
          state: 'TX',
          zipCode: '73301',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-005',
        date: DateTime(2024, 1, 19, 13, 20),
        customerName: 'Robert Brown',
        customerEmail: 'robert.b@example.com',
        total: 224.97,
        status: OrderStatus.delivered,
        items: [
          ShippingItem(
            cargoDescription: 'Office equipment and furniture',
            cargoType: 'Standard',
            weight: 45.0,
            quantity: 3,
            affiliateName: 'Global Logistics Inc',
            imagePath: 'assets/icons/7.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '654 Maple Drive',
          city: 'Phoenix',
          state: 'AZ',
          zipCode: '85001',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '222 Business Center',
          city: 'Scottsdale',
          state: 'AZ',
          zipCode: '85251',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-006',
        date: DateTime(2024, 1, 20, 10, 30),
        customerName: 'Lisa Anderson',
        customerEmail: 'lisa.a@example.com',
        total: 199.99,
        status: OrderStatus.cancelled,
        items: [
          ShippingItem(
            cargoDescription: 'Consumer goods and packages',
            cargoType: 'Standard',
            weight: 12.5,
            quantity: 2,
            affiliateName: 'Premium Cargo Services',
            imagePath: 'assets/icons/10.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '987 Cedar Lane',
          city: 'Philadelphia',
          state: 'PA',
          zipCode: '19101',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '333 Commerce Drive',
          city: 'Camden',
          state: 'NJ',
          zipCode: '08101',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-007',
        date: DateTime(2024, 1, 21, 15, 10),
        customerName: 'David Miller',
        customerEmail: 'david.m@example.com',
        total: 349.98,
        status: OrderStatus.processing,
        items: [
          ShippingItem(
            cargoDescription: 'Industrial parts and components',
            cargoType: 'Heavy',
            weight: 85.0,
            quantity: 2,
            affiliateName: 'Industrial Logistics Corp',
            imagePath: 'assets/icons/11.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '147 Oak Street',
          city: 'San Antonio',
          state: 'TX',
          zipCode: '78201',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '444 Factory Road',
          city: 'New Braunfels',
          state: 'TX',
          zipCode: '78130',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-008',
        date: DateTime(2024, 1, 22, 8, 45),
        customerName: 'Jennifer Taylor',
        customerEmail: 'jennifer.t@example.com',
        total: 179.97,
        status: OrderStatus.shipped,
        items: [
          ShippingItem(
            cargoDescription: 'Electronics and accessories shipment',
            cargoType: 'Fragile',
            weight: 8.0,
            quantity: 3,
            affiliateName: 'Express Cargo Inc',
            imagePath: 'assets/icons/1.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '258 Pine Avenue',
          city: 'San Diego',
          state: 'CA',
          zipCode: '92101',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '555 West Coast Highway',
          city: 'Long Beach',
          state: 'CA',
          zipCode: '90802',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-009',
        date: DateTime(2024, 1, 23, 12, 0),
        customerName: 'Kevin Martinez',
        customerEmail: 'kevin.m@example.com',
        total: 599.99,
        status: OrderStatus.pending,
        items: [
          ShippingItem(
            cargoDescription: 'Medical equipment and supplies',
            cargoType: 'Fragile',
            weight: 25.0,
            quantity: 3,
            affiliateName: 'Medical Logistics Specialists',
            imagePath: 'assets/icons/3.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '369 Birch Boulevard',
          city: 'Dallas',
          state: 'TX',
          zipCode: '75201',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '666 Health Center Road',
          city: 'Arlington',
          state: 'TX',
          zipCode: '76010',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-010',
        date: DateTime(2024, 1, 24, 17, 30),
        customerName: 'Amanda White',
        customerEmail: 'amanda.w@example.com',
        total: 129.99,
        status: OrderStatus.delivered,
        items: [
          ShippingItem(
            cargoDescription: 'Retail merchandise and packaging',
            cargoType: 'Standard',
            weight: 15.0,
            quantity: 1,
            affiliateName: 'Global Logistics Inc',
            imagePath: 'assets/icons/6.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '741 Willow Way',
          city: 'San Jose',
          state: 'CA',
          zipCode: '95101',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '777 Retail Park',
          city: 'Sunnyvale',
          state: 'CA',
          zipCode: '94088',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-011',
        date: DateTime(2024, 1, 25, 14, 15),
        customerName: 'Christopher Lee',
        customerEmail: 'chris.lee@example.com',
        total: 199.98,
        status: OrderStatus.processing,
        items: [
          ShippingItem(
            cargoDescription: 'Audio and multimedia equipment',
            cargoType: 'Fragile',
            weight: 10.0,
            quantity: 2,
            affiliateName: 'Premium Cargo Services',
            imagePath: 'assets/icons/7.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '852 Spruce Street',
          city: 'Austin',
          state: 'TX',
          zipCode: '73301',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '888 Tech Hub',
          city: 'Round Rock',
          state: 'TX',
          zipCode: '78681',
          country: 'USA',
        ),
      ),
      OrderModel(
        id: 'ORD-012',
        date: DateTime(2024, 1, 26, 11, 45),
        customerName: 'Michelle Harris',
        customerEmail: 'michelle.h@example.com',
        total: 79.99,
        status: OrderStatus.shipped,
        items: [
          ShippingItem(
            cargoDescription: 'Power supply and accessories',
            cargoType: 'Standard',
            weight: 7.5,
            quantity: 2,
            affiliateName: 'Express Cargo Inc',
            imagePath: 'assets/icons/9.jpg',
          ),
        ],
        pickupAddress: Address(
          street: '963 Cedar Court',
          city: 'Jacksonville',
          state: 'FL',
          zipCode: '32201',
          country: 'USA',
        ),
        deliveryAddress: Address(
          street: '999 Port Authority Road',
          city: 'Jacksonville Beach',
          state: 'FL',
          zipCode: '32250',
          country: 'USA',
        ),
      ),
    ]);
    notifyListeners();
  }

  List<OrderModel> getFilteredOrders({
    OrderStatus status = OrderStatus.all,
    String searchQuery = '',
  }) {
    var filtered = _orders;

    if (status != OrderStatus.all) {
      filtered = filtered.where((order) => order.status == status).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
                order.customerName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                order.customerEmail.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                order.affiliateNames.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      _orders[index] = OrderModel(
        id: _orders[index].id,
        date: _orders[index].date,
        customerName: _orders[index].customerName,
        customerEmail: _orders[index].customerEmail,
        total: _orders[index].total,
        status: newStatus,
        items: _orders[index].items,
        pickupAddress: _orders[index].pickupAddress,
        deliveryAddress: _orders[index].deliveryAddress,
      );
      notifyListeners();
    }
  }
}
