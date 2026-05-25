import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/models/user.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';
import 'package:shopsnports/repositories/user_repository.dart';
import 'package:shopsnports/services/customer_email_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final firebaseUserProvider = StreamProvider<User?>((ref) {
  final svc = ref.watch(authServiceProvider);
  return svc.authStateChanges();
});

// Example notifier for sign-in actions (optional)
final authActionsProvider = Provider((ref) {
  final svc = ref.read(authServiceProvider);
  final repo = ref.read(userRepositoryProvider);
  return AuthActions(svc, repo);
});

class AuthActions {
  final AuthService _svc;
  final UserRepository _repo;
  final CustomerEmailService _emailService;

  AuthActions(this._svc, this._repo)
      : _emailService = CustomerEmailService();

  Future<User?> signIn(String email, String pwd) => _svc.signIn(email, pwd);

  /// Registration helper used across multiple screens. This creates the
  /// Firebase Auth user and then writes a minimal profile document using
  /// the configured UserRepository. This avoids creating duplicate auth
  /// accounts while ensuring the profile exists for downstream screens.
  Future<User?> register(String name, String email, String pwd,
      {String? phone,
      String? officePhone,
      String? mobilePhone,
      String? role,
      // vendor fields
      String? businessName,
      String? bankName,
      String? accountName,
      String? accountNumber,
      String? taxId}) async {
    final user = await _svc.register(email, pwd);
    if (user == null) return null;

    // Persist an initial profile document (best-effort). Implementations
    // of UserRepository.updateProfile should merge fields when appropriate.
    try {
      final profile = AppUser(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        roleType: UserRoleType.customer,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        businessName: businessName,
        bankName: bankName,
        accountName: accountName,
        accountNumber: accountNumber,
        taxId: taxId,
        affiliateApproved: false,
        affiliateId: null,
      );
      await _repo.updateProfile(user: profile);

      // Welcome email is sent by Cloud Functions (onUserCreated trigger)
      // No need to send it here to avoid duplicates
    } catch (e) {
      // Non-fatal: profile persistence shouldn't block registration.
      // Caller can complete profile later via profile screen.
    }

    return user;
  }

  Future<void> signOut() async {
    // Prefer signOutAll (clears Firebase and OAuth provider sessions) when available.
    try {
      await _svc.signOutAll();
    } catch (_) {
      // If signOutAll fails for any reason, fall back to single-provider signOut.
      try {
        await _svc.signOut();
      } catch (_) {
        // Swallow errors: sign-out should be best-effort and UI already
        // checks auth state stream for final status. Let callers decide
        // whether to display an error message.
      }
    }
    // Ensure repository also clears profile state (important for MockUserRepository).
    try {
      await _repo.signOut();
    } catch (_) {}
  }

  Future<void> sendPasswordReset(String email) => _svc.sendPasswordReset(email);

  Future<void> resendEmailVerification() => _svc.resendEmailVerification();

  Future<User?> signInWithGoogle() => _svc.signInWithGoogle();

  Future<String?> startPhoneVerification(String phone) =>
      _svc.startPhoneVerification(phone);

  Future<User?> signInWithSmsCode(String verificationId, String smsCode) =>
      _svc.signInWithSmsCode(verificationId, smsCode);
}
