import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/repositories/firebase_user_repository.dart';
import 'package:shopsnports/providers/firestore_provider.dart';

final firebaseUserRepositoryProvider = Provider<FirebaseUserRepository>((ref) {
  final db = ref.read(firestoreProvider);
  return FirebaseUserRepository(db: db);
});
