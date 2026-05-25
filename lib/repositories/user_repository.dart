import 'dart:io';

import 'package:shopsnports/models/user.dart';

abstract class UserRepository {
  /// Returns a stream of the currently authenticated user (or null).
  Stream<AppUser?> authStateChanges();

  /// Sign up a user. Implementations should throw on error.
  Future<AppUser> signUp(
      {required String email,
      required String password,
      required String name,
      String? phone});

  /// Sign in an existing user.
  Future<AppUser> signIn({required String email, required String password});

  /// Sign out the current user. Implementations should emit `null` to the
  /// `authStateChanges()` stream so app UI updates accordingly.
  Future<void> signOut();

  /// Fetch user profile by id.
  Future<AppUser?> getProfile(String id);

  /// Update a user's profile. Implementations should update storage and
  /// emit new auth/profile state as appropriate.
  Future<AppUser> updateProfile({required AppUser user});

  /// Set the affiliate approval flag for a given user id. Implementations
  /// should persist the change and emit updated auth/profile state.
  Future<void> setAffiliateApproved(
      {required String uid, required bool approved});

  /// Register a new affiliate account with all required details.
  /// Automatically creates affiliate profile (no approval needed, immediately active).
  Future<AppUser> registerAsAffiliate({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? businessName,
    String? taxId,
    String? bankName,
    String? accountNumber,
    String? countryCode,
  });

  /// Uploads an avatar file for the user and returns a publicly accessible URL.
  /// Implementations may upload to cloud storage and return the remote URL.
  ///
  /// Optional [onProgress] callback receives a double between 0 and 1.
  Future<String> uploadAvatar(
      {required String uid,
      required File file,
      void Function(double progress)? onProgress});
}
