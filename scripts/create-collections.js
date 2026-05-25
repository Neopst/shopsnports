/**
 * PHASE 0.2: Create Firestore Collections and Seed Data
 * Runs: node scripts/create-collections.js
 * Creates 8 collections with test data for production deployment
 */

const admin = require('firebase-admin');
const serviceAccount = require('../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Collection schemas with sample data
const collections = {
  notifications: [
    {
      userId: 'test_user_1',
      title: 'Shipment Confirmed',
      body: 'Your shipping request has been confirmed and assigned to a shipper.',
      type: 'shipment_status',
      read: false,
      createdAt: admin.firestore.Timestamp.now(),
      actionUrl: '/shipments/sr_001',
    },
    {
      userId: 'test_user_1',
      title: 'Shipment In Transit',
      body: 'Your shipment is now in transit to the destination.',
      type: 'shipment_status',
      read: false,
      createdAt: admin.firestore.Timestamp.now(),
      actionUrl: '/shipments/sr_001',
    },
    {
      userId: 'test_user_2',
      title: 'Commission Generated',
      body: 'You have earned a commission from a referred shipment.',
      type: 'affiliate',
      read: false,
      createdAt: admin.firestore.Timestamp.now(),
      actionUrl: '/affiliate/dashboard',
    },
  ],
  customers: [
    {
      userId: 'user_123',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '+2348012345678',
      tier: 'gold',
      totalShipments: 15,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      userId: 'user_124',
      name: 'Jane Smith',
      email: 'jane@example.com',
      phone: '+2348087654321',
      tier: 'silver',
      totalShipments: 8,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      userId: 'user_125',
      name: 'Bob Johnson',
      email: 'bob@example.com',
      phone: '+2348056789012',
      tier: 'bronze',
      totalShipments: 3,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      userId: 'user_126',
      name: 'Alice Williams',
      email: 'alice@example.com',
      phone: '+2348034567890',
      tier: 'gold',
      totalShipments: 22,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      userId: 'user_127',
      name: 'Charlie Brown',
      email: 'charlie@example.com',
      phone: '+2348023456789',
      tier: 'silver',
      totalShipments: 5,
      createdAt: admin.firestore.Timestamp.now(),
    },
  ],
  orders: [
    {
      customerId: 'user_123',
      items: [
        { name: 'Electronics Package', quantity: 1, value: 50000 },
      ],
      total: 50000,
      status: 'pending',
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      customerId: 'user_124',
      items: [
        { name: 'Clothing Shipment', quantity: 5, value: 25000 },
      ],
      total: 25000,
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      customerId: 'user_125',
      items: [
        { name: 'Food Delivery', quantity: 20, value: 10000 },
      ],
      total: 10000,
      status: 'completed',
      createdAt: admin.firestore.Timestamp.now(),
    },
  ],
  commissions: [
    {
      affiliateId: 'aff_001',
      shipmentId: 'sr_001',
      amount: 5000,
      status: 'pending',
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      affiliateId: 'aff_002',
      shipmentId: 'sr_002',
      amount: 7500,
      status: 'paid',
      createdAt: admin.firestore.Timestamp.now(),
    },
  ],
  payouts: [
    {
      affiliateId: 'aff_001',
      amount: 25000,
      status: 'pending',
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      affiliateId: 'aff_002',
      amount: 50000,
      status: 'completed',
      createdAt: admin.firestore.Timestamp.now(),
    },
  ],
  invoices: [
    {
      customerId: 'user_123',
      items: [
        { description: 'Shipping Service', amount: 50000, quantity: 1 },
      ],
      total: 50000,
      status: 'pending',
      issueDate: admin.firestore.Timestamp.now(),
      dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    },
    {
      customerId: 'user_124',
      items: [
        { description: 'Shipping Service', amount: 25000, quantity: 1 },
      ],
      total: 25000,
      status: 'paid',
      issueDate: admin.firestore.Timestamp.now(),
      dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  ],
  announcements: [
    {
      title: 'System Maintenance',
      body: 'We will be performing scheduled maintenance on February 20, 2026 from 2-4 AM.',
      type: 'maintenance',
      priority: 'high',
      visible: true,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      title: 'New Feature: Live Tracking',
      body: 'Real-time GPS tracking is now available for all shipments.',
      type: 'feature',
      priority: 'medium',
      visible: true,
      createdAt: admin.firestore.Timestamp.now(),
    },
    {
      title: 'Winter Weather Advisory',
      body: 'Expect delays due to heavy snow in northern regions.',
      type: 'alert',
      priority: 'high',
      visible: true,
      createdAt: admin.firestore.Timestamp.now(),
    },
  ],
  content_pages: [
    {
      slug: 'terms-of-service',
      title: 'Terms of Service',
      body: `Last updated: February 19, 2026

1. ACCEPTANCE OF TERMS
By accessing and using ShopsNPorts, you accept and agree to be bound by the terms and provision of this agreement.

2. SERVICES DESCRIPTION
ShopsNPorts provides a shipping and logistics platform to facilitate the movement of goods between customers.

3. USER RESPONSIBILITIES
Users are responsible for maintaining the confidentiality of their account and password and for restricting access to their computer.

4. LIMITATIONS OF LIABILITY
In no event shall ShopsNPorts, its officers, directors, employees, or agents, be liable to you or any third parties for any direct, indirect, special, incidental, punitive, or consequential damages.

5. GOVERNING LAW
These terms and conditions are governed by and construed in accordance with the laws of Nigeria.`,
      published: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
    {
      slug: 'privacy-policy',
      title: 'Privacy Policy',
      body: `Last updated: February 19, 2026

1. INFORMATION WE COLLECT
We collect information you provide directly to us, such as when you create an account or submit a shipping request.

2. HOW WE USE INFORMATION
We use the information we collect to provide, maintain, and improve our services.

3. INFORMATION SHARING
We do not sell or rent your personal information to third parties.

4. DATA SECURITY
We implement appropriate technical and organizational measures to protect your personal information.

5. CONTACT US
If you have questions about this Privacy Policy, please contact us at privacy@shopsnports.com.`,
      published: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
    {
      slug: 'about-us',
      title: 'About ShopsNPorts',
      body: `ShopsNPorts is a leading logistics and shipping platform dedicated to connecting customers with reliable shipping services.

Our Mission
To provide fast, affordable, and reliable shipping services to customers across Nigeria and beyond.

Our Values
- Speed: Quick delivery times
- Reliability: On-time deliveries
- Transparency: Clear pricing and tracking
- Innovation: Continuous improvement

Founded in 2024, ShopsNPorts has facilitated over 10,000 successful shipments and partners with professional shippers across the country.`,
      published: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    },
  ],
};

async function createCollections() {
  console.log('🚀 Starting PHASE 0.2: Create Firestore Collections\n');

  try {
    for (const [collectionName, documents] of Object.entries(collections)) {
      console.log(`📦 Creating collection: ${collectionName}`);

      for (let i = 0; i < documents.length; i++) {
        const doc = documents[i];
        const docId = `${collectionName}_${Date.now()}_${i}`;

        await db.collection(collectionName).doc(docId).set(doc);
        console.log(`   ✓ Document ${i + 1}/${documents.length} created (${docId})`);
      }

      console.log(`✅ Collection "${collectionName}" created with ${documents.length} documents\n`);
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('✅ PHASE 0.2 COMPLETE!');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n📊 Collections Created:');
    console.log('   1. notifications (3 docs)');
    console.log('   2. customers (5 docs)');
    console.log('   3. orders (3 docs)');
    console.log('   4. commissions (2 docs)');
    console.log('   5. payouts (2 docs)');
    console.log('   6. invoices (2 docs)');
    console.log('   7. announcements (3 docs)');
    console.log('   8. content_pages (3 docs)\n');
    console.log('Next: Run PHASE 0.3 - Deploy Firestore Indexes');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating collections:', error);
    process.exit(1);
  }
}

// Run the script
createCollections();
