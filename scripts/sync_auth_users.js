#!/usr/bin/env node

/**
 * Simple script to sync Firebase Auth users to Firestore customers collection
 * Run with: node scripts/sync_auth_users.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// This uses the GOOGLE_APPLICATION_CREDENTIALS environment variable
// Set it with: $env:GOOGLE_APPLICATION_CREDENTIALS="path/to/shopsnports-firebase-key.json"
try {
  admin.initializeApp();
} catch (err) {
  console.error('❌ Firebase init failed. Make sure GOOGLE_APPLICATION_CREDENTIALS is set.');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

async function syncAuthUsers() {
  try {
    console.log('🔄 Syncing Firebase Auth users to customers collection...\n');

    let synced = 0;
    let skipped = 0;
    let failed = 0;

    let pageToken = undefined;
    let totalProcessed = 0;

    do {
      const result = await auth.listUsers(1000, pageToken);
      console.log(`📦 Processing batch of ${result.users.length} users...`);

      for (const userRecord of result.users) {
        totalProcessed++;

        try {
          // Check if customer document already exists
          const customerDoc = await db
            .collection('customers')
            .doc(userRecord.uid)
            .get();

          if (customerDoc.exists) {
            console.log(`   ⏭️  ${userRecord.email} (already exists)`);
            skipped++;
            continue;
          }

          // Create customer document from auth user
          const customerData = {
            id: userRecord.uid,
            name: userRecord.displayName || userRecord.email.split('@')[0],
            email: userRecord.email,
            phone: userRecord.phoneNumber || '',
            avatarUrl: userRecord.photoURL || '',
            status: 'active',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLogin: admin.firestore.FieldValue.serverTimestamp(),
          };

          await db.collection('customers').doc(userRecord.uid).set(customerData);
          console.log(`   ✅ ${userRecord.email}`);
          synced++;
        } catch (err) {
          console.error(`   ❌ Error syncing ${userRecord.email}: ${err.message}`);
          failed++;
        }
      }

      pageToken = result.pageToken;
    } while (pageToken);

    console.log(`\n✅ Sync Complete!`);
    console.log(`   Total Processed: ${totalProcessed}`);
    console.log(`   ✅ Synced: ${synced}`);
    console.log(`   ⏭️  Already Existed: ${skipped}`);
    console.log(`   ❌ Failed: ${failed}`);

    process.exit(0);
  } catch (err) {
    console.error('❌ Sync failed:', err.message);
    process.exit(1);
  }
}

syncAuthUsers();
