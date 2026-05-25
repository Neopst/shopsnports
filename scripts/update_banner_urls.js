#!/usr/bin/env node
/**
 * Quick script to update Firestore banners with new imageUrl values.
 * Useful for testing with placeholder URLs or Storage paths.
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
});

const db = admin.firestore();

// Define new image URLs for each banner (by displayOrder)
const BANNER_UPDATES = {
  1: 'https://picsum.photos/800/300?random=1',   // Works in emulator
  2: 'https://picsum.photos/800/300?random=2',
  3: 'https://picsum.photos/800/300?random=3',
  4: 'https://picsum.photos/800/300?random=4',
};

async function main() {
  try {
    console.log('📋 Fetching banners from Firestore...');
    const bannersSnap = await db.collection('banners').orderBy('displayOrder').get();

    if (bannersSnap.empty) {
      console.log('❌ No banners found.');
      process.exit(1);
    }

    console.log(`✅ Found ${bannersSnap.size} banners\n`);
    let updatedCount = 0;

    for (const doc of bannersSnap.docs) {
      const banner = doc.data();
      const order = banner.displayOrder || 1;
      const newUrl = BANNER_UPDATES[order];

      if (newUrl) {
        const oldUrl = banner.imageUrl || 'none';
        console.log(`Banner ${order}: ${banner.id}`);
        console.log(`  Old: ${oldUrl}`);
        console.log(`  New: ${newUrl}`);

        await doc.ref.update({
          imageUrl: newUrl,
          updatedAt: admin.firestore.Timestamp.now(),
        });

        console.log(`  ✅ UPDATED\n`);
        updatedCount++;
      }
    }

    console.log(`✅ Updated ${updatedCount}/${bannersSnap.size} banners.`);
    console.log('\n💡 To use Firebase Storage images instead:');
    console.log('   1. Upload images to Firebase Storage (console.firebase.google.com)');
    console.log('   2. Set imageUrl to gs://shopsnports.firebasestorage.app/path/to/image.jpg');
    console.log('   3. Re-run this script with updated BANNER_UPDATES object\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
