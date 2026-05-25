const admin = require('firebase-admin');
const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixAffiliateNames() {
  console.log('🔧 FIXING AFFILIATE NAMES\n');
  
  try {
    const fixes = [
      { id: 'aff_001', fullName: 'John Doe', email: 'john.doe@example.com' },
      { id: 'aff_002', fullName: 'Jane Smith', email: 'jane.smith@example.com' },
      { id: 'aff_003', fullName: 'Mike Johnson', email: 'mike.j@example.com' }
    ];
    
    for (const fix of fixes) {
      const docRef = db.collection('affiliates').doc(fix.id);
      const doc = await docRef.get();
      
      if (doc.exists) {
        await docRef.update({
          fullName: fix.fullName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Updated ${fix.id}: ${fix.fullName}`);
      } else {
        console.log(`❌ Not found: ${fix.id}`);
      }
    }
    
    // Now update the corresponding payouts
    console.log('\n🔧 UPDATING PAYOUT NAMES\n');
    
    const payoutsSnapshot = await db.collection('payouts').get();
    
    for (const payoutDoc of payoutsSnapshot.docs) {
      const payout = payoutDoc.data();
      
      if (payout.recipient_name === 'Unknown Affiliate') {
        // Fetch the affiliate to get the correct name
        const affiliateDoc = await db.collection('affiliates').doc(payout.recipient_id).get();
        
        if (affiliateDoc.exists) {
          const affiliate = affiliateDoc.data();
          
          if (affiliate.fullName) {
            await payoutDoc.ref.update({
              recipient_name: affiliate.fullName,
              updated_at: admin.firestore.FieldValue.serverTimestamp()
            });
            
            console.log(`✅ Updated payout ${payout.payout_number}: ${affiliate.fullName}`);
          }
        }
      }
    }
    
    console.log('\n✅ All fixes applied!');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

fixAffiliateNames();
