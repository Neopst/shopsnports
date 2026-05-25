/// Complete User Role Enum for ShopsNports
/// All users in the platform fall into one of these categories
enum UserRoleType {
  /// Super Admin - Platform owner with full access
  /// Can create sub-admins, grant permissions, full system access
  superAdmin,

  /// Sub Admin - Created by Super Admin with operational permissions
  /// Can manage business based on granted permissions
  subAdmin,

  /// Registered Customer - Regular user who can ship packages
  customer,

  /// Affiliate - Earns commission by referring shipping clients
  affiliate,

  /// Guest - Unregistered user who can submit shipping requests only
  guest,
}

/// User Status Enum
enum UserStatus {
  active,
  suspended,
  pending,
  deactivated,
}

/// Admin Permission Enum - Granular permissions for sub-admins
enum AdminPermission {
  // Dashboard
  viewDashboard,

  // Shipping Management
  viewShippingRequests,
  approveShippingRequests,
  manageShippingStatus,
  cancelShippingRequests,

  // Customer Management
  viewCustomers,
  manageCustomers,
  suspendCustomers,

  // Affiliate Management
  viewAffiliates,
  manageAffiliates,
  approveAffiliates,
  viewAffiliateCommissions,
  processAffiliatePayouts,

  // Admin Management
  viewSubAdmins,
  createSubAdmins,
  manageSubAdmins,

  // Reports & Analytics
  viewReports,
  exportData,

  // Settings
  viewSettings,
  manageSettings,

  // Notifications
  sendNotifications,

  // Financial
  viewFinancials,
  manageFinancials,

  // Content
  manageContent,
  manageBanners,
  manageNewsTicker,
}

/// Extension for UserRoleType
extension UserRoleTypeExtension on UserRoleType {
  String get displayName {
    switch (this) {
      case UserRoleType.superAdmin:
        return 'Super Admin';
      case UserRoleType.subAdmin:
        return 'Sub Admin';
      case UserRoleType.customer:
        return 'Customer';
      case UserRoleType.affiliate:
        return 'Affiliate';
      case UserRoleType.guest:
        return 'Guest';
    }
  }

  String get description {
    switch (this) {
      case UserRoleType.superAdmin:
        return 'Full platform access - can create sub-admins and manage everything';
      case UserRoleType.subAdmin:
        return 'Operational access based on granted permissions';
      case UserRoleType.customer:
        return 'Registered customer - can ship packages and track shipments';
      case UserRoleType.affiliate:
        return 'Affiliate partner - earn commissions by referring clients';
      case UserRoleType.guest:
        return 'Guest user - can submit shipping requests without registration';
    }
  }

  String get dashboardRoute {
    switch (this) {
      case UserRoleType.superAdmin:
      case UserRoleType.subAdmin:
        return '/admin/dashboard';
      case UserRoleType.customer:
        return '/home';
      case UserRoleType.affiliate:
        return '/affiliate/dashboard';
      case UserRoleType.guest:
        return '/shipping/request';
    }
  }

  bool get canRequestShipping {
    return true; // All user types can request shipping
  }

  bool get isAdmin {
    return this == UserRoleType.superAdmin || this == UserRoleType.subAdmin;
  }

  bool get requiresAuthForShipping {
    return this != UserRoleType.guest;
  }
}

/// Extension for UserStatus
extension UserStatusExtension on UserStatus {
  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  bool get isActive {
    return this == UserStatus.active;
  }
}

/// Extension for AdminPermission with category grouping
extension AdminPermissionExtension on AdminPermission {
  String get displayName {
    switch (this) {
      case AdminPermission.viewDashboard:
        return 'View Dashboard';
      case AdminPermission.viewShippingRequests:
        return 'View Shipping Requests';
      case AdminPermission.approveShippingRequests:
        return 'Approve Shipping Requests';
      case AdminPermission.manageShippingStatus:
        return 'Manage Shipping Status';
      case AdminPermission.cancelShippingRequests:
        return 'Cancel Shipping Requests';
      case AdminPermission.viewCustomers:
        return 'View Customers';
      case AdminPermission.manageCustomers:
        return 'Manage Customers';
      case AdminPermission.suspendCustomers:
        return 'Suspend Customers';
      case AdminPermission.viewAffiliates:
        return 'View Affiliates';
      case AdminPermission.manageAffiliates:
        return 'Manage Affiliates';
      case AdminPermission.approveAffiliates:
        return 'Approve Affiliates';
      case AdminPermission.viewAffiliateCommissions:
        return 'View Affiliate Commissions';
      case AdminPermission.processAffiliatePayouts:
        return 'Process Affiliate Payouts';
      case AdminPermission.viewSubAdmins:
        return 'View Sub Admins';
      case AdminPermission.createSubAdmins:
        return 'Create Sub Admins';
      case AdminPermission.manageSubAdmins:
        return 'Manage Sub Admins';
      case AdminPermission.viewReports:
        return 'View Reports';
      case AdminPermission.exportData:
        return 'Export Data';
      case AdminPermission.viewSettings:
        return 'View Settings';
      case AdminPermission.manageSettings:
        return 'Manage Settings';
      case AdminPermission.sendNotifications:
        return 'Send Notifications';
      case AdminPermission.viewFinancials:
        return 'View Financials';
      case AdminPermission.manageFinancials:
        return 'Manage Financials';
      case AdminPermission.manageContent:
        return 'Manage Content';
      case AdminPermission.manageBanners:
        return 'Manage Banners';
      case AdminPermission.manageNewsTicker:
        return 'Manage News Ticker';
    }
  }

  String get category {
    if (this == AdminPermission.viewDashboard) return 'Dashboard';
    if (name.startsWith('view') || name.startsWith('manage')) {
      if (name.contains('Shipping')) return 'Shipping';
      if (name.contains('Customer')) return 'Customers';
      if (name.contains('Affiliate')) return 'Affiliates';
      if (name.contains('SubAdmin')) return 'Admins';
      if (name.contains('Report')) return 'Reports';
      if (name.contains('Setting')) return 'Settings';
      if (name.contains('Financial')) return 'Financials';
      if (name.contains('Content') ||
          name.contains('Banner') ||
          name.contains('News')) {
        return 'Content';
      }
    }
    if (name.contains('Notification')) return 'Notifications';
    if (name.contains('Export')) return 'Reports';
    return 'General';
  }
}

/// Permission Group - Groups permissions by category
class PermissionGroup {
  final String name;
  final List<AdminPermission> permissions;

  PermissionGroup({required this.name, required this.permissions});

  static List<PermissionGroup> get allGroups => [
        PermissionGroup(
          name: 'Dashboard',
          permissions: [AdminPermission.viewDashboard],
        ),
        PermissionGroup(
          name: 'Shipping',
          permissions: [
            AdminPermission.viewShippingRequests,
            AdminPermission.approveShippingRequests,
            AdminPermission.manageShippingStatus,
            AdminPermission.cancelShippingRequests,
          ],
        ),
        PermissionGroup(
          name: 'Customers',
          permissions: [
            AdminPermission.viewCustomers,
            AdminPermission.manageCustomers,
            AdminPermission.suspendCustomers,
          ],
        ),
        PermissionGroup(
          name: 'Affiliates',
          permissions: [
            AdminPermission.viewAffiliates,
            AdminPermission.manageAffiliates,
            AdminPermission.approveAffiliates,
            AdminPermission.viewAffiliateCommissions,
            AdminPermission.processAffiliatePayouts,
          ],
        ),
        PermissionGroup(
          name: 'Admin Management',
          permissions: [
            AdminPermission.viewSubAdmins,
            AdminPermission.createSubAdmins,
            AdminPermission.manageSubAdmins,
          ],
        ),
        PermissionGroup(
          name: 'Reports',
          permissions: [
            AdminPermission.viewReports,
            AdminPermission.exportData,
          ],
        ),
        PermissionGroup(
          name: 'Settings',
          permissions: [
            AdminPermission.viewSettings,
            AdminPermission.manageSettings,
          ],
        ),
        PermissionGroup(
          name: 'Financials',
          permissions: [
            AdminPermission.viewFinancials,
            AdminPermission.manageFinancials,
          ],
        ),
        PermissionGroup(
          name: 'Content',
          permissions: [
            AdminPermission.manageContent,
            AdminPermission.manageBanners,
            AdminPermission.manageNewsTicker,
          ],
        ),
        PermissionGroup(
          name: 'Notifications',
          permissions: [
            AdminPermission.sendNotifications,
          ],
        ),
      ];
}

/// Default permission sets for sub-admin roles
class DefaultPermissionSet {
  final String name;
  final List<AdminPermission> permissions;

  DefaultPermissionSet({required this.name, required this.permissions});

  /// Full access -接近 super admin
  static final fullAccess = DefaultPermissionSet(
    name: 'Full Access',
    permissions: AdminPermission.values.toList(),
  );

  /// Shipping manager - can only manage shipping
  static final shippingManager = DefaultPermissionSet(
    name: 'Shipping Manager',
    permissions: [
      AdminPermission.viewDashboard,
      AdminPermission.viewShippingRequests,
      AdminPermission.approveShippingRequests,
      AdminPermission.manageShippingStatus,
      AdminPermission.cancelShippingRequests,
    ],
  );

  /// Customer support - view and manage customers
  static final customerSupport = DefaultPermissionSet(
    name: 'Customer Support',
    permissions: [
      AdminPermission.viewDashboard,
      AdminPermission.viewShippingRequests,
      AdminPermission.viewCustomers,
      AdminPermission.manageCustomers,
      AdminPermission.viewAffiliates,
    ],
  );

  /// Finance - view financials and process payouts
  static final finance = DefaultPermissionSet(
    name: 'Finance',
    permissions: [
      AdminPermission.viewDashboard,
      AdminPermission.viewAffiliateCommissions,
      AdminPermission.processAffiliatePayouts,
      AdminPermission.viewFinancials,
      AdminPermission.manageFinancials,
      AdminPermission.exportData,
    ],
  );

  /// Content manager - manage banners, news, content
  static final contentManager = DefaultPermissionSet(
    name: 'Content Manager',
    permissions: [
      AdminPermission.viewDashboard,
      AdminPermission.manageContent,
      AdminPermission.manageBanners,
      AdminPermission.manageNewsTicker,
      AdminPermission.sendNotifications,
    ],
  );

  /// Read-only analyst
  static final analyst = DefaultPermissionSet(
    name: 'Analyst (Read-Only)',
    permissions: [
      AdminPermission.viewDashboard,
      AdminPermission.viewShippingRequests,
      AdminPermission.viewCustomers,
      AdminPermission.viewAffiliates,
      AdminPermission.viewAffiliateCommissions,
      AdminPermission.viewReports,
      AdminPermission.viewFinancials,
    ],
  );

  static List<DefaultPermissionSet> get presets => [
        fullAccess,
        shippingManager,
        customerSupport,
        finance,
        contentManager,
        analyst,
      ];
}
