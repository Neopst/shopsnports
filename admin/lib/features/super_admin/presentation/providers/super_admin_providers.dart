import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_activity_log.dart';
import '../../data/models/admin_user.dart';
import '../../data/repositories/super_admin_repository_firestore.dart';
import '../../../auth/data/providers/auth_providers.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

/// Singleton provider for SuperAdminRepositoryFirestore
final superAdminRepositoryProvider = Provider<SuperAdminRepositoryFirestore>((
  ref,
) {
  return SuperAdminRepositoryFirestore();
});

// ============================================================================
// ADMIN USERS PROVIDERS
// ============================================================================

/// Stream of all admins (real-time updates)
final allAdminsStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminsStream();
});

/// Get a single admin by ID (future)
final adminByIdProvider = FutureProvider.family<AdminUser?, String>((
  ref,
  adminId,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminById(adminId);
});

/// Get admin by email (future)
final adminByEmailProvider = FutureProvider.family<AdminUser?, String>((
  ref,
  email,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminByEmail(email);
});

/// Stream of active admins
final activeAdminsStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminsStream().map(
    (admins) => admins.where((admin) => admin.isActive).toList(),
  );
});

/// Stream of disabled admins
final disabledAdminsStreamProvider = StreamProvider<List<AdminUser>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminsStream().map(
    (admins) => admins.where((admin) => admin.isDisabled).toList(),
  );
});

/// Get active admins count
final activeAdminsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(superAdminRepositoryProvider);
  final admins = await repo.getActiveAdmins();
  return admins.length;
});

/// Get disabled admins count
final disabledAdminsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(superAdminRepositoryProvider);
  final admins = await repo.getDisabledAdmins();
  return admins.length;
});

// ============================================================================
// ADMIN CREATION PROVIDER
// ============================================================================

/// FutureProvider for creating a new admin
final createAdminProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String email, String displayName, String role, Map<String, bool> permissions})
    >((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.createAdmin(
        email: params.email,
        displayName: params.displayName,
        role: params.role,
        permissions: params.permissions,
      );
    });

// ============================================================================
// ADMIN PERMISSIONS PROVIDERS
// ============================================================================

/// Update admin permissions (future)
final updateAdminPermissionsProvider =
    FutureProvider.family<
      bool,
      (String adminId, Map<String, bool> permissions)
    >((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.updateAdminPermissions(
        adminId: params.$1,
        permissions: params.$2,
      );
    });

/// Grant module access to admin (future)
final grantModuleAccessProvider =
    FutureProvider.family<void, (String adminId, String module)>((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.grantModuleAccess(params.$1, params.$2);
    });

/// Revoke module access from admin (future)
final revokeModuleAccessProvider =
    FutureProvider.family<void, (String adminId, String module)>((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.revokeModuleAccess(params.$1, params.$2);
    });

/// Get permission template for displaying module names
final permissionTemplateProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getPermissionTemplate();
});

// ============================================================================
// ADMIN STATUS MANAGEMENT PROVIDERS
// ============================================================================

/// Disable admin (future)
final disableAdminProvider = FutureProvider.family<bool, String>((
  ref,
  adminId,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.disableAdmin(adminId);
});

/// Enable admin (future)
final enableAdminProvider = FutureProvider.family<void, String>((ref, adminId) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.enableAdmin(adminId);
});

/// Delete admin (future)
final deleteAdminProvider = FutureProvider.family<bool, String>((ref, adminId) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.deleteAdmin(adminId);
});

// ============================================================================
// ACTIVITY LOGGING PROVIDERS
// ============================================================================

/// Stream of all admin activities (real-time)
final allActivityLogsStreamProvider = StreamProvider<List<AdminActivityLog>>((
  ref,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getActivityLogsStream(limit: 200);
});

/// Stream of activity logs for a specific admin
final adminActivityLogsStreamProvider =
    StreamProvider.family<List<AdminActivityLog>, String>((ref, adminId) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.getActivityLogsStream(adminId: adminId, limit: 100);
    });

/// Get activity logs for a specific admin (future)
final adminActivityLogsFutureProvider =
    FutureProvider.family<List<AdminActivityLog>, String>((ref, adminId) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.getAdminActivityLogs(adminId);
    });

/// Get activity logs filtered by action (future)
final activityLogsByActionProvider =
    FutureProvider.family<List<AdminActivityLog>, String>((ref, action) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.getActivityLogs(action: action);
    });

/// Get activity logs within date range (future)
final activityLogsByDateRangeProvider =
    FutureProvider.family<
      List<AdminActivityLog>,
      (DateTime startDate, DateTime endDate)
    >((ref, dates) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.getActivityLogs(startDate: dates.$1, endDate: dates.$2);
    });

/// Log an admin activity (future)
final logAdminActivityProvider =
    FutureProvider.family<
      String,
      ({
        String adminId,
        String action,
        String? itemId,
        String? itemName,
        Map<String, dynamic>? details,
      })
    >((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.logAdminActivity(
        adminId: params.adminId,
        action: params.action,
        itemId: params.itemId,
        itemName: params.itemName,
        details: params.details,
      );
    });

/// Get activity summary for dashboard
final activitySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getActivitySummary();
});

// ============================================================================
// STATISTICS PROVIDERS
// ============================================================================

/// Get admin statistics (total, active, disabled, etc.)
final adminStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAdminStatistics();
});

/// Get login statistics for a specific admin
final adminLoginStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, adminId) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.getAdminLoginStats(adminId);
    });

// ============================================================================
// SEARCH & FILTER PROVIDERS
// ============================================================================

/// Search admins by email or name
final searchAdminsProvider = FutureProvider.family<List<AdminUser>, String>((
  ref,
  query,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.searchAdmins(query);
});

/// Filter admins by status and/or role
final filterAdminsProvider =
    FutureProvider.family<List<AdminUser>, ({String? status, String? role})>((
      ref,
      filters,
    ) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.filterAdmins(status: filters.status, role: filters.role);
    });

// ============================================================================
// PROFILE MANAGEMENT PROVIDERS
// ============================================================================

/// Update admin profile (displayName, etc.)
final updateAdminProfileProvider =
    FutureProvider.family<void, (String adminId, String displayName)>((
      ref,
      params,
    ) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.updateAdminProfile(
        adminId: params.$1,
        displayName: params.$2,
      );
    });

/// Require password change on next login
final requirePasswordChangeProvider = FutureProvider.family<void, String>((
  ref,
  adminId,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.requirePasswordChange(adminId);
});

// ============================================================================
// VALIDATION PROVIDERS
// ============================================================================

/// Check if admin is active
final isAdminActiveProvider = FutureProvider.family<bool, String>((
  ref,
  adminId,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.isAdminActive(adminId);
});

/// Check if admin has access to a module
final hasModuleAccessProvider =
    FutureProvider.family<bool, (String adminId, String module)>((ref, params) {
      final repo = ref.watch(superAdminRepositoryProvider);
      return repo.hasModuleAccess(params.$1, params.$2);
    });

/// Get all accessible modules for an admin
final accessibleModulesProvider = FutureProvider.family<List<String>, String>((
  ref,
  adminId,
) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return repo.getAccessibleModules(adminId);
});

// ============================================================================
// CURRENT USER SUPER ADMIN PROFILE PROVIDERS
// ============================================================================

/// Get current user's admin profile from Firestore
final currentUserAdminProfileProvider = StreamProvider<AdminUser?>((
  ref,
) async* {
  // Get current user from auth
  final authAsync = ref.watch(authStateProvider);
  final repo = ref.watch(superAdminRepositoryProvider);
  final allAdmins = repo.getAdminsStream();

  await for (final admins in allAdmins) {
    // Get current user's admin profile
    final authState = authAsync.value;
    if (authState == null) {
      yield null;
      continue;
    }

    try {
      final adminUser = admins.firstWhere((admin) => admin.id == authState.uid);
      yield adminUser;
    } catch (e) {
      // User not found in admins list
      yield null;
    }
  }
});
