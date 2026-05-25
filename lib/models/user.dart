import 'package:cloud_firestore/cloud_firestore.dart';
import 'roles_and_permissions.dart';

/// Main User Model for ShopsNports
/// Represents all user types: Super Admin, Sub Admin, Customer, Affiliate, Guest
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? gender;
  final String? avatarUrl;

  /// Primary role type
  final UserRoleType roleType;

  /// User status (active, suspended, pending, deactivated)
  final UserStatus status;

  /// For sub-admins: list of granted permissions
  final List<String>? permissions;

  /// For sub-admins: reference to super admin who created this account
  final String? createdByAdminId;

  /// Currently selected/active role for this session (persisted to profile)
  final String? activeRole;

  /// Timestamp when user was created
  final DateTime createdAt;

  /// Last login timestamp
  final DateTime? lastLoginAt;

  // Customer-specific fields
  final String? businessName;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? taxId;

  // Affiliate-specific fields
  final bool affiliateApproved;
  final String? affiliateId;
  final String? affiliateCode;
  final double? commissionRate;
  final double? totalEarnings;
  final double? pendingPayout;

  // Guest user flag
  final bool isGuest;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.gender,
    this.avatarUrl,
    this.roleType = UserRoleType.customer,
    this.status = UserStatus.active,
    this.permissions,
    this.createdByAdminId,
    this.activeRole,
    required this.createdAt,
    this.lastLoginAt,
    this.businessName,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.taxId,
    this.affiliateApproved = false,
    this.affiliateId,
    this.affiliateCode,
    this.commissionRate,
    this.totalEarnings = 0.0,
    this.pendingPayout = 0.0,
    this.isGuest = false,
  });

  // ==================== Type Checks ====================

  bool get isSuperAdmin => roleType == UserRoleType.superAdmin;
  bool get isSubAdmin => roleType == UserRoleType.subAdmin;
  bool get isCustomer => roleType == UserRoleType.customer;
  bool get isAffiliate => roleType == UserRoleType.affiliate;
  bool get isGuestUser => roleType == UserRoleType.guest || isGuest;
  bool get isAdmin => roleType == UserRoleType.superAdmin || roleType == UserRoleType.subAdmin;

  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;
  bool get isPending => status == UserStatus.pending;

  bool canRequestShipping() => roleType != UserRoleType.superAdmin || isActive;

  // ==================== Factory Constructors ====================

  /// Create a guest user (temporary, for shipping requests)
  factory AppUser.guest({
    required String name,
    required String email,
    required String phone,
    String? address,
  }) {
    return AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      address: address,
      roleType: UserRoleType.guest,
      status: UserStatus.active,
      createdAt: DateTime.now(),
      isGuest: true,
    );
  }

  /// Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data, doc.id);
  }

  /// Create from Map
  factory AppUser.fromMap(Map<String, dynamic> map, [String? id]) {
    return AppUser(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      gender: map['gender'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      roleType: _parseRoleType(map['roleType']),
      status: _parseStatus(map['status']),
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'] as List)
          : null,
      createdByAdminId: map['createdByAdminId'] as String?,
      activeRole: map['activeRole'] as String?,
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      businessName: map['businessName'] as String?,
      bankName: map['bankName'] as String?,
      accountName: map['accountName'] as String?,
      accountNumber: map['accountNumber'] as String?,
      taxId: map['taxId'] as String?,
      affiliateApproved: map['affiliateApproved'] as bool? ?? false,
      affiliateId: map['affiliateId'] as String?,
      affiliateCode: map['affiliateCode'] as String?,
      commissionRate: (map['commissionRate'] as num?)?.toDouble(),
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (map['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      isGuest: map['isGuest'] as bool? ?? false,
    );
  }

  static UserRoleType _parseRoleType(dynamic value) {
    if (value == null) return UserRoleType.customer;
    if (value is UserRoleType) return value;
    if (value is String) {
      return UserRoleType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRoleType.customer,
      );
    }
    return UserRoleType.customer;
  }

  static UserStatus _parseStatus(dynamic value) {
    if (value == null) return UserStatus.active;
    if (value is UserStatus) return value;
    if (value is String) {
      return UserStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserStatus.active,
      );
    }
    return UserStatus.active;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // ==================== Conversion ====================

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'roleType': roleType.name,
      'status': status.name,
      'permissions': permissions,
      'createdByAdminId': createdByAdminId,
      'activeRole': activeRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'businessName': businessName,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'taxId': taxId,
      'affiliateApproved': affiliateApproved,
      'affiliateId': affiliateId,
      'affiliateCode': affiliateCode,
      'commissionRate': commissionRate,
      'totalEarnings': totalEarnings,
      'pendingPayout': pendingPayout,
      'isGuest': isGuest,
    };
  }

  // ==================== Copy With ====================

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gender,
    String? avatarUrl,
    UserRoleType? roleType,
    UserStatus? status,
    List<String>? permissions,
    String? createdByAdminId,
    String? activeRole,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? businessName,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? taxId,
    bool? affiliateApproved,
    String? affiliateId,
    String? affiliateCode,
    double? commissionRate,
    double? totalEarnings,
    double? pendingPayout,
    bool? isGuest,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleType: roleType ?? this.roleType,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      activeRole: activeRole ?? this.activeRole,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      businessName: businessName ?? this.businessName,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      taxId: taxId ?? this.taxId,
      affiliateApproved: affiliateApproved ?? this.affiliateApproved,
      affiliateId: affiliateId ?? this.affiliateId,
      affiliateCode: affiliateCode ?? this.affiliateCode,
      commissionRate: commissionRate ?? this.commissionRate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  // ==================== Utilities ====================

  /// Check if user has a specific permission (for sub-admins)
  bool hasPermission(String permissionName) {
    return permissions?.contains(permissionName) ?? false;
  }

  /// Get display name for role
  String get roleDisplayName => roleType.displayName;

  /// Get dashboard route based on role
  String get dashboardRoute => roleType.dashboardRoute;

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, role: $roleType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
