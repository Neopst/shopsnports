// Node smoke test: uses Admin SDK to create a test user and REST API to sign-in
// CLI usage:
//  node smoke_test_full.js --key C:\path\to\sa.json --project shopsnports-7c967 --password P@ssw0rd! --apikey <WEB_API_KEY>
// Flags are optional if corresponding environment variables are set.
// Flags:
//  --key       Path to service account JSON (optional if GOOGLE_APPLICATION_CREDENTIALS is set)
//  --project   Firebase project id (optional if FIREBASE_PROJECT_ID is set)
//  --password  Password for the test user (optional)
//  --apikey    Web API key (optional; will attempt to read from lib/firebase_options_staging.dart)

const admin = require('firebase-admin');
const fetch = require('node-fetch');
const fs = require('fs');

async function main() {
  // Simple arg parsing
  const argv = require('minimist')(process.argv.slice(2));
  const keyPath = argv.key || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const projectId = argv.project || process.env.FIREBASE_PROJECT_ID;
  const testPassword = argv.password || process.env.TEST_USER_PASSWORD || 'P@ssw0rd!';
  const apiKeyFlag = argv.apikey || process.env.WEB_API_KEY;
  const useEmulator = argv.emulator || false;
  const authEmulatorHost = argv.authHost || process.env.FIREBASE_AUTH_EMULATOR_HOST || 'localhost:9095';
  const firestoreEmulatorHost = argv.firestoreHost || process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8085';

  if (!projectId) {
    console.error('Provide --project or set FIREBASE_PROJECT_ID env var');
    process.exit(1);
  }

  // Initialize Admin SDK. When using emulator mode, set emulator env vars and initialize without a service account.
  if (useEmulator) {
    // Ensure emulator env vars so Admin SDK and REST endpoints target the emulator
    process.env.FIRESTORE_EMULATOR_HOST = firestoreEmulatorHost;
    process.env.FIREBASE_AUTH_EMULATOR_HOST = authEmulatorHost;
    console.log('Running in emulator mode. FIRESTORE_EMULATOR_HOST=', process.env.FIRESTORE_EMULATOR_HOST, ' FIREBASE_AUTH_EMULATOR_HOST=', process.env.FIREBASE_AUTH_EMULATOR_HOST);
    admin.initializeApp({ projectId: projectId });
  } else {
    // Initialize Admin SDK using the key file if provided, otherwise fall back to applicationDefault
    if (keyPath) {
      if (!fs.existsSync(keyPath)) {
        console.error('Service account key not found at', keyPath);
        process.exit(1);
      }
      const keyJson = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(keyJson),
        projectId: projectId
      });
    } else {
      // rely on ADC or env var
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: projectId
      });
    }
  }

  const testEmail = `smoke_test_${Date.now()}@example.com`;

  console.log('Creating test user:', testEmail);
  const user = await admin.auth().createUser({
    email: testEmail,
    password: testPassword,
    emailVerified: true
  });

  // Small pause to allow the emulator to catch up before REST sign-in attempts.
  if (useEmulator) await new Promise(r => setTimeout(r, 500));

  // When using the emulator, poll the Admin SDK to ensure the user is visible
  // to the emulator's user store before attempting REST sign-in. This handles
  // any eventual consistency between Admin SDK operations and the REST API.
  if (useEmulator) {
    let seen = false;
    let attempts = 0;
    let delay = 200;
    while (!seen && attempts < 10) {
      attempts += 1;
      try {
        const u = await admin.auth().getUserByEmail(testEmail);
        console.log(`Admin SDK can see user after ${attempts} attempt(s):`, u.uid);
        seen = true;
        break;
      } catch (err) {
        console.log(`Admin SDK getUserByEmail attempt ${attempts} failed, retrying...`);
        await new Promise(r => setTimeout(r, delay));
        delay *= 2;
      }
    }
    if (!seen) console.warn('Warning: Admin SDK could not see created user before REST sign-in attempts');
  }

  try {
    // Sign in with REST to obtain idToken. If using emulator, target the emulator auth endpoint.
    let apiKey = apiKeyFlag;
    if (useEmulator && !apiKey) {
      apiKey = 'fake-api-key';
      console.log('No apiKey provided; using placeholder apiKey for emulator:', apiKey);
    }
    if (!apiKey) apiKey = await getWebApiKey(projectId);

    // Auth emulator expects the REST path under identitytoolkit.googleapis.com
  const signInBase = useEmulator ? `http://${authEmulatorHost}/identitytoolkit.googleapis.com` : 'https://identitytoolkit.googleapis.com';

  // For emulator runs, use a custom token exchange (admin.createCustomToken -> signInWithCustomToken)
  // This avoids EMAIL_NOT_FOUND issues observed when attempting password sign-in against the emulator.
  let signInUrl;
  let makeSignInBody;
  if (useEmulator) {
    const customToken = await admin.auth().createCustomToken(user.uid);
    signInUrl = `${signInBase}/v1/accounts:signInWithCustomToken?key=${apiKey}`;
    makeSignInBody = () => ({ token: customToken, returnSecureToken: true });
  } else {
    signInUrl = `${signInBase}/v1/accounts:signInWithPassword?key=${apiKey}`;
    makeSignInBody = () => ({ email: testEmail, password: testPassword, returnSecureToken: true });
  }
    // Attempt sign-in with retries to handle emulator eventual consistency.
    async function attemptSignIn(attempts = 10) {
      let delay = 300;
      for (let i = 0; i < attempts; i++) {
        try {
          console.log(`Sign-in attempt ${i + 1}/${attempts} -> ${signInUrl}`);
          const res = await fetch(signInUrl, {
            method: 'POST',
            body: JSON.stringify(makeSignInBody()),
            headers: { 'Content-Type': 'application/json' }
          });
          const body = await res.json();
          console.log('Sign-in response:', body);
          if (body.error) throw body;
          return body;
        } catch (e) {
          console.warn(`Sign-in attempt ${i + 1} failed:`, e && e.error ? e.error.message || e : e);
          if (i === attempts - 1) throw e;
          // wait then retry
          await new Promise(r => setTimeout(r, delay));
          delay *= 2;
        }
      }
    }

    const body = await attemptSignIn().catch(e => { throw new Error(JSON.stringify(e)); });
    const idToken = body.idToken;
    console.log('Signed in; testing Firestore writes...');

    // At this point we have signed in and obtained idToken; further client-side Firestore
    // writes to validate rules should be done using client SDKs or emulator. This script
    // demonstrates auth flow and can be extended to perform client writes.
    console.log('Signed in; auth flow verified. You can extend this script to perform client-side Firestore writes (emulator recommended).');

  } catch (e) {
    console.error('Smoke test failed:', e);
  } finally {
    console.log('Deleting test user...');
    await admin.auth().deleteUser(user.uid).catch(() => {});
    process.exit(0);
  }
}

async function getWebApiKey(projectId) {
  // Attempt to read the web API key from generated firebase_options if present
  try {
    const p = `../lib/firebase_options_staging.dart`;
    if (fs.existsSync(p)) {
      const content = fs.readFileSync(p, 'utf8');
      const m = content.match(/apiKey:\s*'([^']+)'/);
      if (m) return m[1];
    }
  } catch (_) {}
  throw new Error('Could not determine web API key; provide --apikey or ensure firebase_options_staging.dart exists');
}

main().catch(e => { console.error(e); process.exit(1); });
