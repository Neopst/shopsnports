import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopsnports/models/user.dart';
import 'package:shopsnports/models/roles_and_permissions.dart';
import 'package:shopsnports/repositories/user_repository.dart';
import 'package:shopsnports/services/storage_service.dart';

/// Production implementation that uses Firebase Auth + Firestore + Storage.
class FirebaseUserRepository implements UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<User?>? _authSub;

  FirebaseUserRepository({FirebaseAuth? auth, required FirebaseFirestore db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db {
    _authSub = _auth.authStateChanges().listen((u) async {
      if (u == null) {
        _controller.add(null);
        return;
      }

      // fetch user profile from Firestore (customers collection)
      final doc = await _db.collection('customers').doc(u.uid).get();

      // Auto-create customer document if it doesn't exist
      if (!doc.exists) {
        // Auto-create customer document
        await _db.collection('customers').doc(u.uid).set({
          'name': u.displayName ?? u.email ?? '',
          'email': u.email ?? '',
          'phone': u.phoneNumber ?? '',
          'avatarUrl': u.photoURL ?? '',
          'status': 'active',
          'roleType': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      if (doc.exists) {
        final data = doc.data()!;
        final appUser = _parseAppUser(u.uid, data, u.displayName, u.email);
        _controller.add(appUser);
      } else {
        // Build from the auth user
        _controller.add(_parseAppUser(u.uid, {}, u.displayName, u.email));
      }
    });
  }

  /// Parse AppUser from Firestore data
  AppUser _parseAppUser(
    String uid,
    Map<String, dynamic> data,
    String? displayName,
    String? email,
  ) {
    return AppUser(
      id: uid,
      name: data['name'] ?? displayName ?? '',
      email: data['email'] ?? email ?? '',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      gender: data['gender'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      roleType: _parseRoleType(data['roleType']),
      status: _parseStatus(data['status']),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseTimestamp(data['lastLogin']),
      businessName: data['businessName'] as String?,
      bankName: data['bankName'] as String?,
      accountName: data['accountName'] as String?,
      accountNumber: data['accountNumber'] as String?,
      taxId: data['taxId'] as String?,
      affiliateApproved: data['affiliateApproved'] as bool? ?? false,
      affiliateId: data['affiliateId'] as String?,
      affiliateCode: data['affiliateCode'] as String?,
      commissionRate: (data['commissionRate'] as num?)?.toDouble(),
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (data['pendingPayout'] as num?)?.toDouble() ?? 0.0,
    );
  }

  UserRoleType _parseRoleType(dynamic value) {
    if (value == null) return UserRoleType.customer;
    if (value is UserRoleType) return value;
    if (value is String) {
      return UserRoleType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRoleType.customer,
      );
    }
    return UserRoleType.customer;
  }

  UserStatus _parseStatus(dynamic value) {
    if (value == null) return UserStatus.active;
    if (value is UserStatus) return value;
    if (value is String) {
      return UserStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserStatus.active,
      );
    }
    return UserStatus.active;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final u = cred.user!;

    // Get or create customer document
    final doc = await _db.collection('customers').doc(u.uid).get();

    // If customer document doesn't exist, create it automatically
    if (!doc.exists) {
      await _db.collection('customers').doc(u.uid).set({
        'name': u.displayName ?? u.email ?? '',
        'email': u.email ?? '',
        'phone': u.phoneNumber ?? '',
        'avatarUrl': u.photoURL ?? '',
        'status': 'active',
        'roleType': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await _db.collection('customers').doc(u.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    final data = doc.data() ?? {};
    final appUser = _parseAppUser(u.uid, data, u.displayName, u.email);
    _controller.add(appUser);
    return appUser;
  }

  @override
  Future<AppUser> signUp(
      {required String email,
      required String password,
      required String name,
      String? phone}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final u = cred.user!;

    try {
      // Single source of truth: write ONLY to customers/ collection
      await _db.collection('customers').doc(u.uid).set({
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'status': 'active',
        'roleType': 'customer',
        'avatarUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }

    final appUser = _parseAppUser(u.uid, {
      'name': name,
      'email': email,
      'phone': phone,
      'affiliateApproved': false,
    }, null, email);
    _controller.add(appUser);
    return appUser;
  }

  @override
  Future<AppUser?> getProfile(String id) async {
    final doc = await _db.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return _parseAppUser(id, data, null, null);
  }

  @override
  Future<AppUser> updateProfile({required AppUser user}) async {
    // Write to customers collection (single source of truth)
    await _db.collection('customers').doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'phone': user.phone ?? '',
      'avatarUrl': user.avatarUrl ?? '',
      'address': user.address,
      'gender': user.gender,
      'businessName': user.businessName,
      'bankName': user.bankName,
      'accountName': user.accountName,
      'accountNumber': user.accountNumber,
      'taxId': user.taxId,
      'affiliateApproved': user.affiliateApproved,
      'affiliateId': user.affiliateId,
      'affiliateCode': user.affiliateCode,
      'commissionRate': user.commissionRate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _controller.add(user);
    return user;
  }

  @override
  Future<void> setAffiliateApproved(
      {required String uid, required bool approved}) async {
    await _db.collection('customers').doc(uid).set({
      'affiliateApproved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // If the currently observed user is the one updated, emit a fresh AppUser
    final current = _auth.currentUser;
    if (current != null && current.uid == uid) {
      final doc = await _db.collection('customers').doc(uid).get();
      final data = doc.data() ?? {};
      final appUser = _parseAppUser(uid, data, null, null);
      _controller.add(appUser);
    }
  }

  /// Register a new affiliate account with all required details
  @override
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
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final u = cred.user!;

    // Create user document with affiliate role (auto-approved)
    await _db.collection('customers').doc(u.uid).set({
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'businessName': businessName,
      'taxId': taxId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'countryCode': countryCode,
      'roleType': 'affiliate',
      'affiliateApproved': true,
      'affiliateId': u.uid,
      'affiliateCode': 'AFF${u.uid.substring(0, 6).toUpperCase()}',
      'commissionRate': 0.15,
      'totalEarnings': 0.0,
      'pendingPayout': 0.0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create affiliate profile document
    await _db.collection('affiliates').doc(u.uid).set({
      'uid': u.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'taxId': taxId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'countryCode': countryCode,
      'status': 'active',
      'totalEarnings': 0.0,
      'commissionRate': 0.15,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final appUser = _parseAppUser(u.uid, {
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'taxId': taxId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'affiliateApproved': true,
      'affiliateId': u.uid,
      'roleType': 'affiliate',
    }, null, email);
    _controller.add(appUser);
    return appUser;
  }

  @override
  Future<String> uploadAvatar(
      {required String uid,
      required File file,
      void Function(double progress)? onProgress}) async {
    return await StorageService.uploadAvatar(
        uid: uid, file: file, onProgress: onProgress);
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      _controller.add(null);
    }
  }

  void dispose() {
    _authSub?.cancel();
    _controller.close();
  }
}