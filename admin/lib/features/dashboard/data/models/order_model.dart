// lib/features/dashboard/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String customerId;
  final String type; // "product" or "shipping"
  final List<Map<String, dynamic>>? items; // for product orders
  final Map<String, dynamic>? shippingRequest; // for shipping orders
  final double totalAmount;
  final String status;
  final String? invoiceId;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.type,
    this.items,
    this.shippingRequest,
    required this.totalAmount,
    required this.status,
    this.invoiceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'type': type,
      'items': items,
      'shippingRequest': shippingRequest,
      'totalAmount': totalAmount,
      'status': status,
      'invoiceId': invoiceId,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      customerId: data['customerId'],
      type: data['type'],
      items: (data['items'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      shippingRequest: data['shippingRequest'] != null
          ? Map<String, dynamic>.from(data['shippingRequest'])
          : null,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'],
      invoiceId: data['invoiceId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
