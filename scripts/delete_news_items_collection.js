#!/usr/bin/env node
/**
 * Delete news_items collection (now redundant, migrated to news_ticker)
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'shopsnports',
});

const db = admin.firestore();

async function deleteCollection(collectionPath, batchSize = 100) {
  let deleted = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snapshot = await db.collection(collectionPath).limit(batchSize).get();

    if (snapshot.size === 0) {
      break;
    }

    let batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    deleted += snapshot.size;
  }
  return deleted;
}

async function main() {
  try {
    console.log('🗑️  Deleting redundant news_items collection...\n');

    const deleted = await deleteCollection('news_items');

    console.log(`✅ Deleted ${deleted} documents from news_items collection\n`);
    console.log('📝 Summary:');
    console.log('   • news_items is now DELETED');
    console.log('   • news_ticker is the single source of truth');
    console.log('   • Admin dashboard writes to news_ticker');
    console.log('   • Mobile app reads from news_ticker');
    console.log('   • ✅ Sync complete!\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
