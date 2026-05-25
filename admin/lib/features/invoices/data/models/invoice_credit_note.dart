import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice credit notes
class InvoiceCreditNote {
  final String id;
  final String invoiceId;
  final String creditNoteNumber;
  final String? customerId;
  final String? orderId;
  final double totalAmount;
  final String currency;
  final CreditNoteReason reason;
  final String? description;
  final CreditNoteStatus status;
  final List<CreditNoteLineItem> lineItems;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? appliedDate;
  final String? appliedToInvoiceId;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  InvoiceCreditNote({
    required this.id,
    required this.invoiceId,
    required this.creditNoteNumber,
    this.customerId,
    this.orderId,
    required this.totalAmount,
    required this.currency,
    required this.reason,
    this.description,
    required this.status,
    this.lineItems = const [],
    required this.issueDate,
    this.dueDate,
    this.appliedDate,
    this.appliedToInvoiceId,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory InvoiceCreditNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceCreditNote(
      id: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      creditNoteNumber: data['creditNoteNumber'] ?? '',
      customerId: data['customerId'],
      orderId: data['orderId'],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      reason: CreditNoteReason.fromString(data['reason'] ?? 'refund'),
      description: data['description'],
      status: CreditNoteStatus.fromString(data['status'] ?? 'draft'),
      lineItems: data['lineItems'] != null
          ? (data['lineItems'] as List)
              .map((item) => CreditNoteLineItem.fromMap(item))
          .toList()
          : [],
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      appliedDate: data['appliedDate'] != null
          ? (data['appliedDate'] as Timestamp).toDate()
          : null,
      appliedToInvoiceId: data['appliedToInvoiceId'],
      createdBy: data['createdBy'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceId': invoiceId,
      'creditNoteNumber': creditNoteNumber,
      'customerId': customerId,
      'orderId': orderId,
      'totalAmount': totalAmount,
      'currency': currency,
      'reason': reason.value,
      'description': description,
      'status': status.value,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'appliedDate': appliedDate != null ? Timestamp.fromDate(appliedDate!) : null,
      'appliedToInvoiceId': appliedToInvoiceId,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  bool get isDraft => status == CreditNoteStatus.draft;
  bool get isPending => status == CreditNoteStatus.pending;
  bool get isApproved => status == CreditNoteStatus.approved;
  bool get isApplied => status == CreditNoteStatus.applied;
  bool get isVoided => status == CreditNoteStatus.voided;

  bool get canBeApplied => isApproved && !isApplied && !isVoided;
  bool get canBeVoided => !isVoided;

  double get remainingAmount {
    if (isApplied) return 0;
    return totalAmount;
  }

  InvoiceCreditNote copyWith({
    String? id,
    String? invoiceId,
    String? creditNoteNumber,
    String? customerId,
    String? orderId,
    double? totalAmount,
    String? currency,
    CreditNoteReason? reason,
    String? description,
    CreditNoteStatus? status,
    List<CreditNoteLineItem>? lineItems,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? appliedDate,
    String? appliedToInvoiceId,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceCreditNote(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      appliedDate: appliedDate ?? this.appliedDate,
      appliedToInvoiceId: appliedToInvoiceId ?? this.appliedToInvoiceId,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CreditNoteLineItem {
  final String id;
  final String? productId;
  final String? productName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? description;
  final Map<String, dynamic>? metadata;

  CreditNoteLineItem({
    required this.id,
    this.productId,
    this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.description,
    this.metadata,
  });

  factory CreditNoteLineItem.fromMap(Map<String, dynamic> data) {
    return CreditNoteLineItem(
      id: data['id'] ?? '',
      productId: data['productId'],
      productName: data['productName'],
      sku: data['sku'],
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      description: data['description'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'description': description,
      'metadata': metadata,
    };
  }
}

enum CreditNoteReason {
  refund('refund'),
  productReturn('return'),
  discount('discount'),
  priceAdjustment('priceAdjustment'),
  damagedGoods('damagedGoods'),
  wrongItem('wrongItem'),
  lateDelivery('lateDelivery'),
  customerService('customerService'),
  other('other');

  final String value;
  const CreditNoteReason(this.value);

  static CreditNoteReason fromString(String value) {
    return CreditNoteReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CreditNoteReason.refund,
    );
  }
}

enum CreditNoteStatus {
  draft('draft'),
  pending('pending'),
  approved('approved'),
  applied('applied'),
  voided('voided');

  final String value;
  const CreditNoteStatus(this.value);

  static CreditNoteStatus fromString(String value) {
    return CreditNoteStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CreditNoteStatus.draft,
    );
  }
}