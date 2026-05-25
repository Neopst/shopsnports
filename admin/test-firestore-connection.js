const admin = require('firebase-admin');
const serviceAccount = require('./admin_dashboard/shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testConnection() {
  try {
    console.log('🔍 Testing Firestore connection...\n');
    
    // Test 1: Count payouts
    const payoutsSnapshot = await db.collection('payouts').get();
    console.log(`✅ Total payouts in Firestore: ${payoutsSnapshot.size}`);
    
    // Test 2: Check pending payouts
    const pendingSnapshot = await db.collection('payouts').where('status', '==', 'pending').get();
    console.log(`✅ Pending payouts: ${pendingSnapshot.size}`);
    
    // Test 3: Check affiliate type
    const affiliateSnapshot = await db.collection('payouts').where('recipient_type', '==', 'affiliate').get();
    console.log(`✅ Affiliate payouts: ${affiliateSnapshot.size}`);
    
    // Test 4: Show first payout
    if (!payoutsSnapshot.empty) {
      const firstDoc = payoutsSnapshot.docs[0];
      console.log('\n📄 Sample payout document:');
      console.log('ID:', firstDoc.id);
      const data = firstDoc.data();
      console.log('Fields:', Object.keys(data).join(', '));
      console.log('\nData:');
      console.log(JSON.stringify(data, null, 2));
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testConnection();
