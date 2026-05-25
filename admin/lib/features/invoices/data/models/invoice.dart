import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_line_item.dart';

enum InvoiceStatus {
  draft,
  pending,
  paid,
  cancelled,
  overdue;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }
}

/// Invoice model
class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerAvatar;
  final String? customerPhone;
  final String? customerAddress;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> lineItems;
  final double taxRate; // as percentage (e.g., 10.0 for 10%)
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final double? discountAmount;
  final String? terms;
  final String? notes;

  // Email tracking
  final String accessToken; // Secure token for public invoice view
  final bool emailSent;
  final DateTime? lastEmailSentAt;
  final int emailSentCount;

  // Payment tracking
  final String? paymentMethod; // e.g., 'Bank Transfer', 'Cash', 'Card'
  final String? paymentReference; // Transaction/receipt reference
  final DateTime? paymentDate;
  final double? amountPaid;
  final String? paymentNotes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerAvatar,
    this.customerPhone,
    this.customerAddress,
    required this.invoiceDate,
    required this.dueDate,
    required this.lineItems,
    this.taxRate = 0.0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.discountAmount,
    this.terms,
    this.notes,
    required this.accessToken,
    this.emailSent = false,
    this.lastEmailSentAt,
    this.emailSentCount = 0,
    this.paymentMethod,
    this.paymentReference,
    this.paymentDate,
    this.amountPaid,
    this.paymentNotes,
  });

  // Calculate subtotal (sum of all line items)
  double get subtotal {
    return lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // Calculate tax amount
  double get taxAmount {
    return subtotal * (taxRate / 100);
  }

  // Calculate total (subtotal + tax)
  double get total {
    return subtotal + taxAmount;
  }

  // Check if invoice is overdue
  bool get isOverdue {
    return status == InvoiceStatus.pending && DateTime.now().isAfter(dueDate);
  }

  // Days until due (negative if overdue)
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerAvatar,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? lineItems,
    double? taxRate,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? accessToken,
    bool? emailSent,
    DateTime? lastEmailSentAt,
    int? emailSentCount,
    String? paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
    double? amountPaid,
    String? paymentNotes,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      lineItems: lineItems ?? this.lineItems,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      accessToken: accessToken ?? this.accessToken,
      emailSent: emailSent ?? this.emailSent,
      lastEmailSentAt: lastEmailSentAt ?? this.lastEmailSentAt,
      emailSentCount: emailSentCount ?? this.emailSentCount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentNotes: paymentNotes ?? this.paymentNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerAvatar': customerAvatar,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'taxRate': taxRate,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'accessToken': accessToken,
      'emailSent': emailSent,
      'lastEmailSentAt': lastEmailSentAt != null
          ? Timestamp.fromDate(lastEmailSentAt!)
          : null,
      'emailSentCount': emailSentCount,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
      'amountPaid': amountPaid,
      'paymentNotes': paymentNotes,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] ?? '') as String,
      invoiceNumber: (json['invoiceNumber'] ?? '') as String,
      customerId: (json['customerId'] ?? '') as String,
      customerName: (json['customerName'] ?? '') as String,
      customerEmail: (json['customerEmail'] ?? '') as String,
      customerAvatar: json['customerAvatar'] as String?,
      invoiceDate:
          (json['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate:
          (json['dueDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      lineItems:
          (json['lineItems'] as List?)
              ?.map(
                (item) =>
                    InvoiceLineItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: json['notes'] as String?,
      accessToken: json['accessToken'] as String? ?? '',
      emailSent: json['emailSent'] as bool? ?? false,
      lastEmailSentAt: (json['lastEmailSentAt'] as Timestamp?)?.toDate(),
      emailSentCount: json['emailSentCount'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentReference: json['paymentReference'] as String?,
      paymentDate: (json['paymentDate'] as Timestamp?)?.toDate(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentNotes: json['paymentNotes'] as String?,
    );
  }

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Invoice.fromJson({...data, 'id': doc.id});
  }
}
