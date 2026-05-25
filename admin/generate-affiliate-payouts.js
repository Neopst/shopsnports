// generate-affiliate-payouts.js - Generate payout records from actual affiliate data
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
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

async function generatePayoutsFromAffiliates() {
  console.log('\n💰 GENERATING PAYOUTS FROM AFFILIATE DATA...\n');
  
  try {
    // Get all approved affiliates with pending payouts
    const affiliatesSnapshot = await db
      .collection('affiliates')
      .where('status', '==', 'approved')
      .get();
    
    if (affiliatesSnapshot.empty) {
      console.log('❌ No approved affiliates found');
      return;
    }
    
    const batch = db.batch();
    let payoutCount = 0;
    const now = new Date();
    
    console.log(`📊 Found ${affiliatesSnapshot.size} approved affiliates\n`);
    
    for (const doc of affiliatesSnapshot.docs) {
      const affiliate = doc.data();
      const affiliateId = doc.id;
      
      // Skip if no pending payout
      if (!affiliate.pendingPayout || affiliate.pendingPayout <= 0) {
        console.log(`⏭️  ${affiliate.fullName}: No pending payout (${affiliate.pendingPayout || 0})`);
        continue;
      }
      
      // Generate payout record
      const payoutId = `payout_${affiliateId}_${Date.now()}`;
      const payoutNumber = `PAY-${now.getFullYear()}-${String(payoutCount + 1).padStart(4, '0')}`;
      
      const grossAmount = affiliate.pendingPayout;
      const taxRate = 0; // No tax for affiliates in this system
      const taxAmount = grossAmount * taxRate;
      const netAmount = grossAmount - taxAmount;
      
      // Period: last 30 days (assuming accumulated earnings)
      const periodEnd = now;
      const periodStart = new Date(now);
      periodStart.setDate(periodStart.getDate() - 30);
      
      const payoutData = {
        id: payoutId,
        payout_number: payoutNumber,
        recipient_type: 'affiliate',
        recipient_id: affiliateId,
        recipient_name: affiliate.fullName || 'Unknown Affiliate',
        gross_amount: grossAmount,
        commission_amount: grossAmount, // For affiliates, commission = gross
        tax_amount: taxAmount,
        net_amount: netAmount,
        currency: 'USD', // Match affiliate earnings
        status: 'pending',
        payment_method: 'bank_transfer',
        bank_account_number: affiliate.bankAccountDetails || null,
        bank_name: affiliate.bankAccountDetails ? affiliate.bankAccountDetails.split(' - ')[0] : null,
        payment_reference: null,
        period_start: admin.firestore.Timestamp.fromDate(periodStart),
        period_end: admin.firestore.Timestamp.fromDate(periodEnd),
        approved_by: null,
        approved_at: null,
        processed_by: null,
        processed_at: null,
        notes: `Payout for ${affiliate.totalShipments || 0} shipments`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      batch.set(db.collection('payouts').doc(payoutId), payoutData);
      payoutCount++;
      
      console.log(`✅ ${affiliate.fullName}`);
      console.log(`   - Pending Payout: $${grossAmount.toFixed(2)}`);
      console.log(`   - Payout Number: ${payoutNumber}`);
      console.log(`   - Shipments: ${affiliate.totalShipments || 0}`);
      console.log(`   - Bank: ${affiliate.bankAccountDetails || 'Not provided'}\n`);
    }
    
    if (payoutCount > 0) {
      await batch.commit();
      console.log(`\n✅ Created ${payoutCount} payout records from affiliate data`);
      console.log('✅ Payouts are now synchronized with affiliate earnings!\n');
    } else {
      console.log('\n⚠️  No affiliates with pending payouts found\n');
    }
    
    // Show summary
    const payoutsSnapshot = await db.collection('payouts').get();
    console.log(`📊 Final state:`);
    console.log(`   - Affiliates: ${affiliatesSnapshot.size}`);
    console.log(`   - Payouts: ${payoutsSnapshot.size}`);
    console.log(`   - Integration: ✅ COMPLETE`);
    
  } catch (error) {
    console.error('❌ Error generating payouts:', error);
    throw error;
  } finally {
    process.exit(0);
  }
}

generatePayoutsFromAffiliates();
