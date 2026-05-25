import 'package:cloud_firestore/cloud_firestore.dart';

/// Commission record - earned by affiliates for shipping requests
class CommissionRecord {
  final String id;
  final String shippingRequestId;
  final String affiliateId;
  final double shipmentPrice;
  final double commissionRate; // e.g., 15.0 for 15%
  final double commissionAmount; // Calculated: price × rate / 100
  final String status; // pending, approved, paid
  final String? payoutId; // Link to payout if included in one
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final String? notes;

  CommissionRecord({
    required this.id,
    required this.shippingRequestId,
    required this.affiliateId,
    required this.shipmentPrice,
    required this.commissionRate,
    required this.commissionAmount,
    this.status = 'pending',
    this.payoutId,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
    this.notes,
  });

  /// Create from Firestore document
  factory CommissionRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommissionRecord(
      id: doc.id,
      shippingRequestId: data['shippingRequestId'] ?? '',
      affiliateId: data['affiliateId'] ?? '',
      shipmentPrice: (data['shipmentPrice'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 15.0,
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      payoutId: data['payoutId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shippingRequestId': shippingRequestId,
      'affiliateId': affiliateId,
      'shipmentPrice': shipmentPrice,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'status': status,
      'payoutId': payoutId,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'notes': notes,
    };
  }

  /// Get display status
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Admin Review';
      case 'approved':
        return 'Approved for Payout';
      case 'paid':
        return 'Paid';
      default:
        return status;
    }
  }

  /// Check if commission can be included in payout
  bool get canIncludeInPayout => status == 'pending' || status == 'approved';

  /// Get commission percentage display
  String get rateDisplay => '${commissionRate.toStringAsFixed(1)}%';

  /// Get amount display
  String get amountDisplay => '\$${commissionAmount.toStringAsFixed(2)}';
}
