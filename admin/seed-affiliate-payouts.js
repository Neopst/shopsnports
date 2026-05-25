// seed-affiliate-payouts.js - Create payouts for existing Firestore affiliates
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = JSON.parse(fs.readFileSync('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json', 'utf8'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function seedAffiliatePayouts() {
  console.log('🚀 Starting to seed affiliate payouts...');
  
  try {
    // 1. Get all affiliates from Firestore (we'll filter for approved ones)
    const affiliatesSnapshot = await db.collection('affiliates').get();
    
    if (affiliatesSnapshot.empty) {
      console.log('❌ No affiliates found. Please seed affiliates first.');
      process.exit(1);
    }
    
    // Filter for approved affiliates
    const approvedAffiliates = [];
    affiliatesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === 'approved') {
        approvedAffiliates.push({ id: doc.id, data });
      }
    });
    
    console.log(`✅ Found ${approvedAffiliates.length} approved affiliates (out of ${affiliatesSnapshot.size} total)`);
    
    if (approvedAffiliates.length === 0) {
      console.log('❌ No approved affiliates found. Please approve some affiliates first.');
      process.exit(1);
    }
    
    // 2. Clear existing payouts (optional - remove if you want to keep old data)
    const existingPayouts = await db.collection('payouts').get();
    const deletePromises = existingPayouts.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`🗑️  Cleared ${existingPayouts.size} existing payouts`);
    
    const now = new Date();
    const payouts = [];
    
    // 3. Create payouts for each approved affiliate
    approvedAffiliates.forEach(({ id: affiliateId, data: affiliate }, index) => {
      
      // Create 2-3 payouts per affiliate (mix of pending, completed, failed)
      const payoutStatuses = ['pending', 'completed', 'completed', 'failed'];
      const statusToUse = payoutStatuses[index % payoutStatuses.length];
      
      // Payout 1: Recent payout
      const payout1 = {
        id: `payout_${affiliateId}_001`,
        payout_number: `PAY-2026-${String(index * 3 + 1).padStart(3, '0')}`,
        recipient_type: 'affiliate',
        recipient_id: affiliateId, // REAL FIRESTORE AFFILIATE ID
        recipient_name: affiliate.fullName || 'Unknown Affiliate',
        gross_amount: affiliate.pendingPayout || 0,
        commission_amount: affiliate.pendingPayout || 0,
        tax_amount: ((affiliate.pendingPayout || 0) * 0.05), // 5% tax
        net_amount: (affiliate.pendingPayout || 0) * 0.95,
        currency: 'NGN',
        status: statusToUse,
        payment_method: 'bank_transfer',
        bank_account_number: affiliate.bankAccountDetails || 'Account not provided',
        bank_name: 'GTBank',
        payment_reference: statusToUse === 'completed' ? `TXN-${Date.now()}-${index}` : null,
        period_start: admin.firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth() - 1, 1)),
        period_end: admin.firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth(), 0)),
        approved_by: (statusToUse !== 'pending') ? 'admin_001' : null,
        approved_at: (statusToUse !== 'pending') ? admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 86400000 * 2)) : null,
        processed_by: (statusToUse === 'completed') ? 'admin_001' : null,
        processed_at: (statusToUse === 'completed') ? admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 86400000)) : null,
        notes: (statusToUse === 'failed') ? 'Bank transfer failed - incorrect account number' : null,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      payouts.push(payout1);
      
      // Payout 2: Older completed payout (history)
      if (affiliate.totalEarnings > affiliate.pendingPayout) {
        const payout2 = {
          id: `payout_${affiliateId}_002`,
          payout_number: `PAY-2026-${String(index * 3 + 2).padStart(3, '0')}`,
          recipient_type: 'affiliate',
          recipient_id: affiliateId,
          recipient_name: affiliate.fullName || 'Unknown Affiliate',
          gross_amount: affiliate.totalEarnings - affiliate.pendingPayout,
          commission_amount: affiliate.totalEarnings - affiliate.pendingPayout,
          tax_amount: ((affiliate.totalEarnings - affiliate.pendingPayout) * 0.05),
          net_amount: (affiliate.totalEarnings - affiliate.pendingPayout) * 0.95,
          currency: 'NGN',
          status: 'completed',
          payment_method: 'bank_transfer',
          bank_account_number: affiliate.bankAccountDetails || 'Account not provided',
          bank_name: 'First Bank',
          payment_reference: `TXN-${Date.now()}-${index}-OLD`,
          period_start: admin.firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth() - 2, 1)),
          period_end: admin.firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth() - 1, 0)),
          approved_by: 'admin_001',
          approved_at: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 86400000 * 45)),
          processed_by: 'admin_001',
          processed_at: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 86400000 * 40)),
          notes: 'Previous month payout',
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        payouts.push(payout2);
      }
    });
    
    // 4. Write all payouts to Firestore
    const batch = db.batch();
    payouts.forEach(payout => {
      const docRef = db.collection('payouts').doc(payout.id);
      batch.set(docRef, payout);
    });
    
    await batch.commit();
    console.log(`✅ Successfully seeded ${payouts.length} payouts`);
    
    // 5. Summary
    const pendingCount = payouts.filter(p => p.status === 'pending').length;
    const completedCount = payouts.filter(p => p.status === 'completed').length;
    const failedCount = payouts.filter(p => p.status === 'failed').length;
    
    console.log('\n📊 Summary:');
    console.log(`   - Total: ${payouts.length} payouts`);
    console.log(`   - Pending: ${pendingCount}`);
    console.log(`   - Completed: ${completedCount}`);
    console.log(`   - Failed: ${failedCount}`);
    console.log('\n✅ Payouts are now linked to real Firestore affiliates!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding payouts:', error);
    process.exit(1);
  }
}

seedAffiliatePayouts();
