#!/usr/bin/env node
/**
 * Migrate banner position values from "HOME_CAROUSEL" to "homeCarousel"
 * to match Dart enum naming convention
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
});

const db = admin.firestore();

// Map old position values to new enum names
const POSITION_MAP = {
  'HOME_CAROUSEL': 'homeCarousel',
  'HOME_TOP': 'top',
  'HOME_BOTTOM': 'footer',
  'SIDEBAR': 'sidebar',
};

async function main() {
  try {
    console.log('🔄 Migrating banner position values\n');
    console.log('='.repeat(60) + '\n');

    const bannersSnap = await db.collection('banners').get();
    
    if (bannersSnap.empty) {
      console.log('❌ No banners found');
      process.exit(1);
    }

    console.log(`Found ${bannersSnap.size} banners\n`);

    let updatedCount = 0;
    const batch = db.batch();

    for (const doc of bannersSnap.docs) {
      const data = doc.data();
      const oldPosition = data.position;
      const newPosition = POSITION_MAP[oldPosition];

      if (newPosition && newPosition !== oldPosition) {
        console.log(`📝 ${doc.id}`);
        console.log(`  Old position: ${oldPosition}`);
        console.log(`  New position: ${newPosition}`);
        
        batch.update(doc.ref, { position: newPosition });
        updatedCount++;
      } else if (!newPosition) {
        console.log(`⚠️  ${doc.id}`);
        console.log(`  Position "${oldPosition}" not in mapping, keeping as-is\n`);
      }
    }

    if (updatedCount > 0) {
      console.log(`\n✅ Writing ${updatedCount} updates...\n`);
      await batch.commit();
      console.log(`✅ Migration complete!\n`);
    } else {
      console.log('ℹ️  No banners needed updating\n');
    }

    console.log('📋 Updated position values:');
    console.log('  • "HOME_CAROUSEL" → "homeCarousel"');
    console.log('  • "HOME_TOP" → "top"');
    console.log('  • "HOME_BOTTOM" → "footer"');
    console.log('  • "SIDEBAR" → "sidebar"\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
