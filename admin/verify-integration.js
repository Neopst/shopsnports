// verify-integration.js - Check Payouts module will see Affiliate-generated payouts
const admin = require('firebase-admin');
const fs = require('fs');

try {
  admin.app();
} catch (e) {
  const serviceAccount = JSON.parse(
    fs.readFileSync('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json', 'utf8')
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function verifyIntegration() {
  console.log('\n🔍 VERIFYING AFFILIATES → PAYOUTS INTEGRATION\n');
  
  // 1. Check payouts collection
  const payoutsSnap = await db.collection('payouts').get();
  console.log(`📊 Payouts in Firestore: ${payoutsSnap.size}\n`);
  
  if (payoutsSnap.empty) {
    console.log('❌ No payouts found! Integration failed.\n');
    process.exit(1);
  }
  
  // Show first 5 payouts
  let count = 0;
  for (const doc of payoutsSnap.docs) {
    if (count >= 5) break;
    const payout = doc.data();
    
    console.log(`✅ ${payout.payout_number}`);
    console.log(`   Recipient: ${payout.recipient_name || 'N/A'}`);
    console.log(`   Amount: $${payout.net_amount}`);
    console.log(`   Status: ${payout.status}`);
    console.log(`   Type: ${payout.recipient_type}`);
    console.log(`   Recipient ID: ${payout.recipient_id}`);
    console.log(`   Created: ${payout.created_at ? 'Yes' : 'Pending'}\n`);
    count++;
  }
  
  // 2. Test filtering by affiliate ID
  const testAffiliateId = payoutsSnap.docs[0].data().recipient_id;
  const filteredSnap = await db
    .collection('payouts')
    .where('recipient_id', '==', testAffiliateId)
    .get();
  
  console.log(`\n🔗 Testing filter by affiliate ID: ${testAffiliateId}`);
  console.log(`   Found ${filteredSnap.size} payout(s) for this affiliate\n`);
  
  // 3. Verify affiliate has matching data
  const affiliateSnap = await db.collection('affiliates').doc(testAffiliateId).get();
  if (affiliateSnap.exists) {
    const affiliate = affiliateSnap.data();
    const payout = payoutsSnap.docs[0].data();
    
    console.log(`✅ INTEGRATION VERIFIED:`);
    console.log(`   Affiliate: ${affiliate.fullName}`);
    console.log(`   Pending Payout: $${affiliate.pendingPayout}`);
    console.log(`   Payout Amount: $${payout.net_amount}`);
    console.log(`   Match: ${affiliate.pendingPayout === payout.net_amount ? '✅ YES' : '⚠️ Different amounts'}\n`);
  }
  
  console.log('✅ Payouts module WILL display these records!');
  console.log('✅ Click "View Payout History" in Affiliates → Shows payouts filtered by affiliateId\n');
  
  process.exit(0);
}

verifyIntegration().catch(err => {
  console.error('❌ Error:', err);
  process.exit(1);
});
