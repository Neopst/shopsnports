#!/usr/bin/env node
/**
 * Migrate news_items → news_ticker
 * Keep news_ticker as the single source of truth for all news
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
    console.log('📋 News Ticker Migration (news_items → news_ticker)\n');
    console.log('='.repeat(60) + '\n');

    // Get all documents from news_items
    console.log('🔍 Reading news_items collection...\n');
    const newsItemsSnap = await db.collection('news_items').get();
    
    if (newsItemsSnap.empty) {
      console.log('ℹ️  news_items is empty, nothing to migrate.\n');
      process.exit(0);
    }

    console.log(`✅ Found ${newsItemsSnap.size} documents to migrate\n`);

    // Migrate each document
    let migratedCount = 0;
    const batch = db.batch();

    for (const doc of newsItemsSnap.docs) {
      const data = doc.data();
      const newsTickerRef = db.collection('news_ticker').doc(doc.id);
      
      console.log(`📝 Migrating: ${doc.id}`);
      console.log(`   Title: ${data.title || 'N/A'}`);
      
      batch.set(newsTickerRef, data);
      migratedCount++;
    }

    // Commit batch
    console.log(`\n✅ Writing ${migratedCount} documents to news_ticker...\n`);
    await batch.commit();

    console.log('🎉 Migration complete!\n');
    console.log('='.repeat(60) + '\n');

    console.log('📊 Next Steps:\n');
    console.log('1️⃣  Update mobile app to read from news_ticker');
    console.log('   File: lib/providers/content_providers.dart');
    console.log('   Change: collection("news_items") → collection("news_ticker")\n');
    
    console.log('2️⃣  Delete news_items collection (optional)');
    console.log('   Run: npm run delete-news-items\n');
    
    console.log('3️⃣  Verify in mobile app:');
    console.log('   - Rebuild and run\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
