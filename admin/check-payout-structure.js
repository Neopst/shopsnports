const admin = require('firebase-admin');
const serviceAccount = require('./admin_dashboard/shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkPayouts() {
  console.log('🔍 Checking payout structure...\n');
  
  const snapshot = await db.collection('payouts').limit(2).get();
  
  if (snapshot.empty) {
    console.log('❌ No payouts found in Firestore');
    return;
  }
  
  console.log(`Found ${snapshot.size} payouts\n`);
  
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log('Document ID:', doc.id);
    console.log('Fields:', Object.keys(data).sort().join(', '));
    console.log('Data:', JSON.stringify(data, null, 2));
    console.log('---\n');
  });
  
  process.exit(0);
}

checkPayouts().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
