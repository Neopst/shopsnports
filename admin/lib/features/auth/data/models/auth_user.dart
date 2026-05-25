/// Represents an authenticated user in the system
class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final String? role; // 'super_admin', 'admin', 'user'
  final List<String> permissions; // e.g., ['create_admin', 'manage_content']
  final bool twoFactorEnabled;
  final bool isActive;

  AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
    required this.createdAt,
    this.lastSignInAt,
    this.role,
    this.permissions = const [],
    this.twoFactorEnabled = false,
    this.isActive = true,
  });

  /// Create copy with optional fields replaced
  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    String? role,
    List<String>? permissions,
    bool? twoFactorEnabled,
    bool? isActive,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'role': role,
      'permissions': permissions,
      'twoFactorEnabled': twoFactorEnabled,
      'isActive': isActive,
    };
  }

  /// Create from JSON (from Firestore)
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
      role: json['role'] as String?,
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if user is super admin
  bool get isSuperAdmin => role == 'super_admin';

  /// Check if user is admin
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, role: $role, isActive: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
