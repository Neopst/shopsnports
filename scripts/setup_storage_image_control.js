#!/usr/bin/env node
/**
 * Update Firestore banners to use Firebase Storage paths.
 * This allows the user to manage images via Firebase console.
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
  storageBucket: 'shopsnports.firebasestorage.app',
});

const db = admin.firestore();

// Storage relative paths - user will upload images to these paths
const BANNER_STORAGE_PATHS = {
  1: 'banners/fast-shipping.jpg',
  2: 'banners/competitive-rates.jpg',
  3: 'banners/real-time-tracking.jpg',
  4: 'banners/affiliate-program.jpg',
};

async function main() {
  try {
    console.log('🔄 Updating Firestore banners to use Firebase Storage paths...\n');
    const bannersSnap = await db.collection('banners').orderBy('displayOrder').get();

    if (bannersSnap.empty) {
      console.log('❌ No banners found.');
      process.exit(1);
    }

    let updatedCount = 0;

    for (const doc of bannersSnap.docs) {
      const banner = doc.data();
      const order = banner.displayOrder || 1;
      const storagePath = BANNER_STORAGE_PATHS[order];

      const oldUrl = banner.imageUrl || 'none';
      console.log(`Banner ${order}: ${banner.id}`);
      console.log(`  Old: ${oldUrl}`);
      console.log(`  New: ${storagePath}`);

      await doc.ref.update({
        imageUrl: storagePath,
        updatedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`  ✅ UPDATED\n`);
      updatedCount++;
    }

    console.log(`✅ Updated ${updatedCount}/${bannersSnap.size} banners.\n`);

    console.log('📝 NEXT STEPS:\n');
    console.log('1️⃣  Go to: https://console.firebase.google.com');
    console.log('2️⃣  Select "shopsnports" project');
    console.log('3️⃣  Click Storage → Start');
    console.log('4️⃣  Create a "banners/" folder');
    console.log('5️⃣  Upload these files to that folder:');
    console.log('    • fast-shipping.jpg');
    console.log('    • competitive-rates.jpg');
    console.log('    • real-time-tracking.jpg');
    console.log('    • affiliate-program.jpg\n');
    console.log('6️⃣  Run your mobile app - images will load automatically!\n');

    console.log('✅ The mobile app will:');
    console.log('   • Read Firestore banners');
    console.log('   • Resolve Storage paths automatically');
    console.log('   • Display your uploaded images\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
