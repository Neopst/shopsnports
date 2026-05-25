import 'package:cloud_firestore/cloud_firestore.dart';
import 'roles_and_permissions.dart';

/// Admin User Model - For Super Admin and Sub Admin
/// Stored in Firestore collection: 'admin_users'
class AdminUser {
  final String id; // Firebase Auth UID
  final String email;
  final String displayName;
  final UserRoleType roleType; // super_admin or sub_admin
  final UserStatus status;
  final List<AdminPermission> permissions;
  final String? createdBy; // UID of super admin who created this sub-admin
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? avatarUrl;
  final String? phone;
  final String? department;
  final String? notes;

  /// For sub-admin: optional temp password requirement
  final bool requirePasswordChange;
  final DateTime? passwordChangedAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roleType,
    required this.status,
    required this.permissions,
    this.createdBy,
    required this.createdAt,
    this.lastLoginAt,
    this.avatarUrl,
    this.phone,
    this.department,
    this.notes,
    this.requirePasswordChange = false,
    this.passwordChangedAt,
  });

  /// Check if user has a specific permission
  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<AdminPermission> permissionList) {
    return permissions.any((p) => permissionList.contains(p));
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<AdminPermission> permissionList) {
    return permissionList.every((p) => permissions.contains(p));
  }

  /// Check if this is a super admin
  bool get isSuperAdmin => roleType == UserRoleType.superAdmin;

  /// Check if this is a sub admin
  bool get isSubAdmin => roleType == UserRoleType.subAdmin;

  /// Check if account is active
  bool get isActive => status == UserStatus.active;

  /// Check if account is suspended
  bool get isSuspended => status == UserStatus.suspended;

  /// Check if password needs to be changed
  bool get needsPasswordChange => requirePasswordChange;

  /// Get role display name
  String get roleDisplayName => roleType.displayName;

  /// Create from Firestore document
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser.fromMap(data, doc.id);
  }

  /// Create from Map
  factory AdminUser.fromMap(Map<String, dynamic> map, [String? id]) {
    return AdminUser(
      id: id ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      roleType: UserRoleType.values.firstWhere(
        (e) => e.name == map['roleType'],
        orElse: () => UserRoleType.subAdmin,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      permissions: (map['permissions'] as List?)
              ?.map((p) => AdminPermission.values.firstWhere(
                    (e) => e.name == p,
                    orElse: () => AdminPermission.viewDashboard,
                  ))
              .toList() ??
          [],
      createdBy: map['createdBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
      avatarUrl: map['avatarUrl'] as String?,
      phone: map['phone'] as String?,
      department: map['department'] as String?,
      notes: map['notes'] as String?,
      requirePasswordChange: map['requirePasswordChange'] as bool? ?? false,
      passwordChangedAt: (map['passwordChangedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'roleType': roleType.name,
      'status': status.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'department': department,
      'notes': notes,
      'requirePasswordChange': requirePasswordChange,
      'passwordChangedAt':
          passwordChangedAt != null ? Timestamp.fromDate(passwordChangedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRoleType? roleType,
    UserStatus? status,
    List<AdminPermission>? permissions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? avatarUrl,
    String? phone,
    String? department,
    String? notes,
    bool? requirePasswordChange,
    DateTime? passwordChangedAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      roleType: roleType ?? this.roleType,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      notes: notes ?? this.notes,
      requirePasswordChange: requirePasswordChange ?? this.requirePasswordChange,
      passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
    );
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, email: $email, role: $roleType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper to create a new sub-admin
class SubAdminCreator {
  final String superAdminId;

  SubAdminCreator({required this.superAdminId});

  /// Create a new sub-admin with default permissions
  AdminUser createSubAdmin({
    required String email,
    required String displayName,
    String? phone,
    String? department,
    String? notes,
    List<AdminPermission>? customPermissions,
  }) {
    return AdminUser(
      id: '', // Will be set after Firebase Auth creation
      email: email,
      displayName: displayName,
      roleType: UserRoleType.subAdmin,
      status: UserStatus.active,
      permissions: customPermissions ??
          DefaultPermissionSet.shippingManager.permissions,
      createdBy: superAdminId,
      createdAt: DateTime.now(),
      requirePasswordChange: true,
    );
  }

  /// Create a sub-admin with a preset permission set
  AdminUser createWithPreset({
    required String email,
    required String displayName,
    required DefaultPermissionSet preset,
    String? phone,
    String? department,
    String? notes,
  }) {
    return createSubAdmin(
      email: email,
      displayName: displayName,
      phone: phone,
      department: department,
      notes: notes,
      customPermissions: preset.permissions,
    );
  }
}