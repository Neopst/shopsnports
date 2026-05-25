#!/usr/bin/env node

/**
 * Migration: add "category" field to existing shippingRequests documents.
 *
 * - category = 'affiliate' if affiliateId is non-null
 * - else 'customer' if requesterId is non-empty
 * - else 'guest'
 *
 * Usage: node scripts/add_category_to_shipping_requests.js
 */

const admin = require('firebase-admin');
const path = require('path');

// initialize with service account (same as other scripts)
const serviceAccountPath = path.join(__dirname, '../functions/serviceAccountKey.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });
  console.log('✅ Firebase Admin initialized');
} catch (e) {
  console.error('❌ Admin init error', e.message);
  process.exit(1);
}

const db = admin.firestore();

async function run() {
  const col = db.collection('shippingRequests');
  const snapshot = await col.get();
  console.log(`🔍 Found ${snapshot.size} documents`);

  let updated = 0;
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const existing = data.category;
    let cat = 'guest';
    if (data.affiliateId) {
      cat = 'affiliate';
    } else if (data.requesterId) {
      cat = 'customer';
    }

    if (existing !== cat) {
      batch.update(doc.ref, { category: cat });
      updated++;
      console.log(` - will update ${doc.id}: ${existing} → ${cat}`);
    }
  });

  if (updated > 0) {
    console.log(`📦 Applying updates (${updated} docs)`);
    await batch.commit();
    console.log('✅ Migration complete');
  } else {
    console.log('✅ Nothing to update');
  }

  process.exit(0);
}

run().catch((e) => {
  console.error('Migration failed', e);
  process.exit(1);
});