# Smoke test (Node) — Admin SDK + REST

This smoke test creates a temporary test user via the Admin SDK, signs in via the REST API, and validates basic authentication flows.

Prerequisites:
- Node.js (16+)
- npm
- A service account JSON with permissions for the Firebase project
- `lib/firebase_options_staging.dart` must exist (to extract web API key) OR set API key in the script

Setup:

1. Install dependencies:

```powershell
cd scripts
npm install
```

2. Run with CLI flags (recommended) or environment variables (alternate):

CLI flags example:

```powershell
cd scripts
node smoke_test_full.js --key C:\path\to\serviceAccount.json --project shopsnports-7c967 --password P@ssw0rd! --apikey <WEB_API_KEY>
```

Environment variables example:

```powershell
cd scripts
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccount.json'
$env:FIREBASE_PROJECT_ID = 'shopsnports-7c967'
# optional: $env:TEST_USER_PASSWORD = 'YourPassw0rd!'
node smoke_test_full.js
```

What it does:
- Creates a temporary user with a random email
- Signs in (REST) to validate auth flows
- (Placeholder) demonstrates where you'd add client-side Firestore writes to test rules
- Deletes the temporary user

Notes:
- For full Firestore rules testing, consider running tests against the Firestore emulator or using the client SDK to verify actual rule enforcement.
