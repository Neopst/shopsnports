import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole { superAdmin, admin, manager }

enum AdminStatus { active, inactive, suspended, pendingApproval }

/// Admin user model - admin account management
class AdminUser {
  final String id; // Firebase UID
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final AdminRole role;
  final List<String> permissions; // Granular permissions
  final AdminStatus status;
  final DateTime createdAt;
  final String createdBy; // Super-admin who created
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? lastLogin;
  final DateTime? lastPasswordChange;
  final bool twoFactorEnabled;
  final String? twoFactorPhone;
  final bool isEmailVerified;
  final int loginAttempts;
  final DateTime? lockedUntil;

  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.permissions,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.lastLogin,
    this.lastPasswordChange,
    required this.twoFactorEnabled,
    this.twoFactorPhone,
    required this.isEmailVerified,
    required this.loginAttempts,
    this.lockedUntil,
  });

  bool get isLocked =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  bool get canLogin => status == AdminStatus.active && !isLocked;

  AdminUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    AdminRole? role,
    List<String>? permissions,
    AdminStatus? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? lastLogin,
    DateTime? lastPasswordChange,
    bool? twoFactorEnabled,
    String? twoFactorPhone,
    bool? isEmailVerified,
    int? loginAttempts,
    DateTime? lockedUntil,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      lastLogin: lastLogin ?? this.lastLogin,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorPhone: twoFactorPhone ?? this.twoFactorPhone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'permissions': permissions,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'lastPasswordChange': lastPasswordChange != null
          ? Timestamp.fromDate(lastPasswordChange!)
          : null,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorPhone': twoFactorPhone,
      'isEmailVerified': isEmailVerified,
      'loginAttempts': loginAttempts,
      'lockedUntil': lockedUntil != null
          ? Timestamp.fromDate(lockedUntil!)
          : null,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map, String docId) {
    return AdminUser(
      id: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      role: AdminRole.values.byName(map['role'] ?? 'admin'),
      permissions: List<String>.from(map['permissions'] ?? []),
      status: AdminStatus.values.byName(map['status'] ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? 'system',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? 'system',
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      lastPasswordChange: (map['lastPasswordChange'] as Timestamp?)?.toDate(),
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      twoFactorPhone: map['twoFactorPhone'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      loginAttempts: map['loginAttempts'] ?? 0,
      lockedUntil: (map['lockedUntil'] as Timestamp?)?.toDate(),
    );
  }

  factory AdminUser.empty() {
    final now = DateTime.now();
    return AdminUser(
      id: '',
      email: '',
      fullName: '',
      role: AdminRole.admin,
      permissions: [],
      status: AdminStatus.active,
      createdAt: now,
      createdBy: '',
      updatedAt: now,
      updatedBy: '',
      twoFactorEnabled: false,
      isEmailVerified: false,
      loginAttempts: 0,
    );
  }

  @override
  String toString() =>
      'AdminUser(id: $id, email: $email, fullName: $fullName, role: $role, status: $status)';
}
