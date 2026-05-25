const admin = require('firebase-admin');
const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function auditIntegration() {
  console.log('🔍 COMPREHENSIVE AFFILIATES-PAYOUTS INTEGRATION AUDIT\n');
  console.log('='.repeat(60));
  
  try {
    // 1. Check Affiliates Collection
    console.log('\n📊 AFFILIATES COLLECTION:');
    const affiliatesSnapshot = await db.collection('affiliates').get();
    console.log(`Total affiliates: ${affiliatesSnapshot.size}`);
    
    const approvedWithPending = [];
    affiliatesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === 'approved' && (data.pendingPayout || 0) > 0) {
        approvedWithPending.push({
          id: doc.id,
          name: data.fullName,
          email: data.email,
          pendingPayout: data.pendingPayout,
          totalEarnings: data.totalEarnings
        });
      }
    });
    
    console.log(`Approved affiliates with pending payouts: ${approvedWithPending.length}`);
    approvedWithPending.forEach(aff => {
      console.log(`  ✓ ${aff.name} (${aff.email})`);
      console.log(`    ID: ${aff.id}`);
      console.log(`    Pending: $${aff.pendingPayout.toFixed(2)}`);
    });
    
    // 2. Check Payouts Collection
    console.log('\n💰 PAYOUTS COLLECTION:');
    const payoutsSnapshot = await db.collection('payouts').get();
    console.log(`Total payouts: ${payoutsSnapshot.size}`);
    
    const payoutsByStatus = {};
    const payoutDetails = [];
    
    payoutsSnapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'unknown';
      payoutsByStatus[status] = (payoutsByStatus[status] || 0) + 1;
      
      payoutDetails.push({
        id: doc.id,
        payoutNumber: data.payout_number,
        recipientId: data.recipient_id,
        recipientName: data.recipient_name,
        netAmount: data.net_amount,
        status: data.status,
        recipientType: data.recipient_type
      });
    });
    
    console.log('Payouts by status:');
    Object.entries(payoutsByStatus).forEach(([status, count]) => {
      console.log(`  ${status}: ${count}`);
    });
    
    console.log('\nPayout details:');
    payoutDetails.forEach(p => {
      console.log(`  ${p.payoutNumber} - ${p.recipientName || 'UNKNOWN'} - $${p.netAmount} - ${p.status}`);
      console.log(`    Recipient ID: ${p.recipientId}`);
      console.log(`    Recipient Type: ${p.recipientType}`);
    });
    
    // 3. Verify Synchronization
    console.log('\n🔗 SYNCHRONIZATION CHECK:');
    let syncIssues = 0;
    
    for (const payout of payoutDetails) {
      if (payout.recipientType === 'affiliate') {
        // Find matching affiliate
        const affiliateDoc = await db.collection('affiliates').doc(payout.recipientId).get();
        
        if (!affiliateDoc.exists) {
          console.log(`  ❌ Payout ${payout.payoutNumber}: Affiliate ID ${payout.recipientId} NOT FOUND in affiliates collection`);
          syncIssues++;
        } else {
          const affiliateData = affiliateDoc.data();
          const nameMatches = payout.recipientName === affiliateData.fullName;
          
          if (!nameMatches) {
            console.log(`  ⚠️  Payout ${payout.payoutNumber}: Name mismatch`);
            console.log(`     Payout says: "${payout.recipientName}"`);
            console.log(`     Affiliate is: "${affiliateData.fullName}"`);
            syncIssues++;
          }
          
          // Check if amounts make sense
          if (payout.status === 'pending' && affiliateData.pendingPayout !== payout.netAmount) {
            console.log(`  ⚠️  Payout ${payout.payoutNumber}: Amount mismatch`);
            console.log(`     Payout amount: $${payout.netAmount}`);
            console.log(`     Affiliate pending: $${affiliateData.pendingPayout}`);
            syncIssues++;
          }
        }
      }
    }
    
    if (syncIssues === 0) {
      console.log('  ✅ All payouts properly linked to affiliates!');
    } else {
      console.log(`  ❌ Found ${syncIssues} synchronization issues`);
    }
    
    // 4. Summary
    console.log('\n' + '='.repeat(60));
    console.log('📋 SUMMARY:');
    console.log(`  Affiliates: ${affiliatesSnapshot.size} (${approvedWithPending.length} with pending payouts)`);
    console.log(`  Payouts: ${payoutsSnapshot.size}`);
    console.log(`  Sync Issues: ${syncIssues}`);
    console.log(`  Status: ${syncIssues === 0 ? '✅ HEALTHY' : '❌ NEEDS ATTENTION'}`);
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Error during audit:', error.message);
    console.error(error);
    process.exit(1);
  }
}

auditIntegration();
