/// Admin module permissions
/// Each admin can have access to specific modules (except super_admin which is always denied)
library;

import 'package:flutter/material.dart';

enum AdminModule {
  news_ticker,
  content_management,
  invoices,
  shipping,
  customers,
  affiliates,
  payouts,
  notifications,
  push_notifications,
  settings,
}

extension AdminModuleExtension on AdminModule {
  String get displayName {
    switch (this) {
      case AdminModule.news_ticker:
        return 'News Ticker';
      case AdminModule.content_management:
        return 'Content Management';
      case AdminModule.invoices:
        return 'Invoices';
      case AdminModule.shipping:
        return 'Shipping';
      case AdminModule.customers:
        return 'Customers';
      case AdminModule.affiliates:
        return 'Affiliates';
      case AdminModule.payouts:
        return 'Payouts';
      case AdminModule.notifications:
        return 'Notifications';
      case AdminModule.push_notifications:
        return 'Push Notifications';
      case AdminModule.settings:
        return 'Settings';
    }
  }

  String get description {
    switch (this) {
      case AdminModule.news_ticker:
        return 'Create and manage news ticker items';
      case AdminModule.content_management:
        return 'Manage pages, FAQs, banners, and templates';
      case AdminModule.invoices:
        return 'Create and manage invoices';
      case AdminModule.shipping:
        return 'Track and manage shipping requests';
      case AdminModule.customers:
        return 'Manage customer profiles and data';
      case AdminModule.affiliates:
        return 'Manage affiliate accounts';
      case AdminModule.payouts:
        return 'Manage payouts and commission settings';
      case AdminModule.notifications:
        return 'Send and manage notifications';
      case AdminModule.push_notifications:
        return 'Send push notifications via FCM';
      case AdminModule.settings:
        return 'Configure business settings and SMTP';
    }
  }
}

class AdminPermissions {
  final Map<String, bool> permissions;

  AdminPermissions({required this.permissions});

  /// Check if admin has access to a specific module
  bool hasAccess(AdminModule module) {
    return permissions[module.name] ?? false;
  }

  /// Get list of modules admin can access
  List<AdminModule> getAccessibleModules() {
    return AdminModule.values.where((module) => hasAccess(module)).toList();
  }

  /// Get list of modules admin cannot access
  List<AdminModule> getRestrictedModules() {
    return AdminModule.values.where((module) => !hasAccess(module)).toList();
  }

  /// Create default permissions (all false for new admins)
  factory AdminPermissions.defaultPermissions() {
    return AdminPermissions(
      permissions: {for (var module in AdminModule.values) module.name: false},
    );
  }

  /// Create permissions from JSON (Firestore)
  factory AdminPermissions.fromMap(Map<String, dynamic> map) {
    return AdminPermissions(
      permissions: Map<String, bool>.from(
        map['permissions'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {'permissions': permissions};
  }

  /// Convert to JSON for display
  Map<String, dynamic> toJson() {
    return {'permissions': permissions};
  }

  /// Create a copy with updated permissions
  AdminPermissions copyWith({Map<String, bool>? permissions}) {
    return AdminPermissions(permissions: permissions ?? this.permissions);
  }

  /// Update single module permission
  AdminPermissions updateModuleAccess(AdminModule module, bool access) {
    final newPermissions = Map<String, bool>.from(permissions);
    newPermissions[module.name] = access;
    return AdminPermissions(permissions: newPermissions);
  }

  /// Grant all permissions (super admin only)
  factory AdminPermissions.superAdmin() {
    return AdminPermissions(
      permissions: {for (var module in AdminModule.values) module.name: true},
    );
  }

  /// Revoke all permissions
  factory AdminPermissions.noPermissions() {
    return AdminPermissions(
      permissions: {for (var module in AdminModule.values) module.name: false},
    );
  }

  // ============================================================================
  // PERMISSION TEMPLATES
  // ============================================================================

  /// Content Manager template - manages news and content
  factory AdminPermissions.contentManager() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module == AdminModule.news_ticker ||
                      module == AdminModule.content_management
      },
    );
  }

  /// Support Agent template - handles customers and notifications
  factory AdminPermissions.supportAgent() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module == AdminModule.customers ||
                      module == AdminModule.notifications
      },
    );
  }

  /// Billing Manager template - manages invoices and payouts
  factory AdminPermissions.billingManager() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module == AdminModule.invoices ||
                      module == AdminModule.payouts
      },
    );
  }

  /// Shipping Manager template - manages shipping requests
  factory AdminPermissions.shippingManager() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module == AdminModule.shipping
      },
    );
  }

  /// Affiliate Manager template - manages affiliates
  factory AdminPermissions.affiliateManager() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module == AdminModule.affiliates
      },
    );
  }

  /// Full Access template - all modules except settings
  factory AdminPermissions.fullAccess() {
    return AdminPermissions(
      permissions: {
        for (var module in AdminModule.values)
          module.name: module != AdminModule.settings
      },
    );
  }

  /// Get all available permission templates
  static List<PermissionTemplate> getTemplates() {
    return [
      PermissionTemplate(
        name: 'Full Access',
        description: 'Access to all modules except settings',
        icon: Icons.dashboard,
        color: Colors.blue,
        permissions: AdminPermissions.fullAccess().permissions,
      ),
      PermissionTemplate(
        name: 'Content Manager',
        description: 'Manage news ticker and content',
        icon: Icons.article,
        color: Colors.green,
        permissions: AdminPermissions.contentManager().permissions,
      ),
      PermissionTemplate(
        name: 'Support Agent',
        description: 'Handle customers and notifications',
        icon: Icons.support_agent,
        color: Colors.orange,
        permissions: AdminPermissions.supportAgent().permissions,
      ),
      PermissionTemplate(
        name: 'Billing Manager',
        description: 'Manage invoices and payouts',
        icon: Icons.receipt,
        color: Colors.purple,
        permissions: AdminPermissions.billingManager().permissions,
      ),
      PermissionTemplate(
        name: 'Shipping Manager',
        description: 'Manage shipping requests',
        icon: Icons.local_shipping,
        color: Colors.teal,
        permissions: AdminPermissions.shippingManager().permissions,
      ),
      PermissionTemplate(
        name: 'Affiliate Manager',
        description: 'Manage affiliate accounts',
        icon: Icons.handshake,
        color: Colors.indigo,
        permissions: AdminPermissions.affiliateManager().permissions,
      ),
      PermissionTemplate(
        name: 'Custom',
        description: 'Manually select permissions',
        icon: Icons.tune,
        color: Colors.grey,
        permissions: AdminPermissions.defaultPermissions().permissions,
      ),
    ];
  }
}

/// Permission template for quick selection
class PermissionTemplate {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Map<String, bool> permissions;

  const PermissionTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.permissions,
  });
}
