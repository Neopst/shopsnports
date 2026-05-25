#!/usr/bin/env node
/**
 * Migrate Firestore documents from `news_ticker` -> `news_items`
 * Usage (PowerShell):
 *  $env:GOOGLE_APPLICATION_CREDENTIALS='C:\projects\shopsnports\shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'
 *  node scripts/migrate_news_ticker_to_news_items.js [--force]
 *
 * By default the script will abort if `news_items` already has documents.
 * Pass `--force` to overwrite/merge existing docs.
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, '..', 'shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json');
const force = process.argv.includes('--force');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Service account JSON not found at:', serviceAccountPath);
  console.error('Set the full path in the environment variable GOOGLE_APPLICATION_CREDENTIALS or place the file at that path.');
  process.exit(1);
}

const svc = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(svc),
  projectId: svc.project_id || 'shopsnports',
});

const db = admin.firestore();

async function migrate() {
  console.log('🔁 Starting migration: news_ticker -> news_items');

  const destSnapshot = await db.collection('news_items').limit(1).get();
  if (!force && destSnapshot.docs.length > 0) {
    console.error('Destination collection `news_items` already contains documents. Use --force to proceed.');
    process.exit(1);
  }

  const srcSnapshot = await db.collection('news_ticker').get();
  if (srcSnapshot.empty) {
    console.log('No documents found in `news_ticker`. Nothing to migrate.');
    return;
  }

  console.log(`Found ${srcSnapshot.size} docs in news_ticker`);

  let migrated = 0;
  for (const doc of srcSnapshot.docs) {
    const data = doc.data();
    // Ensure timestamp fields are Firestore Timestamps when possible
    // (admin SDK preserves them)

    // Use same doc id to preserve references
    await db.collection('news_items').doc(doc.id).set(data, { merge: true });
    console.log(`  → Migrated ${doc.id}`);
    migrated++;
  }

  console.log(`✅ Migration complete. Migrated ${migrated} documents.`);
}

migrate().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
