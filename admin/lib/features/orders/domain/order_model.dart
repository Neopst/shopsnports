import 'package:flutter/material.dart';

enum OrderStatus { all, pending, processing, shipped, delivered, cancelled }

enum OrderType { freight, cargo, parcel }

class OrderModel {
  final String id;
  final DateTime date;
  final String customerName;
  final String customerEmail;
  final double total;
  final OrderStatus status;
  final List<ShippingItem> items;
  final Address pickupAddress;
  final Address deliveryAddress;

  const OrderModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerEmail,
    required this.total,
    required this.status,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String? ?? '',
      date: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
      customerName: map['customerName'] as String? ?? map['name'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? map['email'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ShippingItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      pickupAddress: map['pickupAddress'] != null
          ? Address.fromMap(map['pickupAddress'] as Map<String, dynamic>)
          : Address(
              street: '', city: '', state: '', zipCode: '', country: ''),
      deliveryAddress: map['deliveryAddress'] != null
          ? Address.fromMap(map['deliveryAddress'] as Map<String, dynamic>)
          : Address(
              street: '', city: '', state: '', zipCode: '', country: ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': date,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'total': total,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'pickupAddress': pickupAddress.toMap(),
      'deliveryAddress': deliveryAddress.toMap(),
    };
  }

  String get statusText {
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

  Color get statusColor {
    switch (status) {
      case OrderStatus.all:
        return Colors.grey;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String get affiliateNames {
    final affiliates = items.map((item) => item.affiliateName).toSet();
    return affiliates.join(', ');
  }
}

class ShippingItem {
  final String cargoDescription;
  final String cargoType;
  final double weight;
  final int quantity;
  final String affiliateName;
  final String imagePath;

  const ShippingItem({
    required this.cargoDescription,
    required this.cargoType,
    required this.weight,
    required this.quantity,
    required this.affiliateName,
    required this.imagePath,
  });

  double get totalWeight => weight * quantity;

  factory ShippingItem.fromMap(Map<String, dynamic> map) {
    return ShippingItem(
      cargoDescription: map['cargoDescription'] as String? ?? '',
      cargoType: map['cargoType'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      affiliateName: map['affiliateName'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cargoDescription': cargoDescription,
      'cargoType': cargoType,
      'weight': weight,
      'quantity': quantity,
      'affiliateName': affiliateName,
      'imagePath': imagePath,
    };
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  String get formatted => '$street, $city, $state $zipCode, $country';

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zipCode: map['zipCode'] as String? ?? map['zipCode'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}
