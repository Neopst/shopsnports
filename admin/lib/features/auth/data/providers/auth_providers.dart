import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository_firebase.dart';

/// Firebase Auth Repository Provider
final authRepositoryProvider = Provider((ref) {
  return AuthRepositoryFirebase();
});

/// Auth state provider - listens to authentication changes
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Current user provider - shortcut to get current user
final currentUserProvider = Provider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Check if user is super admin
final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user.when(
    data: (authUser) => authUser?.isSuperAdmin ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if user is admin (includes super admin)
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user.when(
    data: (authUser) => authUser?.isAdmin ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Sign up with email and password
final signUpProvider =
    FutureProvider.family<
      AuthUser,
      ({String email, String password, String displayName})
    >((ref, params) async {
      final repository = ref.watch(authRepositoryProvider);
      final user = await repository.signUp(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
      ref.invalidate(authStateProvider);
      return user;
    });

/// Sign in with email and password
final signInProvider =
    FutureProvider.family<AuthUser, ({String email, String password})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      final user = await repository.signIn(
        email: params.email,
        password: params.password,
      );
      ref.invalidate(authStateProvider);
      return user;
    });

/// Sign out
final signOutProvider = FutureProvider((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.signOut();
  ref.invalidate(authStateProvider);
});

/// Send password reset email
final sendPasswordResetProvider = FutureProvider.family<void, String>((
  ref,
  email,
) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.sendPasswordResetEmail(email);
});

/// Reset password
final resetPasswordProvider =
    FutureProvider.family<void, ({String code, String newPassword})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      await repository.resetPassword(
        code: params.code,
        newPassword: params.newPassword,
      );
    });

/// Update user profile
final updateProfileProvider =
    FutureProvider.family<AuthUser, ({String? displayName, String? photoUrl})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      final user = await repository.updateProfile(
        displayName: params.displayName,
        photoUrl: params.photoUrl,
      );
      ref.invalidate(authStateProvider);
      return user;
    });

/// Change password
final changePasswordProvider =
    FutureProvider.family<void, ({String currentPassword, String newPassword})>(
      (ref, params) async {
        final repository = ref.watch(authRepositoryProvider);
        await repository.changePassword(
          currentPassword: params.currentPassword,
          newPassword: params.newPassword,
        );
      },
    );

/// Send email verification
final sendEmailVerificationProvider = FutureProvider((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.sendEmailVerification();
});

/// Enable 2FA
final enable2FAProvider = FutureProvider((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.enable2FA();
  ref.invalidate(authStateProvider);
});

/// Disable 2FA
final disable2FAProvider = FutureProvider((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.disable2FA();
  ref.invalidate(authStateProvider);
});

/// Get user by UID
final userByIdProvider = FutureProvider.family<AuthUser?, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserById(uid);
});

/// Get all users (admin only)
final allUsersProvider = FutureProvider<List<AuthUser>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAllUsers();
});

/// Update user role (admin only)
final updateUserRoleProvider =
    FutureProvider.family<void, ({String uid, String role})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      await repository.updateUserRole(params.uid, params.role);
      ref.invalidate(allUsersProvider);
      ref.invalidate(userByIdProvider(params.uid));
    });

/// Update user permissions (admin only)
final updateUserPermissionsProvider =
    FutureProvider.family<void, ({String uid, List<String> permissions})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      await repository.updateUserPermissions(params.uid, params.permissions);
      ref.invalidate(allUsersProvider);
      ref.invalidate(userByIdProvider(params.uid));
    });

/// Suspend user (admin only)
final suspendUserProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.suspendUser(uid);
  ref.invalidate(allUsersProvider);
  ref.invalidate(userByIdProvider(uid));
});

/// Reactivate user (admin only)
final reactivateUserProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.reactivateUser(uid);
  ref.invalidate(allUsersProvider);
  ref.invalidate(userByIdProvider(uid));
});

/// Delete user (admin only)
final deleteUserProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.deleteUser(uid);
  ref.invalidate(allUsersProvider);
});
