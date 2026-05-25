import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model for invoice exports
class InvoiceExport {
  final String id;
  final String name;
  final ExportFormat format;
  final ExportStatus status;
  final List<String> invoiceIds;
  final int totalInvoices;
  final DateTime startDate;
  final DateTime endDate;
  final String? filePath;
  final int? fileSize;
  final String? downloadUrl;
  final DateTime? completedAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic>? filters;
  final List<String>? selectedFields;

  InvoiceExport({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    required this.invoiceIds,
    required this.totalInvoices,
    required this.startDate,
    required this.endDate,
    this.filePath,
    this.fileSize,
    this.downloadUrl,
    this.completedAt,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.filters,
    this.selectedFields,
  });

  factory InvoiceExport.fromMap(Map<String, dynamic> map) {
    return InvoiceExport(
      id: map['id'] as String,
      name: map['name'] as String,
      format: ExportFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => ExportFormat.csv,
      ),
      status: ExportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExportStatus.pending,
      ),
      invoiceIds: List<String>.from(map['invoiceIds'] as List),
      totalInvoices: map['totalInvoices'] as int,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      filePath: map['filePath'] as String?,
      fileSize: map['fileSize'] as int?,
      downloadUrl: map['downloadUrl'] as String?,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      errorMessage: map['errorMessage'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      filters: map['filters'] as Map<String, dynamic>?,
      selectedFields: map['selectedFields'] != null
          ? List<String>.from(map['selectedFields'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format.name,
      'status': status.name,
      'invoiceIds': invoiceIds,
      'totalInvoices': totalInvoices,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'filePath': filePath,
      'fileSize': fileSize,
      'downloadUrl': downloadUrl,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'filters': filters,
      'selectedFields': selectedFields,
    };
  }

  InvoiceExport copyWith({
    String? id,
    String? name,
    ExportFormat? format,
    ExportStatus? status,
    List<String>? invoiceIds,
    int? totalInvoices,
    DateTime? startDate,
    DateTime? endDate,
    String? filePath,
    int? fileSize,
    String? downloadUrl,
    DateTime? completedAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? filters,
    List<String>? selectedFields,
  }) {
    return InvoiceExport(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      status: status ?? this.status,
      invoiceIds: invoiceIds ?? this.invoiceIds,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      filters: filters ?? this.filters,
      selectedFields: selectedFields ?? this.selectedFields,
    );
  }

  bool get isPending => status == ExportStatus.pending;
  bool get isProcessing => status == ExportStatus.processing;
  bool get isCompleted => status == ExportStatus.completed;
  bool get isFailed => status == ExportStatus.failed;
  bool get canDownload => isCompleted && downloadUrl != null;
  String get formattedFileSize {
    if (fileSize == null) return 'N/A';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(2)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

enum ExportFormat {
  csv,
  excel,
  pdf,
  json,
}

enum ExportStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  String get extension {
    switch (this) {
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.json:
        return '.json';
    }
  }

  String get icon {
    switch (this) {
      case ExportFormat.csv:
        return '📊';
      case ExportFormat.excel:
        return '📈';
      case ExportFormat.pdf:
        return '📄';
      case ExportFormat.json:
        return '📋';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.json:
        return 'application/json';
    }
  }
}

extension ExportStatusExtension on ExportStatus {
  String get displayName {
    switch (this) {
      case ExportStatus.pending:
        return 'Pending';
      case ExportStatus.processing:
        return 'Processing';
      case ExportStatus.completed:
        return 'Completed';
      case ExportStatus.failed:
        return 'Failed';
      case ExportStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case ExportStatus.pending:
        return '⏳';
      case ExportStatus.processing:
        return '⚙️';
      case ExportStatus.completed:
        return '✅';
      case ExportStatus.failed:
        return '❌';
      case ExportStatus.cancelled:
        return '🚫';
    }
  }

  Color get color {
    switch (this) {
      case ExportStatus.pending:
        return Colors.orange;
      case ExportStatus.processing:
        return Colors.blue;
      case ExportStatus.completed:
        return Colors.green;
      case ExportStatus.failed:
        return Colors.red;
      case ExportStatus.cancelled:
        return Colors.grey;
    }
  }
}

/// Available fields for export
class ExportField {
  final String key;
  final String label;
  final String description;
  final bool required;

  const ExportField({
    required this.key,
    required this.label,
    required this.description,
    this.required = false,
  });

  static const List<ExportField> availableFields = [
    ExportField(
      key: 'id',
      label: 'Invoice ID',
      description: 'Unique identifier for the invoice',
      required: true,
    ),
    ExportField(
      key: 'invoiceNumber',
      label: 'Invoice Number',
      description: 'Human-readable invoice number',
      required: true,
    ),
    ExportField(
      key: 'customerName',
      label: 'Customer Name',
      description: 'Name of the customer',
    ),
    ExportField(
      key: 'customerEmail',
      label: 'Customer Email',
      description: 'Email address of the customer',
    ),
    ExportField(
      key: 'amount',
      label: 'Amount',
      description: 'Total invoice amount',
      required: true,
    ),
    ExportField(
      key: 'currency',
      label: 'Currency',
      description: 'Currency code (e.g., USD, EUR)',
    ),
    ExportField(
      key: 'status',
      label: 'Status',
      description: 'Current invoice status',
      required: true,
    ),
    ExportField(
      key: 'dueDate',
      label: 'Due Date',
      description: 'Date when payment is due',
    ),
    ExportField(
      key: 'issueDate',
      label: 'Issue Date',
      description: 'Date when invoice was issued',
    ),
    ExportField(
      key: 'paidDate',
      label: 'Paid Date',
      description: 'Date when payment was received',
    ),
    ExportField(
      key: 'paymentMethod',
      label: 'Payment Method',
      description: 'Method used for payment',
    ),
    ExportField(
      key: 'notes',
      label: 'Notes',
      description: 'Additional notes or comments',
    ),
    ExportField(
      key: 'lineItems',
      label: 'Line Items',
      description: 'Items included in the invoice',
    ),
    ExportField(
      key: 'taxAmount',
      label: 'Tax Amount',
      description: 'Total tax amount',
    ),
    ExportField(
      key: 'discountAmount',
      label: 'Discount Amount',
      description: 'Total discount amount',
    ),
    ExportField(
      key: 'shippingAmount',
      label: 'Shipping Amount',
      description: 'Shipping cost',
    ),
    ExportField(
      key: 'totalAmount',
      label: 'Total Amount',
      description: 'Final total including all charges',
    ),
  ];
}