import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/models/user.dart';
import 'package:shopsnports/repositories/user_repository.dart';
import 'package:shopsnports/repositories/firebase_user_repository.dart';
// Import the Firebase implementation for production use

/// The repository provider. Uses Firebase implementation for real auth persistence.
/// During tests you can override this provider to return a `MockUserRepository`.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository(db: FirebaseFirestore.instance);
});

/// Call this from main.dart (or an environment-specific entrypoint) to
/// switch the app to use the real Firebase-backed repository.
void provideFirebaseUserRepository(ProviderContainer container) {
  // Example usage in main.dart:
  // container.read(userRepositoryProvider.notifier).state =
  //    FirebaseUserRepository();
  // For now we leave this as documentation; tests continue to use the mock.
}

/// Exposes the auth state as an AsyncValue that yields an AppUser or null.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.authStateChanges();
});

/// A convenience provider that reads the current user (if any) synchronously
/// from the latest auth state. Returns null if not available yet.
final currentUserProvider = Provider<AppUser?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(orElse: () => null, data: (d) => d);
});

/// Globally selected role for the current session. This mirrors the
/// user's `activeRole` and persists changes through the `UserRepository`.
final currentRoleProvider =
    StateNotifierProvider<CurrentRoleNotifier, String?>((ref) {
  final user = ref.watch(currentUserProvider);
  final notifier = CurrentRoleNotifier(ref, user?.activeRole);

  // Keep notifier in sync when the authenticated user changes (sign-in / sign-out).
  ref.listen<AppUser?>(currentUserProvider, (previous, next) {
    // If user signed out, ensure role is cleared; if signed in, set initial activeRole.
    try {
      notifier.setRole(next?.activeRole);
    } catch (_) {
      // ignore errors here; persistence may fail in tests or offline.
    }
  });

  return notifier;
});

class CurrentRoleNotifier extends StateNotifier<String?> {
  final Ref _ref;
  CurrentRoleNotifier(this._ref, String? initial) : super(initial);

  Future<void> setRole(String? role) async {
    state = role;
    // Persist to profile when possible
    final user = _ref.read(currentUserProvider);
    final repo = _ref.read(userRepositoryProvider);
    if (user != null) {
      final updated = user.copyWith(activeRole: role);
      try {
        await repo.updateProfile(user: updated);
      } catch (_) {
        // Non-fatal: local state updated even if persistence fails.
      }
    }
  }
}
