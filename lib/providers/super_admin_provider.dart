import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/admin_user.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';
import 'package:shopsnports/services/super_admin_service.dart';
import 'package:shopsnports/services/admin_email_service.dart';

/// Super Admin Service Provider
final superAdminServiceProvider = Provider((ref) => SuperAdminService());

/// Admin Email Service Provider
final adminEmailServiceProvider = Provider((ref) => AdminEmailService());

/// Current Admin User Provider
final currentAdminProvider = FutureProvider<AdminUser?>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getCurrentAdmin();
});

/// Is Admin Check Provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.isAdmin();
});

/// Is Super Admin Check Provider
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.isSuperAdmin();
});

/// All Sub-Admins Provider
final allSubAdminsProvider = FutureProvider<List<AdminUser>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAllSubAdmins();
});

/// Create Sub-Admin Result
class CreateSubAdminResult {
  final AdminUser adminUser;
  final String tempPassword;

  CreateSubAdminResult({
    required this.adminUser,
    required this.tempPassword,
  });
}

/// Create Sub-Admin Provider
final createSubAdminProvider = FutureProvider.family<
  CreateSubAdminResult,
  ({
    String email,
    String displayName,
    List<AdminPermission>? permissions,
    String? phone,
    String? department,
    String? notes,
    bool sendWelcomeEmail,
  })
>((ref, params) async {
  final service = ref.watch(superAdminServiceProvider);
  final emailService = ref.watch(adminEmailServiceProvider);
  final currentAdmin = await service.getCurrentAdmin();

  if (currentAdmin == null || !currentAdmin.isSuperAdmin) {
    throw Exception('Only super admins can create sub-admins');
  }

  // Create the sub-admin
  final result = await service.createSubAdmin(
    email: params.email,
    displayName: params.displayName,
    createdBySuperAdminId: currentAdmin.id,
    permissions: params.permissions,
    phone: params.phone,
    department: params.department,
    notes: params.notes,
  );

  // Send welcome email if requested
  if (params.sendWelcomeEmail) {
    await emailService.sendSubAdminWelcomeEmail(
      email: params.email,
      displayName: params.displayName,
      tempPassword: result['tempPassword'] as String,
      createdBySuperAdminName: currentAdmin.displayName,
    );
  }

  return CreateSubAdminResult(
    adminUser: result['adminUser'] as AdminUser,
    tempPassword: result['tempPassword'] as String,
  );
});

/// Update Sub-Admin Permissions Provider
final updateSubAdminPermissionsProvider = FutureProvider.family<
  void,
  ({
    String subAdminId,
    List<AdminPermission> permissions,
  })
>((ref, params) async {
  final service = ref.watch(superAdminServiceProvider);
  final currentAdmin = await service.getCurrentAdmin();

  if (currentAdmin == null || !currentAdmin.isSuperAdmin) {
    throw Exception('Only super admins can update permissions');
  }

  await service.updateSubAdminPermissions(
    subAdminId: params.subAdminId,
    permissions: params.permissions,
    updatedBySuperAdminId: currentAdmin.id,
  );
});

/// Suspend Sub-Admin Provider
final suspendSubAdminProvider = FutureProvider.family<
  void,
  String
>((ref, subAdminId) async {
  final service = ref.watch(superAdminServiceProvider);
  final currentAdmin = await service.getCurrentAdmin();

  if (currentAdmin == null || !currentAdmin.isSuperAdmin) {
    throw Exception('Only super admins can suspend users');
  }

  await service.suspendSubAdmin(
    subAdminId: subAdminId,
    suspendedBySuperAdminId: currentAdmin.id,
  );
});

/// Reactivate Sub-Admin Provider
final reactivateSubAdminProvider = FutureProvider.family<
  void,
  String
>((ref, subAdminId) async {
  final service = ref.watch(superAdminServiceProvider);
  final currentAdmin = await service.getCurrentAdmin();

  if (currentAdmin == null || !currentAdmin.isSuperAdmin) {
    throw Exception('Only super admins can reactivate users');
  }

  await service.reactivateSubAdmin(
    subAdminId: subAdminId,
    reactivatedBySuperAdminId: currentAdmin.id,
  );
});

/// Delete Sub-Admin Provider
final deleteSubAdminProvider = FutureProvider.family<
  void,
  String
>((ref, subAdminId) async {
  final service = ref.watch(superAdminServiceProvider);
  final currentAdmin = await service.getCurrentAdmin();

  if (currentAdmin == null || !currentAdmin.isSuperAdmin) {
    throw Exception('Only super admins can delete users');
  }

  await service.deleteSubAdmin(
    subAdminId: subAdminId,
    deletedBySuperAdminId: currentAdmin.id,
  );
});

/// Get Admin by ID Provider
final adminByIdProvider = FutureProvider.family<AdminUser?, String>((ref, id) async {
  final service = ref.watch(superAdminServiceProvider);
  return service.getAdminById(id);
});