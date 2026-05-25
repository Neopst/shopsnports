import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Line item in an invoice
class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

/// Invoice model for vendor transactions
class Invoice {
  final String id;
  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? shippingRequestId; // Link to shipping request (for affiliate invoices)
  final InvoiceStatus status;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? notes;
  final Map<String, dynamic> metadata;
  final String invoiceType; // 'vendor', 'affiliate_commission', 'service_fee' (default: 'vendor')
  final double? commissionRate; // For affiliate commission invoices
  final double? commissionAmount; // For affiliate commission invoices

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.shippingRequestId,
    this.status = InvoiceStatus.draft,
    required this.lineItems,
    required this.subtotal,
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.total,
    this.currency = 'USD',
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.notes,
    this.metadata = const {},
    this.invoiceType = 'vendor',
    this.commissionRate,
    this.commissionAmount,
  });

  /// Create Invoice from Firestore document
  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice.fromMap(data, doc.id);
  }

  /// Create Invoice from Map
  factory Invoice.fromMap(Map<String, dynamic> map, [String? id]) {
    return Invoice(
      id: id ?? map['id'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      vendorId: map['vendorId'] as String? ?? '',
      vendorName: map['vendorName'] as String? ?? '',
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
      customerEmail: map['customerEmail'] as String?,
      status: map['status'] != null
          ? InvoiceStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => InvoiceStatus.draft,
            )
          : InvoiceStatus.draft,
      lineItems: map['lineItems'] != null
          ? (map['lineItems'] as List)
              .map((item) =>
                  InvoiceLineItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      issueDate: map['issueDate'] != null
          ? (map['issueDate'] as Timestamp).toDate()
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      paymentMethod: map['paymentMethod'] as String?,
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
      'invoiceNumber': invoiceNumber,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'status': status.name,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'currency': currency,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'status': status.name,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'currency': currency,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? customerName,
    String? customerEmail,
    InvoiceStatus? status,
    List<InvoiceLineItem>? lineItems,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? currency,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    String? paymentMethod,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if invoice is overdue
  bool get isOverdue {
    if (status == InvoiceStatus.paid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Get days until due (negative if overdue)
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, vendor: $vendorName, total: $total, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
