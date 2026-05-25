#!/usr/bin/env node

// Checks that a given email exists in Firebase Authentication using Admin SDK
// Usage: node scripts/check_user.js user@example.com

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, '..', 'shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json');

if (!admin.apps.length) {
  try {
    const svc = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(svc),
      projectId: svc.project_id || 'shopsnports',
    });
  } catch (err) {
    console.error('Failed to initialize admin SDK. Set GOOGLE_APPLICATION_CREDENTIALS or update path.');
    console.error(err.message || err);
    process.exit(1);
  }
}

const email = process.argv[2];
if (!email) {
  console.error('Usage: node scripts/check_user.js <email>');
  process.exit(1);
}

admin.auth().getUserByEmail(email)
  .then(user => {
    console.log('User found:', user.uid, user.email, user.customClaims);
    process.exit(0);
  })
  .catch(err => {
    console.error('Error fetching user:', err.message);
    process.exit(1);
  });
