import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// App-wide Firestore provider.
///
/// Purpose:
/// - Avoid referencing `FirebaseFirestore.instance` at import time so tests
///   can override this provider without requiring Firebase initialization.
/// - Encourage explicit wiring of the production Firestore instance in the
///   app entrypoint (see example below).
///
/// Usage (production):
/// In your `main()` or environment-specific entrypoint, initialize Firebase
/// and then provide the real instance via `ProviderScope.overrides`:
///
/// ProviderScope(
///   overrides: [
///     firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
///   ],
///   child: const MyApp(),
/// );
///
/// Usage (tests): override `firestoreProvider` with a `FakeFirebaseFirestore`.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  throw StateError(
      'firestoreProvider was not initialized. In production add an override to ProviderScope with `firestoreProvider.overrideWithValue(FirebaseFirestore.instance)`, or override this provider in tests.');
});
