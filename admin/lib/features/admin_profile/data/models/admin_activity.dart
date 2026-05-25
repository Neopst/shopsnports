import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin activity model - audit trail for all admin actions
class AdminActivity {
  final String id;
  final String adminId; // Admin who performed action
  final String adminEmail; // Admin email for quick reference
  final String
  action; // "created_review", "approved_invoice", "updated_product"
  final String
  resourceType; // "Review", "Invoice", "Product", "AdminUser", "Settings"
  final String? resourceId;
  final String resourceDisplayName; // For quick understanding
  final String
  actionCategory; // "create", "read", "update", "delete", "approve", "manage"
  final Map<String, dynamic>? changes; // Before/after values
  final String? notes; // Optional notes
  final String ipAddress;
  final String userAgent;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;

  AdminActivity({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.resourceType,
    this.resourceId,
    required this.resourceDisplayName,
    required this.actionCategory,
    this.changes,
    this.notes,
    required this.ipAddress,
    required this.userAgent,
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });

  AdminActivity copyWith({
    String? id,
    String? adminId,
    String? adminEmail,
    String? action,
    String? resourceType,
    String? resourceId,
    String? resourceDisplayName,
    String? actionCategory,
    Map<String, dynamic>? changes,
    String? notes,
    String? ipAddress,
    String? userAgent,
    bool? success,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return AdminActivity(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      adminEmail: adminEmail ?? this.adminEmail,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      resourceDisplayName: resourceDisplayName ?? this.resourceDisplayName,
      actionCategory: actionCategory ?? this.actionCategory,
      changes: changes ?? this.changes,
      notes: notes ?? this.notes,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'resourceDisplayName': resourceDisplayName,
      'actionCategory': actionCategory,
      'changes': changes,
      'notes': notes,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'success': success,
      'errorMessage': errorMessage,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AdminActivity.fromMap(Map<String, dynamic> map, String docId) {
    return AdminActivity(
      id: docId,
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      action: map['action'] ?? '',
      resourceType: map['resourceType'] ?? '',
      resourceId: map['resourceId'],
      resourceDisplayName: map['resourceDisplayName'] ?? '',
      actionCategory: map['actionCategory'] ?? '',
      changes: map['changes'] as Map<String, dynamic>?,
      notes: map['notes'],
      ipAddress: map['ipAddress'] ?? '',
      userAgent: map['userAgent'] ?? '',
      success: map['success'] ?? false,
      errorMessage: map['errorMessage'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() =>
      'AdminActivity(action: $action, resource: $resourceType, success: $success, timestamp: $timestamp)';
}
