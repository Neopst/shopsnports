import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin permission model - granular permission definitions
class AdminPermission {
  final String id;
  final String name; // "reviews.approve", "invoices.create"
  final String description;
  final String module; // "reviews", "invoices", "settings", "admin_management"
  final String
  action; // "create", "read", "update", "delete", "approve", "publish"
  final bool requiresApproval; // Some actions need secondary approval
  final bool isActive;
  final DateTime createdAt;

  AdminPermission({
    required this.id,
    required this.name,
    required this.description,
    required this.module,
    required this.action,
    required this.requiresApproval,
    required this.isActive,
    required this.createdAt,
  });

  AdminPermission copyWith({
    String? id,
    String? name,
    String? description,
    String? module,
    String? action,
    bool? requiresApproval,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AdminPermission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      module: module ?? this.module,
      action: action ?? this.action,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'module': module,
      'action': action,
      'requiresApproval': requiresApproval,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AdminPermission.fromMap(Map<String, dynamic> map, String docId) {
    return AdminPermission(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      module: map['module'] ?? '',
      action: map['action'] ?? '',
      requiresApproval: map['requiresApproval'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'AdminPermission(name: $name, module: $module, action: $action)';
}

/// Admin registration request - for creating new admins
class AdminRegistrationRequest {
  final String email;
  final String fullName;
  final String? phoneNumber;
  final AdminRoleRequest role; // Which role to assign
  final List<String> permissions; // Which specific permissions
  final bool sendInvitation; // Send email invitation
  final String? invitationMessage; // Custom message
  final DateTime createdAt;
  final String createdBy; // Super-admin who initiated
  final AdminRegistrationStatus status;
  final String? approvedBy; // Super-admin who approved
  final DateTime? approvedAt;

  AdminRegistrationRequest({
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.permissions,
    required this.sendInvitation,
    this.invitationMessage,
    required this.createdAt,
    required this.createdBy,
    required this.status,
    this.approvedBy,
    this.approvedAt,
  });

  AdminRegistrationRequest copyWith({
    String? email,
    String? fullName,
    String? phoneNumber,
    AdminRoleRequest? role,
    List<String>? permissions,
    bool? sendInvitation,
    String? invitationMessage,
    DateTime? createdAt,
    String? createdBy,
    AdminRegistrationStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return AdminRegistrationRequest(
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      sendInvitation: sendInvitation ?? this.sendInvitation,
      invitationMessage: invitationMessage ?? this.invitationMessage,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'permissions': permissions,
      'sendInvitation': sendInvitation,
      'invitationMessage': invitationMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  factory AdminRegistrationRequest.fromMap(Map<String, dynamic> map) {
    return AdminRegistrationRequest(
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      role: AdminRoleRequest.values.byName(map['role'] ?? 'admin'),
      permissions: List<String>.from(map['permissions'] ?? []),
      sendInvitation: map['sendInvitation'] ?? true,
      invitationMessage: map['invitationMessage'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      status: AdminRegistrationStatus.values.byName(map['status'] ?? 'pending'),
      approvedBy: map['approvedBy'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  String toString() =>
      'AdminRegistrationRequest(email: $email, fullName: $fullName, role: $role, status: $status)';
}

enum AdminRoleRequest { superAdmin, admin, manager }

enum AdminRegistrationStatus { pending, approved, rejected, completed, expired }
