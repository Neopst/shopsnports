import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_user.dart';

/// Firebase Authentication Repository
class AuthRepositoryFirebase {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryFirebase({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  /// Get current authenticated user
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _convertFirebaseUser(user);
  }

  /// Stream of authentication state changes
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _getUserFromFirestore(user.uid);
    });
  }

  /// Sign up with email and password (ADMIN-ONLY - Super Admin creates accounts)
  /// This method is disabled for public use. Use SuperAdminCreateAdminScreen instead.
  @Deprecated(
    'Public signup disabled. Use SuperAdminCreateAdminScreen for admin creation.',
  )
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // SECURITY: Public signup is disabled for admin dashboard
    // Only super admins can create accounts via SuperAdminCreateAdminScreen
    throw Exception(
      'Public signup is disabled. Please contact an administrator to create an account.',
    );
  }

  /// Create admin user (Super Admin only - internal use)
  /// Used by SuperAdminCreateAdminScreen to create new admin accounts
  Future<AuthUser> createAdminUser({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'admin' or 'super_admin'
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore with specified role
      final authUser = AuthUser(
        uid: user.uid,
        email: email,
        displayName: displayName,
        emailVerified: false,
        createdAt: DateTime.now(),
        role: role, // Admin or super_admin role
        isActive: true,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(authUser.toJson());

      // Send email verification
      await user.sendEmailVerification();

      return authUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Sign in failed');

      // Update last sign in time
      final authUser = await _getUserFromFirestore(user.uid);
      if (authUser != null) {
        await _firestore.collection(_usersCollection).doc(user.uid).update({
          'lastSignInAt': DateTime.now().toIso8601String(),
        });
        return authUser.copyWith(lastSignInAt: DateTime.now());
      }

      return _convertFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reset password with code
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<AuthUser> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      final authUser = await _getUserFromFirestore(user.uid);
      if (authUser != null) {
        return authUser;
      }

      return _convertFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      if (user.email == null) throw Exception('User email not found');

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Enable 2FA (Time-based One-Time Password)
  Future<void> enable2FA() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Update user document
      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'twoFactorEnabled': true,
      });
    } catch (e) {
      throw Exception('Failed to enable 2FA: $e');
    }
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'twoFactorEnabled': false,
      });
    } catch (e) {
      throw Exception('Failed to disable 2FA: $e');
    }
  }

  /// Get user by UID
  Future<AuthUser?> getUserById(String uid) async {
    try {
      return await _getUserFromFirestore(uid);
    } catch (e) {
      return null;
    }
  }

  /// Get all users (admin only)
  Future<List<AuthUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      return snapshot.docs
          .map((doc) => AuthUser.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Update user permissions (admin only)
  Future<void> updateUserPermissions(
    String uid,
    List<String> permissions,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'permissions': permissions,
      });
    } catch (e) {
      throw Exception('Failed to update user permissions: $e');
    }
  }

  /// Suspend user account (admin only)
  Future<void> suspendUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Reactivate user account (admin only)
  Future<void> reactivateUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to reactivate user: $e');
    }
  }

  /// Delete user account (admin only)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      // Note: Firebase Auth user deletion should be done via Firebase Console
      // or with admin privileges
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Helper: Get user from Firestore
  Future<AuthUser?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      return AuthUser.fromJson({...doc.data()!, 'uid': uid});
    } catch (e) {
      return null;
    }
  }

  /// Helper: Convert Firebase User to AuthUser
  AuthUser _convertFirebaseUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSignInAt: user.metadata.lastSignInTime,
      isActive: true,
    );
  }

  /// Helper: Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'operation-not-allowed':
        return Exception('Operation not allowed. Please contact support.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'user-not-found':
        return Exception('User not found.');
      case 'wrong-password':
        return Exception('Wrong password provided for that user.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}
