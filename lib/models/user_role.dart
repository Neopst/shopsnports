import 'roles_and_permissions.dart';

/// Enum representing the different user roles in ShopsNports
/// Updated to use the centralized roles_and_permissions.dart
enum UserRole {
  customer, // Ship packages, browse offerings
  affiliate, // Earn as affiliate carrier
  superAdmin, // Full platform access
  subAdmin, // Operational access based on permissions
  guest, // Can submit shipping requests and browse without registration
}

extension UserRoleExtension on UserRole {
  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.affiliate:
        return 'Affiliate Carrier';
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.subAdmin:
        return 'Sub Admin';
      case UserRole.guest:
        return 'Guest User';
    }
  }

  /// Get role description
  String get description {
    switch (this) {
      case UserRole.customer:
        return 'Ship packages and track your shipments';
      case UserRole.affiliate:
        return 'Earn money as an affiliate carrier';
      case UserRole.superAdmin:
        return 'Full platform access with ability to create sub-admins';
      case UserRole.subAdmin:
        return 'Operational access based on granted permissions';
      case UserRole.guest:
        return 'Submit shipping requests and browse without creating an account';
    }
  }

  /// Get role icon emoji
  String get emoji {
    switch (this) {
      case UserRole.customer:
        return '📦';
      case UserRole.affiliate:
        return '💰';
      case UserRole.superAdmin:
        return '👑';
      case UserRole.subAdmin:
        return '👮';
      case UserRole.guest:
        return '🚶';
    }
  }

  /// Convert from UserRoleType (static method since extensions can't have constructors)
  static UserRole fromUserRoleType(UserRoleType type) {
    switch (type) {
      case UserRoleType.superAdmin:
        return UserRole.superAdmin;
      case UserRoleType.subAdmin:
        return UserRole.subAdmin;
      case UserRoleType.customer:
        return UserRole.customer;
      case UserRoleType.affiliate:
        return UserRole.affiliate;
      case UserRoleType.guest:
        return UserRole.guest;
    }
  }

  /// Convert to UserRoleType
  UserRoleType toUserRoleType() {
    switch (this) {
      case UserRole.superAdmin:
        return UserRoleType.superAdmin;
      case UserRole.subAdmin:
        return UserRoleType.subAdmin;
      case UserRole.customer:
        return UserRoleType.customer;
      case UserRole.affiliate:
        return UserRoleType.affiliate;
      case UserRole.guest:
        return UserRoleType.guest;
    }
  }

  /// Get dashboard route based on role
  String get dashboardRoute {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.subAdmin:
        return '/admin/dashboard';
      case UserRole.customer:
        return '/home';
      case UserRole.affiliate:
        return '/affiliate/dashboard';
      case UserRole.guest:
        return '/shipping/request';
    }
  }

  /// Check if role can request shipping
  bool get canRequestShipping => true;

  /// Check if role is admin
  bool get isAdmin =>
      this == UserRole.superAdmin || this == UserRole.subAdmin;

  /// Check if role requires authentication for shipping
  bool get requiresAuthForShipping => this != UserRole.guest;
}