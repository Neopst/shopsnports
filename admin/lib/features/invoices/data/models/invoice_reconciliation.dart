import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice reconciliation records
class InvoiceReconciliation {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final double invoiceAmount;
  final double paidAmount;
  final double outstandingAmount;
  final ReconciliationStatus status;
  final List<PaymentRecord> payments;
  final DateTime? lastPaymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reconciledBy;
  final DateTime? reconciledAt;

  InvoiceReconciliation({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    required this.payments,
    this.lastPaymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.reconciledBy,
    this.reconciledAt,
  });

  factory InvoiceReconciliation.fromJson(Map<String, dynamic> json) {
    return InvoiceReconciliation(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
      status: ReconciliationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReconciliationStatus.pending,
      ),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastPaymentDate: json['lastPaymentDate'] != null
          ? (json['lastPaymentDate'] as Timestamp).toDate()
          : null,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      reconciledBy: json['reconciledBy'] as String?,
      reconciledAt: json['reconciledAt'] != null
          ? (json['reconciledAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'invoiceAmount': invoiceAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'status': status.name,
      'payments': payments.map((e) => e.toJson()).toList(),
      'lastPaymentDate': lastPaymentDate != null
          ? Timestamp.fromDate(lastPaymentDate!)
          : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reconciledBy': reconciledBy,
      'reconciledAt': reconciledAt != null
          ? Timestamp.fromDate(reconciledAt!)
          : null,
    };
  }

  InvoiceReconciliation copyWith({
    String? id,
    String? invoiceId,
    String? invoiceNumber,
    double? invoiceAmount,
    double? paidAmount,
    double? outstandingAmount,
    ReconciliationStatus? status,
    List<PaymentRecord>? payments,
    DateTime? lastPaymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reconciledBy,
    DateTime? reconciledAt,
  }) {
    return InvoiceReconciliation(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reconciledBy: reconciledBy ?? this.reconciledBy,
      reconciledAt: reconciledAt ?? this.reconciledAt,
    );
  }

  double get paymentPercentage =>
      invoiceAmount > 0 ? (paidAmount / invoiceAmount) * 100 : 0;

  bool get isFullyPaid => outstandingAmount <= 0.01;

  bool get isPartiallyPaid => paidAmount > 0 && !isFullyPaid;

  bool get isOverdue => status == ReconciliationStatus.overdue;
}

enum ReconciliationStatus {
  pending,
  partiallyPaid,
  fullyPaid,
  overdue,
  disputed,
  writtenOff,
}

class PaymentRecord {
  final String id;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final String? processedBy;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    this.processedBy,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.other,
      ),
      paymentDate: (json['paymentDate'] as Timestamp).toDate(),
      referenceNumber: json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      processedBy: json['processedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'method': method.name,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'referenceNumber': referenceNumber,
      'notes': notes,
      'processedBy': processedBy,
    };
  }
}

enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  check,
  paypal,
  stripe,
  other,
}