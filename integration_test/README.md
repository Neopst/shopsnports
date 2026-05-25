This folder contains an end-to-end integration test that exercises email/password auth flows.

Prerequisites
- Flutter SDK installed and on PATH
- Node.js & Firebase CLI (for emulators) installed

Run locally against Firebase emulators
1. Start emulators (Auth + Firestore):

```powershell
cd <repo-root>
firebase emulators:start --only auth,firestore
```

2. Run the integration test:

```powershell
# from repo root
# ensure emulator env var so app initializers use emulator URLs if wired that way
$env:USE_FIREBASE_EMULATOR = '1'
flutter test integration_test/auth_e2e_test.dart
```

Notes
- The test expects certain Widget Keys to exist in the app UI. If your app uses different keys or navigation patterns, update `integration_test/auth_e2e_test.dart` accordingly.
- To run in CI, start the emulators in the job (or use Firebase Test Lab) and run the same flutter test command.
