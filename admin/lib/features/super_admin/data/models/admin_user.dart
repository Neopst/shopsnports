import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_permissions.dart';

enum AdminRole { super_admin, admin, subAdmin }

enum AdminStatus { active, disabled }

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final AdminRole role;
  final AdminStatus status;
  final AdminPermissions permissions;
  final String? createdBy; // ID of super admin who created this
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool requirePasswordChange; // Force password reset on first login
  final DateTime? expiresAt; // Account expiration date (null = no expiration)

  AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.permissions,
    this.createdBy,
    required this.createdAt,
    this.lastLogin,
    this.requirePasswordChange = false,
    this.expiresAt,
  });

  /// Check if admin is active
  bool get isActive => status == AdminStatus.active;

  /// Check if admin is disabled
  bool get isDisabled => status == AdminStatus.disabled;

  /// Check if admin is super admin
  bool get isSuperAdmin => role == AdminRole.super_admin;

  /// Check if account is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if account is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiry = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final days = expiresAt!.difference(DateTime.now()).inDays;
    return days >= 0 ? days : 0;
  }

  /// Format last login for display
  String? get lastLoginFormatted {
    if (lastLogin == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return lastLogin!.toString().split(' ')[0];
    }
  }

  /// From Firestore
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser.fromMap({...data, 'id': doc.id});
  }

  /// From JSON
  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => AdminRole.admin,
      ),
      status: AdminStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdminStatus.active,
      ),
      permissions: AdminPermissions.fromMap(
        map['permissions'] as Map<String, dynamic>? ?? {},
      ),
      createdBy: map['createdBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      requirePasswordChange: map['requirePasswordChange'] as bool? ?? false,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  /// To Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'permissions': permissions.toMap()['permissions'],
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'requirePasswordChange': requirePasswordChange,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'permissions': permissions.toJson()['permissions'],
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'requirePasswordChange': requirePasswordChange,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  /// Copy with updates
  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    AdminRole? role,
    AdminStatus? status,
    AdminPermissions? permissions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? requirePasswordChange,
    DateTime? expiresAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      requirePasswordChange:
          requirePasswordChange ?? this.requirePasswordChange,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, email: $email, displayName: $displayName, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
