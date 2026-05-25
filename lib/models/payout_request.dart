import 'package:cloud_firestore/cloud_firestore.dart';

/// Payout request - manual process for paying affiliates
class PayoutRequest {
  final String id;
  final String affiliateId;
  final String affiliateName;
  final String? affiliateEmail;
  final double amount;
  final List<String> commissionIds; // Commissions included in this payout
  final String status; // pending, processing, completed, failed
  final String? bankAccountDetails;
  final String period; // e.g., "2026-02" for February 2026
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String? transactionReference; // Bank transfer ID, check number, etc
  final String? notes;
  final String? paymentMethod; // bank_transfer, check, wire, etc

  PayoutRequest({
    required this.id,
    required this.affiliateId,
    required this.affiliateName,
    this.affiliateEmail,
    required this.amount,
    required this.commissionIds,
    this.status = 'pending',
    this.bankAccountDetails,
    required this.period,
    required this.requestedAt,
    this.completedAt,
    this.transactionReference,
    this.notes,
    this.paymentMethod,
  });

  /// Create from Firestore document
  factory PayoutRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutRequest(
      id: doc.id,
      affiliateId: data['affiliateId'] ?? '',
      affiliateName: data['affiliateName'] ?? '',
      affiliateEmail: data['affiliateEmail'],
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      commissionIds: List<String>.from(data['commissionIds'] ?? []),
      status: data['status'] ?? 'pending',
      bankAccountDetails: data['bankAccountDetails'],
      period: data['period'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      transactionReference: data['transactionReference'],
      notes: data['notes'],
      paymentMethod: data['paymentMethod'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'affiliateId': affiliateId,
      'affiliateName': affiliateName,
      'affiliateEmail': affiliateEmail,
      'amount': amount,
      'commissionIds': commissionIds,
      'status': status,
      'bankAccountDetails': bankAccountDetails,
      'period': period,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'transactionReference': transactionReference,
      'notes': notes,
      'paymentMethod': paymentMethod,
    };
  }

  /// Get display status
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Awaiting Processing';
      case 'processing':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Get amount display
  String get amountDisplay => '\$${amount.toStringAsFixed(2)}';

  /// Get commission count
  int get commissionCount => commissionIds.length;

  /// Check if this payout can be changed
  bool get canModify => status == 'pending';

  /// Check if this payout can be processed
  bool get canProcess => status == 'pending' || status == 'processing';

  /// Get days since request
  int get daysSinceRequest {
    return DateTime.now().difference(requestedAt).inDays;
  }

  /// Payout is overdue if pending after 7 days
  bool get isOverdue =>
      (status == 'pending' || status == 'processing') && daysSinceRequest > 7;
}
