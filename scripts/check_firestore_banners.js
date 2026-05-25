#!/usr/bin/env node
/**
 * Check current Firestore banner imageUrl values.
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
const storage = admin.storage().bucket('shopsnports.firebasestorage.app');

async function main() {
  try {
    console.log('📋 Firestore Banners:\n');
    const bannersSnap = await db.collection('banners').orderBy('displayOrder').get();

    if (bannersSnap.empty) {
      console.log('❌ No banners found.\n');
      process.exit(1);
    }

    bannersSnap.forEach((doc) => {
      const banner = doc.data();
      console.log(`ID: ${banner.id}`);
      console.log(`  Title: ${banner.title}`);
      console.log(`  ImageURL: ${banner.imageUrl}`);
      console.log(`  IsActive: ${banner.isActive}\n`);
    });

    console.log('\n📂 Firebase Storage Contents:\n');
    const [files] = await storage.getFiles({ maxResults: 100 });

    if (files.length === 0) {
      console.log('❌ Storage is EMPTY - no images uploaded yet.\n');
      console.log('✅ ACTION REQUIRED:');
      console.log('   1. Go to https://console.firebase.google.com');
      console.log('   2. Select "shopsnports" project');
      console.log('   3. Click Storage → Start → Upload images to banners/ folder');
      console.log('   4. Then update Firestore imageUrl fields to point to Storage\n');
    } else {
      console.log(`✅ Found ${files.length} files in Storage:\n`);
      files.forEach((f) => {
        const size = f.metadata.size || '?';
        console.log(`   • ${f.name} (${size} bytes)`);
      });
      console.log('\n✅ Storage images exist! Update Firestore imageUrl to reference them.\n');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
