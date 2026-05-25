#!/usr/bin/env node
/**
 * Update Firestore banner imageUrl fields to use Firebase Storage paths.
 * 
 * Usage: node scripts/update_banners_to_storage_paths.js
 * 
 * This script:
 * 1. Lists all images in Firebase Storage under banners/
 * 2. Maps current Firestore banners to Storage images by matching on displayOrder or ID
 * 3. Updates Firestore docs with gs:// URLs or relative paths
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
  storageBucket: 'shopsnports.firebasestorage.app',
});

const db = admin.firestore();
const storage = admin.storage();
const bucket = storage.bucket();

async function main() {
  try {
    console.log('📋 Fetching banners from Firestore...');
    const bannersSnap = await db.collection('banners').orderBy('displayOrder').get();
    
    if (bannersSnap.empty) {
      console.log('❌ No banners found in Firestore.');
      process.exit(1);
    }

    console.log(`✅ Found ${bannersSnap.size} banners\n`);

    console.log('🔍 Listing images in Firebase Storage (banners/*)...');
    const [files] = await bucket.getFiles({ prefix: 'banners/' });
    
    console.log(`✅ Found ${files.length} files in banners/ folder\n`);
    files.forEach((f, i) => {
      console.log(`  ${i + 1}. ${f.name}`);
    });

    console.log('\n📝 Mapping Firestore banners to Storage paths...\n');

    const bannerDocs = bannersSnap.docs;
    let updatedCount = 0;

    for (let i = 0; i < bannerDocs.length; i++) {
      const doc = bannerDocs[i];
      const banner = doc.data();
      const displayOrder = banner.displayOrder || i + 1;

      // Try to find a matching image in Storage by displayOrder or ID
      let storageFile = null;
      for (const file of files) {
        const fileName = path.basename(file.name);
        // Match on displayOrder (e.g., "banner_001.jpg" for displayOrder 1)
        if (fileName.includes(`banner_${String(displayOrder).padStart(3, '0')}`)) {
          storageFile = file;
          break;
        }
        // Match on banner ID
        if (fileName.includes(banner.id)) {
          storageFile = file;
          break;
        }
      }

      if (storageFile) {
        // Build a gs:// URL for the Storage object
        const gsUrl = `gs://${bucket.name}/${storageFile.name}`;
        const currentUrl = banner.imageUrl || 'none';

        console.log(`Banner: ${banner.id} (displayOrder=${displayOrder})`);
        console.log(`  Current: ${currentUrl}`);
        console.log(`  Storage: ${storageFile.name}`);
        console.log(`  gs:// URL: ${gsUrl}`);

        // Update the Firestore doc
        await doc.ref.update({
          imageUrl: gsUrl,
          updatedAt: admin.firestore.Timestamp.now(),
        });
        console.log(`  ✅ UPDATED\n`);
        updatedCount++;
      } else {
        console.log(`Banner: ${banner.id} (displayOrder=${displayOrder})`);
        console.log(`  ❌ No matching Storage file found`);
        console.log(`  Current imageUrl: ${banner.imageUrl || 'none'}\n`);
      }
    }

    console.log(`\n✅ Updated ${updatedCount} banners with Storage paths.`);
    console.log('💡 If some banners were not matched, upload the images to Storage');
    console.log('   using the admin dashboard, then run this script again.\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
