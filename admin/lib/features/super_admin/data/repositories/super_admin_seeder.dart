import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_permissions.dart';

/// Helper to seed super admin profile on first login
class SuperAdminSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update super admin profile in Firestore
  /// Call this after successful authentication
  static Future<void> ensureSuperAdminProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final userDoc = _firestore.collection('admin_users').doc(uid);
      final snapshot = await userDoc.get();

      // If user doc doesn't exist, create it as super admin
      if (!snapshot.exists) {
        await userDoc.set({
          'id': uid,
          'email': email,
          'displayName': displayName,
          'role': 'super_admin',
          'status': 'active',
          'permissions': _defaultSuperAdminPermissions(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
          'requirePasswordChange': false,
        });
      } else {
        // User exists - ensure they have super_admin role
        final data = snapshot.data();
        if (data?['role'] != 'super_admin') {
          // Log this as it might indicate permission issues
          print('Warning: User $uid exists but is not super_admin');
        }
      }
    } catch (e) {
      print('Error seeding super admin profile: $e');
      rethrow;
    }
  }

  /// Get default permissions for super admin (all modules)
  static Map<String, dynamic> _defaultSuperAdminPermissions() {
    final permissions = <String, bool>{};
    for (final module in AdminModule.values) {
      permissions[module.name] = true;
    }
    return {'permissions': permissions};
  }

  /// Check if user needs profile creation
  static Future<bool> needsProfileCreation(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return !doc.exists;
    } catch (e) {
      return false;
    }
  }
}
