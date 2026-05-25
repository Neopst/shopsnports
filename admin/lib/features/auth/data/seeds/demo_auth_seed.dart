/// Firebase Auth Demo Data Seeder
/// Run this once to set up demo credentials for testing
/// Email: demo@example.com
/// Password: Demo@123456
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_user.dart';

Future<void> seedDemoAuthUser() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  const String demoEmail = 'demo@example.com';
  const String demoPassword = 'Demo@123456';

  try {
    // Check if user already exists
    try {
      await auth.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      print('Demo user already exists');
      return;
    } catch (e) {
      // User doesn't exist, create it
    }

    // Create user account
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: demoEmail,
      password: demoPassword,
    );

    final user = userCredential.user;
    if (user == null) throw Exception('User creation failed');

    // Update display name
    await user.updateDisplayName('Demo Admin');

    // Create user document in Firestore with super admin role
    final demoUser = AuthUser(
      uid: user.uid,
      email: demoEmail,
      displayName: 'Demo Admin',
      emailVerified: true,
      createdAt: DateTime.now(),
      role: 'super_admin',
      permissions: [
        'create_admin',
        'delete_admin',
        'manage_content',
        'manage_settings',
        'manage_news',
        'view_analytics',
        'manage_users',
      ],
      twoFactorEnabled: false,
      isActive: true,
    );

    await firestore.collection('users').doc(user.uid).set(demoUser.toJson());

    print('Demo user seeded successfully!');
    print('Email: $demoEmail');
    print('Password: $demoPassword');
    print('Role: Super Admin');

    // Sign out the demo user
    await auth.signOut();
  } catch (e) {
    print('Error seeding demo user: $e');
  }
}
