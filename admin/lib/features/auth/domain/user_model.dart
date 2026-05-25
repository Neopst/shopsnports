import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'super_admin', 'admin', 'support', 'finance'
  final bool isActive;
  final DateTime createdAt;
  final String? photoURL;

  AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.photoURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'photoURL': photoURL,
    };
  }

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'admin',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      photoURL: data['photoURL'],
    );
  }
}
