import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model for invoice reminders
class InvoiceReminder {
  final String id;
  final String invoiceId;
  final String customerId;
  final String customerEmail;
  final String customerName;
  final ReminderType type;
  final ReminderStatus status;
  final DateTime scheduledDate;
  final DateTime? sentDate;
  final String? subject;
  final String? message;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  InvoiceReminder({
    required this.id,
    required this.invoiceId,
    required this.customerId,
    required this.customerEmail,
    required this.customerName,
    required this.type,
    required this.status,
    required this.scheduledDate,
    this.sentDate,
    this.subject,
    this.message,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory InvoiceReminder.fromMap(Map<String, dynamic> map) {
    return InvoiceReminder(
      id: map['id'] as String,
      invoiceId: map['invoiceId'] as String,
      customerId: map['customerId'] as String,
      customerEmail: map['customerEmail'] as String,
      customerName: map['customerName'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.dueDate,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReminderStatus.pending,
      ),
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      sentDate: map['sentDate'] != null
          ? (map['sentDate'] as Timestamp).toDate()
          : null,
      subject: map['subject'] as String?,
      message: map['message'] as String?,
      attemptCount: map['attemptCount'] as int? ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? (map['lastAttemptAt'] as Timestamp).toDate()
          : null,
      errorMessage: map['errorMessage'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'type': type.name,
      'status': status.name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'sentDate': sentDate != null ? Timestamp.fromDate(sentDate!) : null,
      'subject': subject,
      'message': message,
      'attemptCount': attemptCount,
      'lastAttemptAt':
          lastAttemptAt != null ? Timestamp.fromDate(lastAttemptAt!) : null,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  InvoiceReminder copyWith({
    String? id,
    String? invoiceId,
    String? customerId,
    String? customerEmail,
    String? customerName,
    ReminderType? type,
    ReminderStatus? status,
    DateTime? scheduledDate,
    DateTime? sentDate,
    String? subject,
    String? message,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceReminder(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      sentDate: sentDate ?? this.sentDate,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(scheduledDate) && status == ReminderStatus.pending;
  bool get isSent => status == ReminderStatus.sent;
  bool get isFailed => status == ReminderStatus.failed;
  bool get canRetry => isFailed && attemptCount < 3;
}

enum ReminderType {
  dueDate,
  overdue,
  paymentReceived,
  paymentFailed,
  custom,
}

enum ReminderStatus {
  pending,
  sent,
  failed,
  cancelled,
}

extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.dueDate:
        return 'Due Date Reminder';
      case ReminderType.overdue:
        return 'Overdue Reminder';
      case ReminderType.paymentReceived:
        return 'Payment Received';
      case ReminderType.paymentFailed:
        return 'Payment Failed';
      case ReminderType.custom:
        return 'Custom Reminder';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.dueDate:
        return '📅';
      case ReminderType.overdue:
        return '⚠️';
      case ReminderType.paymentReceived:
        return '✅';
      case ReminderType.paymentFailed:
        return '❌';
      case ReminderType.custom:
        return '📝';
    }
  }

  String get defaultSubject {
    switch (this) {
      case ReminderType.dueDate:
        return 'Invoice Due Soon';
      case ReminderType.overdue:
        return 'Invoice Overdue';
      case ReminderType.paymentReceived:
        return 'Payment Received';
      case ReminderType.paymentFailed:
        return 'Payment Failed';
      case ReminderType.custom:
        return 'Invoice Reminder';
    }
  }

  String get defaultMessage {
    switch (this) {
      case ReminderType.dueDate:
        return 'Your invoice is due soon. Please complete the payment to avoid any late fees.';
      case ReminderType.overdue:
        return 'Your invoice is now overdue. Please complete the payment as soon as possible.';
      case ReminderType.paymentReceived:
        return 'Thank you for your payment. Your invoice has been marked as paid.';
      case ReminderType.paymentFailed:
        return 'We were unable to process your payment. Please try again or contact support.';
      case ReminderType.custom:
        return 'This is a reminder regarding your invoice.';
    }
  }
}

extension ReminderStatusExtension on ReminderStatus {
  String get displayName {
    switch (this) {
      case ReminderStatus.pending:
        return 'Pending';
      case ReminderStatus.sent:
        return 'Sent';
      case ReminderStatus.failed:
        return 'Failed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case ReminderStatus.pending:
        return '⏳';
      case ReminderStatus.sent:
        return '✅';
      case ReminderStatus.failed:
        return '❌';
      case ReminderStatus.cancelled:
        return '🚫';
    }
  }

  Color get color {
    switch (this) {
      case ReminderStatus.pending:
        return Colors.orange;
      case ReminderStatus.sent:
        return Colors.green;
      case ReminderStatus.failed:
        return Colors.red;
      case ReminderStatus.cancelled:
        return Colors.grey;
    }
  }
}