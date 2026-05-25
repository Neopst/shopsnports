import 'package:cloud_firestore/cloud_firestore.dart';

class Payout {
  final String id;
  final String payoutNumber;
  final String recipientType; // affiliate, shipper
  final String recipientId;
  final String recipientName;
  final double grossAmount;
  final double commissionAmount;
  final double taxAmount;
  final double netAmount;
  final String currency;
  final String status; // pending, approved, completed, failed, cancelled
  final String paymentMethod; // bank_transfer, paypal, mobile_money, etc.
  final String? bankAccountNumber;
  final String? bankName;
  final String? paymentReference;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? processedBy;
  final DateTime? processedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payout({
    required this.id,
    required this.payoutNumber,
    required this.recipientType,
    required this.recipientId,
    required this.recipientName,
    required this.grossAmount,
    required this.commissionAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.bankAccountNumber,
    this.bankName,
    this.paymentReference,
    required this.periodStart,
    required this.periodEnd,
    this.approvedBy,
    this.approvedAt,
    this.processedBy,
    this.processedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'].toString(),
      payoutNumber: json['payout_number'],
      recipientType: json['recipient_type'],
      recipientId: json['recipient_id'].toString(),
      recipientName: json['recipient_name'],
      grossAmount: double.parse(json['gross_amount'].toString()),
      commissionAmount: double.parse(json['commission_amount'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      netAmount: double.parse(json['net_amount'].toString()),
      currency: json['currency'] ?? 'NGN',
      status: json['status'],
      paymentMethod: json['payment_method'],
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
      paymentReference: json['payment_reference'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      processedBy: json['processed_by'],
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory Payout.fromMap(Map<String, dynamic> map) {
    return Payout(
      id: map['id'] ?? '',
      payoutNumber: map['payout_number'] ?? '',
      recipientType: map['recipient_type'] ?? '',
      recipientId: map['recipient_id'] ?? '',
      recipientName: map['recipient_name'] ?? '',
      grossAmount: (map['gross_amount'] ?? 0).toDouble(),
      commissionAmount: (map['commission_amount'] ?? 0).toDouble(),
      taxAmount: (map['tax_amount'] ?? 0).toDouble(),
      netAmount: (map['net_amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'NGN',
      status: map['status'] ?? 'pending',
      paymentMethod: map['payment_method'] ?? '',
      bankAccountNumber: map['bank_account_number'],
      bankName: map['bank_name'],
      paymentReference: map['payment_reference'],
      periodStart:
          (map['period_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (map['period_end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedBy: map['approved_by'],
      approvedAt: (map['approved_at'] as Timestamp?)?.toDate(),
      processedBy: map['processed_by'],
      processedAt: (map['processed_at'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payout_number': payoutNumber,
      'recipient_type': recipientType,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'gross_amount': grossAmount,
      'commission_amount': commissionAmount,
      'tax_amount': taxAmount,
      'net_amount': netAmount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'payment_reference': paymentReference,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'processed_by': processedBy,
      'processed_at': processedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CommissionSetting {
  final String id;
  final String entityType; // vendor, affiliate, shipper, global
  final String? entityId;
  final String commissionType; // percentage, fixed, tiered
  final double commissionValue;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionSetting({
    required this.id,
    required this.entityType,
    this.entityId,
    required this.commissionType,
    required this.commissionValue,
    this.minAmount,
    this.maxAmount,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionSetting.fromJson(Map<String, dynamic> json) {
    return CommissionSetting(
      id: json['id'].toString(),
      entityType: json['entity_type'],
      entityId: json['entity_id']?.toString(),
      commissionType: json['commission_type'],
      commissionValue: double.parse(json['commission_value'].toString()),
      minAmount: json['min_amount'] != null
          ? double.parse(json['min_amount'].toString())
          : null,
      maxAmount: json['max_amount'] != null
          ? double.parse(json['max_amount'].toString())
          : null,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'])
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'])
          : null,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory CommissionSetting.fromMap(Map<String, dynamic> map) {
    return CommissionSetting(
      id: map['id'] ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id'],
      commissionType: map['commission_type'] ?? '',
      commissionValue: (map['commission_value'] ?? 0).toDouble(),
      minAmount: map['min_amount'] != null
          ? (map['min_amount']).toDouble()
          : null,
      maxAmount: map['max_amount'] != null
          ? (map['max_amount']).toDouble()
          : null,
      effectiveFrom: (map['effective_from'] as Timestamp?)?.toDate(),
      effectiveTo: (map['effective_to'] as Timestamp?)?.toDate(),
      isActive: map['is_active'] ?? true,
      createdBy: map['created_by'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class TaxSetting {
  final String id;
  final String taxName;
  final String taxType; // vat, sales_tax, income_tax, withholding
  final double taxRate;
  final String appliesTo; // all, vendors, affiliates, shippers
  final String? country;
  final String? region;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaxSetting({
    required this.id,
    required this.taxName,
    required this.taxType,
    required this.taxRate,
    required this.appliesTo,
    this.country,
    this.region,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxSetting.fromJson(Map<String, dynamic> json) {
    return TaxSetting(
      id: json['id'].toString(),
      taxName: json['tax_name'],
      taxType: json['tax_type'],
      taxRate: double.parse(json['tax_rate'].toString()),
      appliesTo: json['applies_to'],
      country: json['country'],
      region: json['region'],
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'])
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'])
          : null,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory TaxSetting.fromMap(Map<String, dynamic> map) {
    return TaxSetting(
      id: map['id'] ?? '',
      taxName: map['tax_name'] ?? '',
      taxType: map['tax_type'] ?? '',
      taxRate: (map['tax_rate'] ?? 0).toDouble(),
      appliesTo: map['applies_to'] ?? '',
      country: map['country'],
      region: map['region'],
      effectiveFrom: (map['effective_from'] as Timestamp?)?.toDate(),
      effectiveTo: (map['effective_to'] as Timestamp?)?.toDate(),
      isActive: map['is_active'] ?? true,
      createdBy: map['created_by'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
