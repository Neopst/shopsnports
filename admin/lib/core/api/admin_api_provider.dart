import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/super_admin/data/repositories/super_admin_repository_firestore.dart';

/// Provider for SuperAdminRepositoryFirestore with authentication context
final superAdminRepositoryProvider = Provider<SuperAdminRepositoryFirestore>((ref) {
  return SuperAdminRepositoryFirestore();
});

/// Provider to get current admin user from Firestore
final currentAdminProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final repository = ref.watch(superAdminRepositoryProvider);
  return repository.getAdminById(user.uid);
});