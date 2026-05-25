// lib/features/dashboard/data/models/vendor_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String vendorId;
  final String ownerId;
  final String businessName;
  final bool approved;
  final double rating;
  final DateTime createdAt;

  VendorModel({
    required this.vendorId,
    required this.ownerId,
    required this.businessName,
    this.approved = false,
    this.rating = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'ownerId': ownerId,
      'businessName': businessName,
      'approved': approved,
      'rating': rating,
      'createdAt': createdAt,
    };
  }

  factory VendorModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorModel(
      vendorId: doc.id,
      ownerId: data['ownerId'],
      businessName: data['businessName'],
      approved: data['approved'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
