import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/admin_activity_log.dart';
import '../models/admin_permissions.dart';
import '../models/admin_user.dart';

/// Repository for Super Admin operations with Firestore backend
/// Handles CRUD operations for admin accounts, permissions, and activity tracking
class SuperAdminRepositoryFirestore {
  final FirebaseFirestore _firestore;

  // Collection references
  late final CollectionReference<Map<String, dynamic>> _adminUsersCollection;
  late final CollectionReference<Map<String, dynamic>>
  _adminActivityLogsCollection;

  // Constants
  static const String _adminUsersCollectionName = 'admin_users';
  static const String _adminActivityLogsCollectionName = 'admin_activity_logs';

  SuperAdminRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _initializeCollections();
  }

  /// Initialize Firestore collection references
  void _initializeCollections() {
    _adminUsersCollection = _firestore.collection(_adminUsersCollectionName);
    _adminActivityLogsCollection = _firestore.collection(_adminActivityLogsCollectionName);
  }

  // ============================================================================
  // ADMIN USER OPERATIONS
  // ============================================================================

  /// Get all admins from Firestore (real-time stream)
  Stream<List<AdminUser>> getAdminsStream() {
    return _adminUsersCollection
        .where('role', isNotEqualTo: null) // Only get documents with role field
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList(),
        );
  }

  /// Get a single admin by ID
  Future<AdminUser?> getAdminById(String adminId) async {
    try {
      final doc = await _adminUsersCollection.doc(adminId).get();
      if (doc.exists) {
        return AdminUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get admin: $e';
    }
  }

  /// Get all active admins
  Future<List<AdminUser>> getActiveAdmins() async {
    try {
      final snapshot = await _adminUsersCollection
          .where('status', isEqualTo: 'active')
          .orderBy('displayName')
          .get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to get active admins: $e';
    }
  }

  /// Get all disabled admins
  Future<List<AdminUser>> getDisabledAdmins() async {
    try {
      final snapshot = await _adminUsersCollection
          .where('status', isEqualTo: 'disabled')
          .orderBy('displayName')
          .get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to get disabled admins: $e';
    }
  }

  /// Get admin by email address
  Future<AdminUser?> getAdminByEmail(String email) async {
    try {
      final snapshot = await _adminUsersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return AdminUser.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Failed to get admin by email: $e';
    }
  }

  /// Check if email is available for new admin creation
  /// Returns true if email is available (not in use), false if already exists
  Future<bool> isEmailAvailable(String email) async {
    try {
      final admin = await getAdminByEmail(email);
      return admin == null;
    } catch (e) {
      // On error, assume email is not available to be safe
      return false;
    }
  }

  // ============================================================================
  // ADMIN CREATION
  // ============================================================================

  /// Create a new admin account
  /// Calls the createAdmin Cloud Function which handles:
  /// 1. Firebase Auth user creation
  /// 2. Firestore admin_users document
  /// 3. Custom claims
  /// 4. Password reset link email
  Future<Map<String, dynamic>> createAdmin({
    required String email,
    required String displayName,
    required String role, // 'admin' or 'sub_admin'
    required Map<String, bool> permissions,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the Cloud Function via Firebase callable
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createAdmin');

      final result = await callable({
        'email': email,
        'displayName': displayName,
        'role': role,
        'permissions': permissions,
      });

      final data = result.data;
      if (data['success'] == true) {
        return {
          'success': true,
          'adminId': data['adminId'],
          'email': data['email'],
          'displayName': data['displayName'],
          'role': data['role'],
          'requirePasswordChange': data['requirePasswordChange'] ?? true,
          'message': data['message'] ?? 'Admin created successfully',
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to create admin');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud function error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create admin: $e');
    }
  }

  // ============================================================================
  // ADMIN PERMISSIONS MANAGEMENT
  // ============================================================================

  /// Update admin permissions directly in Firestore
  Future<bool> updateAdminPermissions({
    required String adminId,
    required Map<String, bool> permissions,
  }) async {
    try {
      await _adminUsersCollection.doc(adminId).update({'permissions': permissions});

      return true;
    } catch (e) {
      throw 'Failed to update permissions: $e';
    }
  }

  /// Grant module access to admin
  Future<void> grantModuleAccess(String adminId, String module) async {
    try {
      final admin = await getAdminById(adminId);
      if (admin == null) throw 'Admin not found';

      final updatedPermissions = admin.permissions.permissions;
      updatedPermissions[module] = true;

      await updateAdminPermissions(
        adminId: adminId,
        permissions: updatedPermissions,
      );
    } catch (e) {
      throw 'Failed to grant module access: $e';
    }
  }

  /// Revoke module access from admin
  Future<void> revokeModuleAccess(String adminId, String module) async {
    try {
      final admin = await getAdminById(adminId);
      if (admin == null) throw 'Admin not found';

      final updatedPermissions = admin.permissions.permissions;
      updatedPermissions[module] = false;

      await updateAdminPermissions(
        adminId: adminId,
        permissions: updatedPermissions,
      );
    } catch (e) {
      throw 'Failed to revoke module access: $e';
    }
  }

  /// Get permission template for UI (display names and descriptions)
  Future<Map<String, dynamic>> getPermissionTemplate() async {
    try {
      final template = <String, dynamic>{};

      for (final module in AdminModule.values) {
        template[module.name] = {
          'displayName': module.displayName,
          'description': module.description,
        };
      }

      return template;
    } catch (e) {
      throw 'Failed to get permission template: $e';
    }
  }

  // ============================================================================
  // ADMIN STATUS MANAGEMENT
  // ============================================================================

  /// Disable an admin account
  /// Admin can no longer login, but account is preserved
  Future<bool> disableAdmin(String adminId) async {
    try {
      await _adminUsersCollection.doc(adminId).update({'status': 'disabled'});

      // Log activity
      await logAdminActivity(
        adminId: adminId,
        action: 'disabled_admin',
        details: {'targetAdminId': adminId},
      );

      return true;
    } catch (e) {
      throw 'Failed to disable admin: $e';
    }
  }

  /// Enable a disabled admin account
  /// Note: Requires direct Firestore update (no Cloud Function)
  Future<void> enableAdmin(String adminId) async {
    try {
      await _adminUsersCollection.doc(adminId).update({'status': 'active'});

      // Log activity
      await logAdminActivity(
        adminId: adminId,
        action: 'enabled_admin',
        details: {'targetAdminId': adminId},
      );
    } catch (e) {
      throw 'Failed to enable admin: $e';
    }
  }

  /// Delete an admin account permanently
  /// Account is removed from Firestore
  /// Activity logs are preserved for audit trail
  Future<bool> deleteAdmin(String adminId) async {
    try {
      await _adminUsersCollection.doc(adminId).delete();

      // Log activity
      await logAdminActivity(
        adminId: adminId,
        action: 'deleted_admin',
        details: {'targetAdminId': adminId},
      );

      return true;
    } catch (e) {
      throw 'Failed to delete admin: $e';
    }
  }

  // ============================================================================
  // ACTIVITY LOGGING
  // ============================================================================

  /// Get activity logs stream (real-time)
  Stream<List<AdminActivityLog>> getActivityLogsStream({
    String? adminId,
    String? action,
    int limit = 100,
  }) {
    Query query = _adminActivityLogsCollection.orderBy(
      'timestamp',
      descending: true,
    );

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }

    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminActivityLog.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get activity logs (future - single fetch)
  Future<List<AdminActivityLog>> getActivityLogs({
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _adminActivityLogsCollection.orderBy(
        'timestamp',
        descending: true,
      );

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => AdminActivityLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get activity logs: $e';
    }
  }

  /// Get activity logs for a specific admin (paginated)
  Future<List<AdminActivityLog>> getAdminActivityLogs(
    String adminId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _adminActivityLogsCollection
          .where('adminId', isEqualTo: adminId)
          .orderBy('timestamp', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => AdminActivityLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get admin activity logs: $e';
    }
  }

  /// Log an activity (used by Cloud Function and direct logging)
  Future<String> logAdminActivity({
    required String adminId,
    required String action,
    String? itemId,
    String? itemName,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    try {
      // Get current admin email
      final admin = await getAdminById(adminId);
      if (admin == null) throw 'Admin not found';

      final docRef = await _adminActivityLogsCollection.add({
        'adminId': adminId,
        'adminEmail': admin.email,
        'action': action,
        'itemId': itemId,
        'itemName': itemName,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': ipAddress,
        'success': true,
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to log activity: $e';
    }
  }

  /// Get activity summary for dashboard
  Future<Map<String, dynamic>> getActivitySummary() async {
    try {
      final last24h = DateTime.now().subtract(const Duration(hours: 24));
      final last7d = DateTime.now().subtract(const Duration(days: 7));

      // Get last 24 hours activity
      final todaySnapshot = await _adminActivityLogsCollection
          .where('timestamp', isGreaterThan: last24h)
          .count()
          .get();

      // Get last 7 days activity
      final weekSnapshot = await _adminActivityLogsCollection
          .where('timestamp', isGreaterThan: last7d)
          .count()
          .get();

      // Get total activity
      final totalSnapshot = await _adminActivityLogsCollection.count().get();

      return {
        'last24h': todaySnapshot.count,
        'last7d': weekSnapshot.count,
        'total': totalSnapshot.count,
      };
    } catch (e) {
      return {'last24h': 0, 'last7d': 0, 'total': 0};
    }
  }

  // ============================================================================
  // STATISTICS & REPORTING
  // ============================================================================

  /// Get admin statistics
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final allAdmins = await _adminUsersCollection
          .where('role', isNotEqualTo: null)
          .get();
      final activeAdmins = await _adminUsersCollection
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      final disabledAdmins = await _adminUsersCollection
          .where('status', isEqualTo: 'disabled')
          .count()
          .get();
      final superAdmins = await _adminUsersCollection
          .where('role', isEqualTo: 'super_admin')
          .count()
          .get();

      final totalAdminCount = allAdmins.size;
      final superAdminCount = superAdmins.count ?? 0;

      return {
        'total': totalAdminCount,
        'active': activeAdmins.count ?? 0,
        'disabled': disabledAdmins.count ?? 0,
        'superAdmins': superAdminCount,
        'regularAdmins': totalAdminCount - superAdminCount,
      };
    } catch (e) {
      throw 'Failed to get admin statistics: $e';
    }
  }

  /// Get admin login statistics
  Future<Map<String, dynamic>> getAdminLoginStats(String adminId) async {
    try {
      final admin = await getAdminById(adminId);
      if (admin == null) throw 'Admin not found';

      return {
        'email': admin.email,
        'displayName': admin.displayName,
        'lastLogin': admin.lastLogin,
        'lastLoginFormatted': admin.lastLoginFormatted,
        'createdAt': admin.createdAt,
        'status': admin.status.name,
      };
    } catch (e) {
      throw 'Failed to get login stats: $e';
    }
  }

  // ============================================================================
  // SEARCH & FILTER
  // ============================================================================

  /// Search admins by email or display name
  Future<List<AdminUser>> searchAdmins(String query) async {
    try {
      if (query.isEmpty) {
        return getActiveAdmins();
      }

      final lowercaseQuery = query.toLowerCase();

      // Search by email (requires index)
      final emailSnapshot = await _adminUsersCollection
          .where('email', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('email', isLessThan: '${lowercaseQuery}z')
          .get();

      final results = emailSnapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc))
          .toList();

      // Also search in displayName (client-side filtering)
      final allAdmins = await getActiveAdmins();
      final nameMatches = allAdmins
          .where(
            (admin) =>
                admin.displayName.toLowerCase().contains(lowercaseQuery) &&
                !results.any((r) => r.id == admin.id),
          )
          .toList();

      results.addAll(nameMatches);
      return results;
    } catch (e) {
      throw 'Failed to search admins: $e';
    }
  }

  /// Filter admins by criteria
  Future<List<AdminUser>> filterAdmins({String? status, String? role}) async {
    try {
      Query query = _adminUsersCollection;

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.orderBy('displayName').get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to filter admins: $e';
    }
  }

  // ============================================================================
  // PROFILE & ACCOUNT MANAGEMENT
  // ============================================================================

  /// Update admin profile (displayName, etc.)
  /// Only admins can update their own profile
  /// Super admin can update any admin's profile
  Future<void> updateAdminProfile({
    required String adminId,
    required String displayName,
  }) async {
    try {
      await _adminUsersCollection.doc(adminId).update({'displayName': displayName});

      // Log activity
      await logAdminActivity(
        adminId: adminId,
        action: 'updated_admin_profile',
        itemId: adminId,
        itemName: displayName,
        details: {'targetAdminId': adminId, 'newDisplayName': displayName},
      );
    } catch (e) {
      throw 'Failed to update admin profile: $e';
    }
  }

  /// Mark admin to require password change on next login
  Future<void> requirePasswordChange(String adminId) async {
    try {
      await _adminUsersCollection.doc(adminId).update({
        'requirePasswordChange': true,
      });

      // Log activity
      await logAdminActivity(
        adminId: adminId,
        action: 'required_password_change',
        itemId: adminId,
        details: {'targetAdminId': adminId},
      );
    } catch (e) {
      throw 'Failed to require password change: $e';
    }
  }

  /// Verify admin exists and is active
  Future<bool> isAdminActive(String adminId) async {
    try {
      final admin = await getAdminById(adminId);
      return admin != null && admin.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Check if admin has access to module
  Future<bool> hasModuleAccess(String adminId, String module) async {
    try {
      final admin = await getAdminById(adminId);
      if (admin == null) return false;

      // Try to find matching AdminModule enum
      try {
        final adminModule = AdminModule.values.firstWhere(
          (m) => m.name == module,
        );
        return admin.permissions.hasAccess(adminModule);
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get all modules accessible to admin
  Future<List<String>> getAccessibleModules(String adminId) async {
    try {
      final admin = await getAdminById(adminId);
      if (admin == null) return [];
      return admin.permissions
          .getAccessibleModules()
          .map((m) => m.name)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
