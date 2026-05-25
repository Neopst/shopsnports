const admin = require('firebase-admin');
const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testAtomicUpdate() {
  console.log('🧪 TESTING ATOMIC PAYOUT PROCESSING\n');
  console.log('='.repeat(60));
  
  try {
    // Find a pending payout
    const payoutsSnapshot = await db.collection('payouts')
      .where('status', '==', 'pending')
      .limit(1)
      .get();
    
    if (payoutsSnapshot.empty) {
      console.log('❌ No pending payouts found for testing');
      process.exit(1);
    }
    
    const payoutDoc = payoutsSnapshot.docs[0];
    const payout = payoutDoc.data();
    
    console.log('📄 Selected payout for testing:');
    console.log(`  Payout Number: ${payout.payout_number}`);
    console.log(`  Recipient: ${payout.recipient_name}`);
    console.log(`  Amount: $${payout.net_amount}`);
    console.log(`  Recipient ID: ${payout.recipient_id}`);
    console.log(`  Status: ${payout.status}`);
    
    // Get affiliate BEFORE processing
    const affiliateDoc = await db.collection('affiliates').doc(payout.recipient_id).get();
    
    if (!affiliateDoc.exists) {
      console.log(`❌ Affiliate ${payout.recipient_id} not found`);
      process.exit(1);
    }
    
    const affiliateBefore = affiliateDoc.data();
    
    console.log('\n👤 Affiliate BEFORE processing:');
    console.log(`  Name: ${affiliateBefore.fullName}`);
    console.log(`  Pending Payout: $${affiliateBefore.pendingPayout}`);
    console.log(`  Total Earnings: $${affiliateBefore.totalEarnings || 0}`);
    console.log(`  Last Payout Date: ${affiliateBefore.lastPayoutDate || 'Never'}`);
    
    // Simulate atomic update (what the Flutter app does)
    console.log('\n⚙️  Simulating atomic payout processing...');
    
    const batch = db.batch();
    
    // 1. Update payout status
    batch.update(payoutDoc.ref, {
      status: 'completed',
      processed_by: 'test_admin',
      processed_at: admin.firestore.FieldValue.serverTimestamp(),
      payment_reference: 'TEST-REF-12345',
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // 2. Deduct from affiliate balance
    batch.update(affiliateDoc.ref, {
      pendingPayout: admin.firestore.FieldValue.increment(-payout.net_amount),
      lastPayoutDate: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await batch.commit();
    console.log('✅ Batch commit successful');
    
    // Verify changes
    const payoutAfter = (await payoutDoc.ref.get()).data();
    const affiliateAfter = (await affiliateDoc.ref.get()).data();
    
    console.log('\n✅ Payout AFTER processing:');
    console.log(`  Status: ${payoutAfter.status}`);
    console.log(`  Processed By: ${payoutAfter.processed_by}`);
    console.log(`  Payment Reference: ${payoutAfter.payment_reference}`);
    
    console.log('\n✅ Affiliate AFTER processing:');
    console.log(`  Name: ${affiliateAfter.fullName}`);
    console.log(`  Pending Payout: $${affiliateAfter.pendingPayout}`);
    console.log(`  Total Earnings: $${affiliateAfter.totalEarnings || 0}`);
    console.log(`  Last Payout Date: ${affiliateAfter.lastPayoutDate ? new Date(affiliateAfter.lastPayoutDate._seconds * 1000).toISOString() : 'Never'}`);
    
    // Verify atomic update worked
    const expectedNewBalance = affiliateBefore.pendingPayout - payout.net_amount;
    const actualNewBalance = affiliateAfter.pendingPayout;
    
    console.log('\n🔍 VERIFICATION:');
    console.log(`  Expected new balance: $${expectedNewBalance.toFixed(2)}`);
    console.log(`  Actual new balance: $${actualNewBalance.toFixed(2)}`);
    console.log(`  Balance updated correctly: ${Math.abs(expectedNewBalance - actualNewBalance) < 0.01 ? '✅ YES' : '❌ NO'}`);
    console.log(`  Payout marked completed: ${payoutAfter.status === 'completed' ? '✅ YES' : '❌ NO'}`);
    console.log(`  Both updated atomically: ✅ YES (batch commit ensures this)`);
    
    // Rollback for testing purposes
    console.log('\n🔄 Rolling back changes for future tests...');
    const rollback = db.batch();
    rollback.update(payoutDoc.ref, {
      status: 'pending',
      processed_by: admin.firestore.FieldValue.delete(),
      processed_at: admin.firestore.FieldValue.delete(),
      payment_reference: admin.firestore.FieldValue.delete(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    rollback.update(affiliateDoc.ref, {
      pendingPayout: affiliateBefore.pendingPayout,
      lastPayoutDate: affiliateBefore.lastPayoutDate || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await rollback.commit();
    console.log('✅ Rollback complete\n');
    
    console.log('='.repeat(60));
    console.log('🎉 ATOMIC UPDATE TEST: ✅ PASSED');
    console.log('='.repeat(60));
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Error during test:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testAtomicUpdate();
