import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  Future<User?> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() => _auth.signOut();

  /// Sign out from Firebase and any connected OAuth providers (Google).
  Future<void> signOutAll() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore if GoogleSignIn isn't configured on the platform.
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await GoogleSignIn().signOut();

      // Trigger the Google Sign-In flow - this will show the account picker
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user aborted

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } catch (e) {
      // Re-throw so callers can display an error message
      rethrow;
    }
  }

  Future<String?> startPhoneVerification(String phone) async {
    final completer = Completer<String?>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification on some devices.
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete('AUTO_SIGN_IN');
        } catch (e) {
          AppLogger.error('Phone auto verification failed', e);
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        AppLogger.error('Phone verification failed: ${e.message}', e);
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  Future<User?> signInWithSmsCode(String verificationId, String smsCode) async {
    // Attempt to sign in using verificationId/smsCode where possible.
    try {
      final cred = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode),
      );
      return cred.user;
    } catch (e) {
      AppLogger.error('SMS code sign in failed', e);
      return null;
    }
  }
}
