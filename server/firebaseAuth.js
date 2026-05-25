const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK if not already initialized.
// Supports three modes:
// 1. FIREBASE_SERVICE_ACCOUNT_JSON: JSON string of service account credentials
// 2. FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY: Individual env vars (ECS format)
// 3. GOOGLE_APPLICATION_CREDENTIALS: path to service account JSON (ADC)
function initFirebase() {
  if (admin.apps && admin.apps.length) return;

  const svcJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const adc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  try {
    // Method 1: JSON string (for local .env)
    if (svcJson) {
      const obj = JSON.parse(svcJson);
      admin.initializeApp({ credential: admin.credential.cert(obj) });
      console.log('✅ Firebase Admin initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
      return;
    }

    // Method 2: Individual environment variables (for ECS/AWS)
    if (projectId && clientEmail && privateKey) {
      const serviceAccount = {
        projectId: projectId,
        clientEmail: clientEmail,
        privateKey: privateKey.replace(/\\n/g, '\n'), // Handle escaped newlines
      };
      admin.initializeApp({ 
        credential: admin.credential.cert(serviceAccount),
        projectId: projectId
      });
      console.log('✅ Firebase Admin initialized from individual env vars (ECS mode)');
      console.log(`   Project: ${projectId}`);
      return;
    }

    // Method 3: Application Default Credentials
    if (adc && fs.existsSync(path.resolve(adc))) {
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
      console.log('✅ Firebase Admin initialized using Application Default Credentials');
      return;
    }

    // Fallback: try default init (will likely fail)
    admin.initializeApp();
    console.warn('⚠️  Firebase Admin initialized with default config (no credentials found)');
  } catch (e) {
    console.error('❌ Failed to initialize Firebase Admin:', e && e.message ? e.message : e);
  }
}

// Middleware to verify Firebase ID token from Authorization: Bearer <token>
async function verifyFirebaseIdToken(req, res, next) {
  initFirebase();
  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!idToken) return res.status(401).json({ error: 'Missing auth token' });

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    // Attach Firebase identity to request
    req.user = { uid: decoded.uid, email: decoded.email };
    // Optionally set session admin flag if user exists in admins table
    try {
      const db = require('./db');
      if (db && typeof db.findAdminByFirebaseUid === 'function') {
        const adminRow = await db.findAdminByFirebaseUid(decoded.uid);
        if (adminRow) {
          // set session admin marker for cookie-based access
          if (req.session) req.session.admin = { uid: decoded.uid, role: adminRow.role };
          req.user.role = adminRow.role;
        }
      }
    } catch (e) {
      // don't block on DB checks; just continue with token verified
      console.warn('admin lookup failed', e && e.message ? e.message : e);
    }

    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { initFirebase, verifyFirebaseIdToken };
