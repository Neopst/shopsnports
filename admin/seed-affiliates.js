// seed-affiliates.js - Seed sample affiliate data to Firestore
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = JSON.parse(fs.readFileSync('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json', 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Sample affiliate data
const sampleAffiliates = [
  {
    userId: 'user_001',
    fullName: 'Michael Johnson',
    email: 'michael.j@example.com',
    phone: '+1-555-0101',
    photoUrl: 'https://ui-avatars.com/api/?name=Michael+Johnson&size=200&background=0A2A66&color=fff',
    companyName: 'MJ Logistics LLC',
    address: '123 Business Ave, New York, NY 10001',
    status: 'approved',
    commissionRate: 15,
    payoutSchedule: 'monthly',
    bankAccountDetails: 'Chase Bank - **** 4567',
    taxId: 'TAX-MJ-001',
    totalEarnings: 2450.50,
    pendingPayout: 450.50,
    totalShipments: 18,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-01-15')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-01')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-16')),
    approvedBy: 'admin_001',
  },
  {
    userId: 'user_002',
    fullName: 'Sarah Williams',
    email: 'sarah.w@example.com',
    phone: '+1-555-0102',
    photoUrl: 'https://ui-avatars.com/api/?name=Sarah+Williams&size=200&background=4CAF50&color=fff',
    companyName: 'Williams Shipping Co',
    address: '456 Commerce St, Los Angeles, CA 90001',
    status: 'approved',
    commissionRate: 18,
    payoutSchedule: 'monthly',
    bankAccountDetails: 'Bank of America - **** 7890',
    taxId: 'TAX-SW-002',
    totalEarnings: 3200.75,
    pendingPayout: 800.25,
    totalShipments: 25,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2023-12-01')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-05')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2023-12-02')),
    approvedBy: 'admin_001',
  },
  {
    userId: 'user_003',
    fullName: 'David Chen',
    email: 'david.chen@example.com',
    phone: '+1-555-0103',
    photoUrl: 'https://ui-avatars.com/api/?name=David+Chen&size=200&background=2196F3&color=fff',
    companyName: 'Chen Express',
    address: '789 Harbor Blvd, San Francisco, CA 94102',
    status: 'approved',
    commissionRate: 20,
    payoutSchedule: 'weekly',
    bankAccountDetails: 'Wells Fargo - **** 2345',
    taxId: 'TAX-DC-003',
    totalEarnings: 5100.00,
    pendingPayout: 1200.00,
    totalShipments: 42,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2023-11-10')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-08')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2023-11-11')),
    approvedBy: 'admin_002',
  },
  {
    userId: 'user_004',
    fullName: 'Emma Rodriguez',
    email: 'emma.r@example.com',
    phone: '+1-555-0104',
    photoUrl: 'https://ui-avatars.com/api/?name=Emma+Rodriguez&size=200&background=FF5722&color=fff',
    companyName: 'ER Global Shipping',
    address: '321 Trade Center, Miami, FL 33101',
    status: 'approved',
    commissionRate: 16,
    payoutSchedule: 'monthly',
    bankAccountDetails: 'Citibank - **** 6789',
    taxId: 'TAX-ER-004',
    totalEarnings: 1850.25,
    pendingPayout: 350.25,
    totalShipments: 14,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-01-20')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-10')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-21')),
    approvedBy: 'admin_001',
  },
  {
    userId: 'user_005',
    fullName: 'James Anderson',
    email: 'james.a@example.com',
    phone: '+1-555-0105',
    photoUrl: 'https://ui-avatars.com/api/?name=James+Anderson&size=200&background=9C27B0&color=fff',
    companyName: 'Anderson Freight Solutions',
    address: '654 Industrial Pkwy, Chicago, IL 60601',
    status: 'approved',
    commissionRate: 17,
    payoutSchedule: 'bi_weekly',
    bankAccountDetails: 'US Bank - **** 3456',
    taxId: 'TAX-JA-005',
    totalEarnings: 4200.80,
    pendingPayout: 600.80,
    totalShipments: 31,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2023-10-15')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-12')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2023-10-16')),
    approvedBy: 'admin_002',
  },
  {
    userId: 'user_006',
    fullName: 'Linda Martinez',
    email: 'linda.m@example.com',
    phone: '+1-555-0106',
    photoUrl: 'https://ui-avatars.com/api/?name=Linda+Martinez&size=200&background=E91E63&color=fff',
    companyName: null,
    address: '987 Residential Dr, Houston, TX 77001',
    status: 'pending',
    commissionRate: 15,
    payoutSchedule: 'monthly',
    bankAccountDetails: null,
    taxId: null,
    totalEarnings: 0,
    pendingPayout: 0,
    totalShipments: 0,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-10')),
    lastPayoutDate: null,
  },
  {
    userId: 'user_007',
    fullName: 'Robert Taylor',
    email: 'robert.t@example.com',
    phone: '+1-555-0107',
    photoUrl: 'https://ui-avatars.com/api/?name=Robert+Taylor&size=200&background=FF9800&color=fff',
    companyName: 'Taylor Transport Inc',
    address: '147 Logistics Ln, Atlanta, GA 30301',
    status: 'pending',
    commissionRate: 15,
    payoutSchedule: 'monthly',
    bankAccountDetails: null,
    taxId: null,
    totalEarnings: 0,
    pendingPayout: 0,
    totalShipments: 0,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-12')),
    lastPayoutDate: null,
  },
  {
    userId: 'user_008',
    fullName: 'Jennifer Lee',
    email: 'jennifer.l@example.com',
    phone: '+1-555-0108',
    photoUrl: 'https://ui-avatars.com/api/?name=Jennifer+Lee&size=200&background=3F51B5&color=fff',
    companyName: 'Lee Worldwide Shipping',
    address: '258 Global Trade Center, Seattle, WA 98101',
    status: 'pending',
    commissionRate: 15,
    payoutSchedule: 'monthly',
    bankAccountDetails: null,
    taxId: null,
    totalEarnings: 0,
    pendingPayout: 0,
    totalShipments: 0,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-13')),
    lastPayoutDate: null,
  },
  {
    userId: 'user_009',
    fullName: 'Thomas Brown',
    email: 'thomas.b@example.com',
    phone: '+1-555-0109',
    photoUrl: 'https://ui-avatars.com/api/?name=Thomas+Brown&size=200&background=F44336&color=fff',
    companyName: 'Brown Logistics Group',
    address: '369 Distribution Dr, Phoenix, AZ 85001',
    status: 'rejected',
    commissionRate: 15,
    payoutSchedule: 'monthly',
    bankAccountDetails: null,
    taxId: null,
    totalEarnings: 0,
    pendingPayout: 0,
    totalShipments: 0,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2024-02-05')),
    lastPayoutDate: null,
    rejectionReason: 'Incomplete documentation and failed background verification',
  },
  {
    userId: 'user_010',
    fullName: 'Patricia Davis',
    email: 'patricia.d@example.com',
    phone: '+1-555-0110',
    photoUrl: 'https://ui-avatars.com/api/?name=Patricia+Davis&size=200&background=607D8B&color=fff',
    companyName: 'Davis Express Services',
    address: '741 Commerce Blvd, Boston, MA 02101',
    status: 'suspended',
    commissionRate: 18,
    payoutSchedule: 'monthly',
    bankAccountDetails: 'TD Bank - **** 8901',
    taxId: 'TAX-PD-010',
    totalEarnings: 1500.00,
    pendingPayout: 0,
    totalShipments: 12,
    joinedDate: admin.firestore.Timestamp.fromDate(new Date('2023-11-01')),
    lastPayoutDate: admin.firestore.Timestamp.fromDate(new Date('2024-01-15')),
    approvedAt: admin.firestore.Timestamp.fromDate(new Date('2023-11-02')),
    approvedBy: 'admin_001',
    suspensionReason: 'Multiple customer complaints and delivery issues',
    suspendedAt: admin.firestore.Timestamp.fromDate(new Date('2024-02-01')),
  },
];

// Seed data to Firestore
async function seedAffiliates() {
  try {
    console.log('🚀 Starting to seed affiliate data...');

    const batch = db.batch();

    sampleAffiliates.forEach((affiliate, index) => {
      const docRef = db.collection('affiliates').doc(`affiliate_${String(index + 1).padStart(3, '0')}`);
      batch.set(docRef, affiliate);
      console.log(`✅ Added affiliate: ${affiliate.fullName} (${affiliate.status})`);
    });

    await batch.commit();
    console.log('\n✅ Successfully seeded all affiliates!');
    console.log(`\n📊 Summary:`);
    console.log(`   - Total: ${sampleAffiliates.length} affiliates`);
    console.log(`   - Approved: ${sampleAffiliates.filter(a => a.status === 'approved').length}`);
    console.log(`   - Pending: ${sampleAffiliates.filter(a => a.status === 'pending').length}`);
    console.log(`   - Rejected: ${sampleAffiliates.filter(a => a.status === 'rejected').length}`);
    console.log(`   - Suspended: ${sampleAffiliates.filter(a => a.status === 'suspended').length}`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding affiliates:', error);
    process.exit(1);
  }
}

// Link some shipping requests to approved affiliates
async function linkShippingRequests() {
  try {
    console.log('\n🔗 Linking shipping requests to affiliates...');

    // Get existing shipping requests
    const shipmentsSnapshot = await db.collection('shippingRequests')
      .where('status', '==', 'delivered')
      .limit(10)
      .get();

    if (shipmentsSnapshot.empty) {
      console.log('⚠️  No delivered shipments found to link');
      return;
    }

    const approvedAffiliateIds = [
      'affiliate_001', // Michael Johnson
      'affiliate_002', // Sarah Williams
      'affiliate_003', // David Chen
      'affiliate_004', // Emma Rodriguez
      'affiliate_005', // James Anderson
    ];

    const batch = db.batch();
    let count = 0;

    shipmentsSnapshot.docs.forEach((doc, index) => {
      const affiliateId = approvedAffiliateIds[index % approvedAffiliateIds.length];
      const commissionRate = sampleAffiliates.find(a => a.userId === `user_${String(index % 5 + 1).padStart(3, '0')}`).commissionRate;
      
      // Calculate commission (10% of shipment value for example, or use actual price)
      const commissionAmount = Math.random() * 100 + 50; // Random commission between $50-$150

      batch.update(doc.ref, {
        affiliateId: affiliateId,
        commissionAmount: commissionAmount,
      });

      console.log(`   ✅ Linked ${doc.id} to ${affiliateId} (commission: $${commissionAmount.toFixed(2)})`);
      count++;
    });

    await batch.commit();
    console.log(`\n✅ Successfully linked ${count} shipping requests to affiliates!`);
  } catch (error) {
    console.error('❌ Error linking shipping requests:', error);
  }
}

// Run both functions
(async () => {
  await seedAffiliates();
  await linkShippingRequests();
})();
