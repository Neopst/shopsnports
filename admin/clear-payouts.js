// clear-payouts.js - Delete ALL hardcoded payout records from Firestore
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin (reuse existing app if already initialized)
let app;
try {
  app = admin.app();
  console.log('✅ Using existing Firebase app');
} catch (e) {
  const serviceAccount = JSON.parse(
    fs.readFileSync('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json', 'utf8')
  );
  app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin initialized');
}

const db = admin.firestore();

async function clearHardcodedPayouts() {
  console.log('\n🗑️  CLEARING ALL HARDCODED PAYOUTS...\n');
  
  try {
    // Delete ALL existing payouts (they're hardcoded with fake affiliate IDs)
    const payoutsSnapshot = await db.collection('payouts').get();
    
    if (payoutsSnapshot.empty) {
      console.log('✅ No payouts found - collection is already clean');
      return;
    }
    
    const batch = db.batch();
    let count = 0;
    
    payoutsSnapshot.docs.forEach(doc => {
      console.log(`   Deleting payout: ${doc.id} (recipient: ${doc.data().recipient_name || 'N/A'})`);
      batch.delete(doc.ref);
      count++;
    });
    
    await batch.commit();
    console.log(`\n✅ Deleted ${count} hardcoded payout records`);
    console.log('✅ Payouts collection is now clean and ready for real affiliate data');
    
    // Show current state
    const affiliatesSnapshot = await db.collection('affiliates').get();
    console.log(`\n📊 Current Firestore state:`);
    console.log(`   - Affiliates: ${affiliatesSnapshot.size}`);
    console.log(`   - Payouts: 0 (clean slate)`);
    
  } catch (error) {
    console.error('❌ Error clearing payouts:', error);
    throw error;
  } finally {
    process.exit(0);
  }
}

clearHardcodedPayouts();
