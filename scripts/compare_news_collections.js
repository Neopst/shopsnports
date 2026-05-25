#!/usr/bin/env node
/**
 * Compare news_ticker vs news_items collections
 * to identify which is redundant
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
    console.log('📊 Comparing News Collections\n');
    console.log('=' .repeat(60) + '\n');

    // Check news_items
    console.log('📋 news_items collection:\n');
    const newsItemsSnap = await db.collection('news_items').get();
    console.log(`  Document count: ${newsItemsSnap.size}`);
    if (newsItemsSnap.size > 0) {
      newsItemsSnap.forEach((doc) => {
        const data = doc.data();
        console.log(`\n  ID: ${doc.id}`);
        console.log(`    Title: ${data.title || 'N/A'}`);
        console.log(`    Status: ${data.status || 'N/A'}`);
        console.log(`    Published At: ${data.publishedAt ? data.publishedAt.toDate() : 'N/A'}`);
      });
    }

    console.log('\n' + '='.repeat(60) + '\n');

    // Check news_ticker
    console.log('📋 news_ticker collection:\n');
    const newsTickerSnap = await db.collection('news_ticker').get();
    console.log(`  Document count: ${newsTickerSnap.size}`);
    if (newsTickerSnap.size > 0) {
      newsTickerSnap.forEach((doc) => {
        const data = doc.data();
        console.log(`\n  ID: ${doc.id}`);
        console.log(`    Title: ${data.title || 'N/A'}`);
        console.log(`    Status: ${data.status || 'N/A'}`);
        console.log(`    Published At: ${data.publishedAt ? data.publishedAt.toDate() : 'N/A'}`);
      });
    }

    console.log('\n' + '='.repeat(60) + '\n');
    console.log('📝 ANALYSIS:\n');

    if (newsItemsSnap.size > 0 && newsTickerSnap.size === 0) {
      console.log('✅ news_items is ACTIVE (has data)');
      console.log('❌ news_ticker is REDUNDANT (empty)\n');
      console.log('💡 RECOMMENDATION: Delete news_ticker collection\n');
    } else if (newsTickerSnap.size > 0 && newsItemsSnap.size === 0) {
      console.log('❌ news_items is ABANDONED (empty)');
      console.log('✅ news_ticker is ACTIVE (has data)\n');
      console.log('⚠️  ISSUE: Mobile app expects news_items but data is in news_ticker');
      console.log('💡 RECOMMENDATION: Migrate data from news_ticker → news_items\n');
    } else if (newsItemsSnap.size > 0 && newsTickerSnap.size > 0) {
      console.log('⚠️  BOTH collections have data');
      console.log('💡 RECOMMENDATION: Audit which is used, consolidate into one\n');
    } else {
      console.log('❌ BOTH collections are empty\n');
      console.log('💡 ACTION NEEDED: Populate news_items from admin dashboard\n');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
