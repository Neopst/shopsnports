import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Payout record model for tracking vendor/affiliate payouts
class PayoutRecord {
  final String id;
  final String payoutNumber; // Unique payout number (PAY-YYYYMMDD-XXXXX)
  final String recipientId; // Vendor or Affiliate ID
  final String recipientType; // 'vendor' or 'affiliate'
  final String recipientName;
  final double grossAmount; // Total amount before deductions
  final double commissionAmount; // Commission earned
  final double taxAmount; // Tax deducted
  final double netAmount; // Final amount after tax
  final double amount; // Legacy field - same as netAmount
  final PayoutStatus status;
  final String currency; // Currency code (e.g., USD, NGN)
  final String? bankAccountDetails;
  final String? transactionReference;
  final String? failureReason;
  final DateTime requestDate;
  final DateTime? processedDate;
  final DateTime? completedDate;
  final DateTime? periodStart; // Period start date
  final DateTime? periodEnd; // Period end date
  final String? processedBy; // Admin ID
  final String? notes;
  final Map<String, dynamic> metadata;

  PayoutRecord({
    required this.id,
    this.payoutNumber = '',
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    this.grossAmount = 0.0,
    this.commissionAmount = 0.0,
    this.taxAmount = 0.0,
    this.netAmount = 0.0,
    required this.amount,
    this.status = PayoutStatus.pending,
    this.currency = 'USD',
    this.bankAccountDetails,
    this.transactionReference,
    this.failureReason,
    required this.requestDate,
    this.processedDate,
    this.completedDate,
    this.periodStart,
    this.periodEnd,
    this.processedBy,
    this.notes,
    this.metadata = const {},
  });

  /// Create PayoutRecord from Firestore document
  factory PayoutRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutRecord.fromMap(data, doc.id);
  }

  /// Create PayoutRecord from Map
  factory PayoutRecord.fromMap(Map<String, dynamic> map, [String? id]) {
    return PayoutRecord(
      id: id ?? map['id'] as String? ?? '',
      payoutNumber: map['payoutNumber'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      recipientType: map['recipientType'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] != null
          ? PayoutStatusExtension.fromJson(map['status'] as String)
          : PayoutStatus.pending,
      currency: map['currency'] as String? ?? 'USD',
      bankAccountDetails: map['bankAccountDetails'] as String?,
      transactionReference: map['transactionReference'] as String?,
      failureReason: map['failureReason'] as String?,
      requestDate: map['requestDate'] != null
          ? (map['requestDate'] as Timestamp).toDate()
          : DateTime.now(),
      processedDate: map['processedDate'] != null
          ? (map['processedDate'] as Timestamp).toDate()
          : null,
      completedDate: map['completedDate'] != null
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
      periodStart: map['periodStart'] != null
          ? (map['periodStart'] as Timestamp).toDate()
          : null,
      periodEnd: map['periodEnd'] != null
          ? (map['periodEnd'] as Timestamp).toDate()
          : null,
      processedBy: map['processedBy'] as String?,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payoutNumber': payoutNumber,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'recipientName': recipientName,
      'grossAmount': grossAmount,
      'commissionAmount': commissionAmount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'amount': amount,
      'status': status.toJson(),
      'currency': currency,
      'bankAccountDetails': bankAccountDetails,
      'transactionReference': transactionReference,
      'failureReason': failureReason,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'completedDate':
          completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'periodStart': periodStart != null ? Timestamp.fromDate(periodStart!) : null,
      'periodEnd': periodEnd != null ? Timestamp.fromDate(periodEnd!) : null,
      'processedBy': processedBy,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payoutNumber': payoutNumber,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'recipientName': recipientName,
      'grossAmount': grossAmount,
      'commissionAmount': commissionAmount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'amount': amount,
      'status': status.name,
      'currency': currency,
      'bankAccountDetails': bankAccountDetails,
      'transactionReference': transactionReference,
      'failureReason': failureReason,
      'requestDate': requestDate.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'periodStart': periodStart?.toIso8601String(),
      'periodEnd': periodEnd?.toIso8601String(),
      'processedBy': processedBy,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  PayoutRecord copyWith({
    String? id,
    String? payoutNumber,
    String? recipientId,
    String? recipientType,
    String? recipientName,
    double? grossAmount,
    double? commissionAmount,
    double? taxAmount,
    double? netAmount,
    double? amount,
    PayoutStatus? status,
    String? currency,
    String? bankAccountDetails,
    String? transactionReference,
    String? failureReason,
    DateTime? requestDate,
    DateTime? processedDate,
    DateTime? completedDate,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? processedBy,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return PayoutRecord(
      id: id ?? this.id,
      payoutNumber: payoutNumber ?? this.payoutNumber,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      recipientName: recipientName ?? this.recipientName,
      grossAmount: grossAmount ?? this.grossAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      netAmount: netAmount ?? this.netAmount,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      bankAccountDetails: bankAccountDetails ?? this.bankAccountDetails,
      transactionReference: transactionReference ?? this.transactionReference,
      failureReason: failureReason ?? this.failureReason,
      requestDate: requestDate ?? this.requestDate,
      processedDate: processedDate ?? this.processedDate,
      completedDate: completedDate ?? this.completedDate,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      processedBy: processedBy ?? this.processedBy,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PayoutRecord(id: $id, recipient: $recipientName, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayoutRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
