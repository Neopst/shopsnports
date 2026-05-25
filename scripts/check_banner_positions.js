#!/usr/bin/env node
/**
 * Check Firestore banner data to see what position values are stored
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
});

const db = admin.firestore();

async function main() {
  try {
    console.log('📋 Checking Firestore banners structure\n');
    
    const bannersSnap = await db.collection('banners').limit(4).get();
    
    if (bannersSnap.empty) {
      console.log('❌ No banners found');
      process.exit(1);
    }

    console.log(`Found ${bannersSnap.size} banners:\n`);

    bannersSnap.forEach((doc) => {
      const data = doc.data();
      console.log(`ID: ${doc.id}`);
      console.log(`  Title: ${data.title}`);
      console.log(`  Position: ${data.position}`);
      console.log(`  Type: ${data.type || 'N/A'}`);
      console.log(`  ImageUrl: ${data.imageUrl}`);
      console.log(`  IsActive: ${data.isActive}\n`);
    });

    console.log('📝 Issues Found:');
    console.log('  • Admin dashboard expects position: "top" | "sidebar" | "footer"');
    console.log('  • But Firestore has position: "HOME_CAROUSEL" or other values');
    console.log('\n✅ SOLUTION:');
    console.log('  Update admin dashboard BannerPosition enum to include all used values\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
