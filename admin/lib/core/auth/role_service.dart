// lib/core/auth/role_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// RoleService determines the role of the currently logged-in user.
/// Looks up the user's role from Firestore admin_users collection.
class RoleService {
  static Future<String?> getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Check Firebase custom claims first (set by Cloud Functions)
    final idTokenResult = await user.getIdTokenResult();
    if (idTokenResult.claims?.containsKey('admin') == true) {
      return 'admin';
    }

    // Fall back to Firestore lookup
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return doc.data()?['role'] as String?;
    } catch (e) {
      AppLogger.error('RoleService: Error fetching role: $e', tag: 'Auth');
      return null;
    }
  }

  /// Check if current user is a super admin
  static Future<bool> isSuperAdmin() async {
    final role = await getRole();
    return role == 'super_admin';
  }

  /// Check if current user has a specific permission
  static Future<bool> hasPermission(String permission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return false;
      final permissions = doc.data()?['permissions'] as Map<String, dynamic>?;
      return permissions?[permission] == true;
    } catch (e) {
      AppLogger.error('RoleService: Error checking permission: $e', tag: 'Auth');
      return false;
    }
  }
}
