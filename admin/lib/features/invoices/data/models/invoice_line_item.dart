import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single line item in an invoice
class InvoiceLineItem {
  final String id;
  final String description;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  InvoiceLineItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  factory InvoiceLineItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceLineItem.fromJson(data);
  }
}
