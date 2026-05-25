# Firestore Production Readiness Checklist

This checklist helps prepare Firestore for production use (staging and prod projects).

1. Security rules
   - Review `firestore.rules.example` and adapt to your collections and claims.
   - Ensure admin actions require `request.auth.token.admin == true` (or equivalent).
   - Disallow client-side creation for sensitive collections (e.g., `shipment_requests`) when appropriate.
   - Deploy rules with `firebase deploy --only firestore:rules` after review.

2. Indexes
   - Keep `firestore.indexes.json` updated with composite indexes required by queries.
   - Deploy indexes using `firebase deploy --only firestore:indexes` or via console.

3. Environment configuration
   - Use separate Firebase projects for staging and production.
   - Generate `firebase_options.dart` for each environment (FlutterFire CLI supports multiple targets) or load config at runtime via env vars.
   - In your app entrypoints, override `firestoreProvider` with the Firestore instance from the correct Firebase app:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(ProviderScope(overrides: [
  firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
], child: const MyApp()));
```

4. Emulator & testing
   - For CI or local tests, use `FakeFirebaseFirestore` or run the Firestore emulator.
   - Provide clear docs and scripts to start emulators for dev/CI.

5. Monitoring & access
   - Enable Firestore usage and billing alerts, logging, and monitoring.
   - Enforce least privilege for service accounts and restrict console access.
