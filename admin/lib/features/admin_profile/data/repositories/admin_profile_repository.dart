import 'package:admin_dashboard/features/admin_profile/data/models/index.dart';

/// Abstract interface for admin profile operations
abstract class IAdminProfileRepository {
  // Admin User Management
  Future<AdminUser?> getAdminById(String adminId);
  Future<AdminUser?> getAdminByEmail(String email);
  Future<List<AdminUser>> getAllAdmins({
    int limit = 50,
    String? roleFilter,
    String? statusFilter,
  });
  Future<List<AdminUser>> searchAdmins(String query);
  Future<void> updateAdmin(String adminId, AdminUser admin);
  Future<void> suspendAdmin(String adminId, String reason);
  Future<void> reactivateAdmin(String adminId);
  Future<void> resetAdminPassword(String adminId);
  Future<void> updateAdminRole(String adminId, String newRole);
  Future<void> updateAdminPermissions(String adminId, List<String> permissions);
  Future<int> getAdminCount();
  Future<List<AdminUser>> getAdminsByRole(String role);

  // Admin Registration
  Future<AdminRegistrationRequest> createRegistrationRequest(
    AdminRegistrationRequest request,
  );
  Future<AdminRegistrationRequest?> getRegistrationRequest(String requestId);
  Future<List<AdminRegistrationRequest>> getPendingRegistrations();
  Future<void> approveRegistration(String requestId, String approvedBy);
  Future<void> rejectRegistration(String requestId, String reason);
  Future<void> completeRegistration(String requestId, String userId);
  Future<void> expireRegistration(String requestId);

  // Activity Logging
  Future<void> logActivity(AdminActivity activity);
  Future<AdminActivity?> getActivity(String activityId);
  Future<List<AdminActivity>> getActivityLog(
    String adminId, {
    int limit = 100,
    String? actionFilter,
  });
  Future<List<AdminActivity>> getActivityByResource(
    String resourceType,
    String resourceId,
  );
  Future<Map<String, int>> getActivitySummary(String adminId);
  Future<List<AdminActivity>> searchActivities(String query);

  // Security
  Future<void> recordFailedLoginAttempt(String adminId);
  Future<void> recordSuccessfulLogin(String adminId);
  Future<void> resetLoginAttempts(String adminId);
  Future<bool> isAdminLocked(String adminId);
  Future<void> enable2FA(String adminId, String phoneNumber);
  Future<void> disable2FA(String adminId);
  Future<void> verifyAdminEmail(String adminId);

  // Bulk Operations
  Future<void> bulkSuspendAdmins(List<String> adminIds, String reason);
  Future<void> bulkReactivateAdmins(List<String> adminIds);
  Future<void> bulkUpdateRole(List<String> adminIds, String newRole);
  Future<List<String>> exportAdminList();
}
