import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUserAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admin_users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final isAdmin = await isUserAdmin(userCredential.user!.uid);
      if (!isAdmin) {
        await _auth.signOut();
        throw Exception('Access denied. Admin privileges required.');
      }

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
