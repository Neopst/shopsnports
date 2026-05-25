import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice history/audit trail
class InvoiceHistory {
  final String id;
  final String invoiceId;
  final HistoryAction action;
  final String description;
  final Map<String, dynamic> oldValue;
  final Map<String, dynamic> newValue;
  final DateTime createdAt;
  final String performedBy;
  final String? performedByRole;
  final String? ipAddress;
  final String? userAgent;
  final bool isSystemGenerated;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final Map<String, dynamic> metadata;

  InvoiceHistory({
    required this.id,
    required this.invoiceId,
    required this.action,
    required this.description,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    required this.performedBy,
    this.performedByRole,
    this.ipAddress,
    this.userAgent,
    this.isSystemGenerated = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.metadata = const {},
  });

  factory InvoiceHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceHistory(
      id: doc.id,
      invoiceId: data['invoiceId'] as String,
      action: HistoryAction.values.firstWhere(
        (e) => e.name == data['action'],
        orElse: () => HistoryAction.created,
      ),
      description: data['description'] as String,
      oldValue: data['oldValue'] as Map<String, dynamic>? ?? {},
      newValue: data['newValue'] as Map<String, dynamic>? ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      performedBy: data['performedBy'] as String,
      performedByRole: data['performedByRole'] as String?,
      ipAddress: data['ipAddress'] as String?,
      userAgent: data['userAgent'] as String?,
      isSystemGenerated: data['isSystemGenerated'] as bool? ?? false,
      relatedEntityId: data['relatedEntityId'] as String?,
      relatedEntityType: data['relatedEntityType'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceId': invoiceId,
      'action': action.name,
      'description': description,
      'oldValue': oldValue,
      'newValue': newValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isSystemGenerated': isSystemGenerated,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'metadata': metadata,
    };
  }

  InvoiceHistory copyWith({
    String? id,
    String? invoiceId,
    HistoryAction? action,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    DateTime? createdAt,
    String? performedBy,
    String? performedByRole,
    String? ipAddress,
    String? userAgent,
    bool? isSystemGenerated,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceHistory(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      action: action ?? this.action,
      description: description ?? this.description,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      createdAt: createdAt ?? this.createdAt,
      performedBy: performedBy ?? this.performedBy,
      performedByRole: performedByRole ?? this.performedByRole,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// History action types
enum HistoryAction {
  created,
  updated,
  deleted,
  statusChanged,
  paymentReceived,
  paymentRefunded,
  reminderSent,
  noteAdded,
  noteUpdated,
  noteDeleted,
  lineItemAdded,
  lineItemUpdated,
  lineItemDeleted,
  taxUpdated,
  discountApplied,
  discountRemoved,
  templateApplied,
  exported,
  emailed,
  viewed,
  downloaded,
  disputed,
  resolved,
  writtenOff,
  reinstated,
  archived,
  unarchived,
  duplicateCreated,
  merged,
  split,
  custom,
}