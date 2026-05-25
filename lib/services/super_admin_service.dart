import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopsnports/models/admin_user.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';

/// Service for managing Super Admin and Sub Admin accounts
class SuperAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _adminUsersCollection = 'admin_users';
  static const String _activityLogsCollection = 'admin_activity_logs';

  Future<void> ensureSuperAdminProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final docRef = _firestore.collection(_adminUsersCollection).doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final superAdmin = AdminUser(
        id: uid,
        email: email,
        displayName: displayName,
        roleType: UserRoleType.superAdmin,
        status: UserStatus.active,
        permissions: AdminPermission.values.toList(),
        createdAt: DateTime.now(),
        requirePasswordChange: false,
      );

      await docRef.set(superAdmin.toMap());
    }
  }

  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection(_adminUsersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final adminUser = AdminUser.fromMap(doc.data()!, doc.id);
    return adminUser.isSuperAdmin && adminUser.isActive;
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection(_adminUsersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final adminUser = AdminUser.fromMap(doc.data()!, doc.id);
    return adminUser.isActive;
  }

  Future<AdminUser?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(_adminUsersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return AdminUser.fromMap(doc.data()!, doc.id);
  }

  Future<AdminUser?> getAdminById(String uid) async {
    final doc = await _firestore
        .collection(_adminUsersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return AdminUser.fromMap(doc.data()!, doc.id);
  }

  Future<List<AdminUser>> getAllSubAdmins() async {
    final snapshot = await _firestore
        .collection(_adminUsersCollection)
        .where('roleType', isEqualTo: 'subAdmin')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AdminUser.fromMap(doc.data()!, doc.id))
        .toList();
  }

  String _generateTempPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> createSubAdmin({
    required String email,
    required String displayName,
    required String createdBySuperAdminId,
    List<AdminPermission>? permissions,
    String? phone,
    String? department,
    String? notes,
  }) async {
    final tempPassword = _generateTempPassword();

    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: tempPassword,
    );

    final uid = credential.user!.uid;

    final subAdmin = AdminUser(
      id: uid,
      email: email,
      displayName: displayName,
      roleType: UserRoleType.subAdmin,
      status: UserStatus.active,
      permissions: permissions ?? DefaultPermissionSet.shippingManager.permissions,
      createdBy: createdBySuperAdminId,
      createdAt: DateTime.now(),
      phone: phone,
      department: department,
      notes: notes,
      requirePasswordChange: true,
    );

    await _firestore
        .collection(_adminUsersCollection)
        .doc(uid)
        .set(subAdmin.toMap());

    await _logActivity(
      type: 'sub_admin_created',
      performedBy: createdBySuperAdminId,
      targetUserId: uid,
      details: <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'department': department,
        'permissionsCount': permissions?.length ?? 0,
      },
    );

    return {
      'adminUser': subAdmin,
      'tempPassword': tempPassword,
    };
  }

  Future<void> updateSubAdminPermissions({
    required String subAdminId,
    required List<AdminPermission> permissions,
    required String updatedBySuperAdminId,
  }) async {
    final docRef = _firestore.collection(_adminUsersCollection).doc(subAdminId);
    await docRef.update({
      'permissions': permissions.map((p) => p.name).toList(),
    });

    await _logActivity(
      type: 'permissions_updated',
      performedBy: updatedBySuperAdminId,
      targetUserId: subAdminId,
      details: <String, dynamic>{
        'permissionsCount': permissions.length,
      },
    );
  }

  Future<void> suspendSubAdmin({
    required String subAdminId,
    required String suspendedBySuperAdminId,
  }) async {
    await _firestore.collection(_adminUsersCollection).doc(subAdminId).update({
      'status': UserStatus.suspended.name,
    });

    await _logActivity(
      type: 'sub_admin_suspended',
      performedBy: suspendedBySuperAdminId,
      targetUserId: subAdminId,
      details: <String, dynamic>{},
    );
  }

  Future<void> reactivateSubAdmin({
    required String subAdminId,
    required String reactivatedBySuperAdminId,
  }) async {
    await _firestore.collection(_adminUsersCollection).doc(subAdminId).update({
      'status': UserStatus.active.name,
    });

    await _logActivity(
      type: 'sub_admin_reactivated',
      performedBy: reactivatedBySuperAdminId,
      targetUserId: subAdminId,
      details: <String, dynamic>{},
    );
  }

  Future<void> deleteSubAdmin({
    required String subAdminId,
    required String deletedBySuperAdminId,
  }) async {
    final admin = await getAdminById(subAdminId);
    if (admin == null) throw Exception('Admin not found');

    await _firestore.collection(_adminUsersCollection).doc(subAdminId).delete();

    // Note: Firebase Auth user deletion requires Admin SDK or Cloud Functions
    // Client SDK cannot delete users by email for security reasons

    await _logActivity(
      type: 'sub_admin_deleted',
      performedBy: deletedBySuperAdminId,
      targetUserId: subAdminId,
      details: <String, dynamic>{
        'email': admin.email,
      },
    );
  }

  Future<void> updateLastLogin(String adminId) async {
    await _firestore.collection(_adminUsersCollection).doc(adminId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _logActivity({
    required String type,
    required String performedBy,
    String? targetUserId,
    Map<String, dynamic>? details,
  }) async {
    await _firestore.collection(_activityLogsCollection).add({
      'type': type,
      'performedBy': performedBy,
      'targetUserId': targetUserId,
      'details': details ?? <String, dynamic>{},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getActivityLogs({
    String? forUserId,
    String? type,
    int limit = 50,
  }) async {
    Query query = _firestore
        .collection(_activityLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (forUserId != null) {
      query = query.where('performedBy', isEqualTo: forUserId);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}