/*
Firestore seeder script for development/demo.

Usage (local or CI):
- Set Google service account credentials as environment variable:
  - `setx GOOGLE_APPLICATION_CREDENTIALS "C:\path\to\serviceAccountKey.json"` (Windows PowerShell)
  - or export in CI env var `GOOGLE_APPLICATION_CREDENTIALS`

- Run locally with Node.js:
  - `node scripts/seed_reviews.js --count=50`

Notes:
- This script writes  documents into the `reviews` collection.
- Each document will include an `id` field (the doc id) because the app's `Review.fromMap` expects that field.
- Remove or restrict this script from production usage; do not commit service account keys.
*/

const admin = require('firebase-admin');
const { program } = require('commander');

program.option('-c, --count <number>', 'number of reviews to create', '50');
program.parse(process.argv);
const opts = program.opts();
const COUNT = parseInt(opts.count, 10) || 50;

// Initialize Admin SDK: emulator vs production
try {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    // Emulator: no ADC needed
    const projectId = process.env.GCLOUD_PROJECT || 'demo-project';
    admin.initializeApp({ projectId });
    console.log(`[seed_reviews] Initialized for emulator (projectId=${projectId}).`);
  } else {
    // Production: require ADC/service account
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
    console.log('[seed_reviews] Initialized with application default credentials.');
  }
} catch (e) {
  console.error('Failed to initialize firebase-admin. For emulator set FIRESTORE_EMULATOR_HOST and GCLOUD_PROJECT. For prod set GOOGLE_APPLICATION_CREDENTIALS.');
  console.error(e);
  process.exit(1);
}

const db = admin.firestore();
const reviewsRef = db.collection('reviews');

const vendors = ['Acme Audio', 'SmartTech', 'GearWorks', 'SoundHub', 'BlueOcean'];
const products = [
  { id: 'p1', name: 'Wireless Headphones', image: 'assets/icons/1.jpg' },
  { id: 'p2', name: 'Smart Watch', image: 'assets/icons/2.jpg' },
  { id: 'p3', name: 'Laptop Backpack', image: 'assets/icons/3.jpg' },
  { id: 'p4', name: 'Bluetooth Speaker', image: 'assets/icons/4.jpg' },
  { id: 'p5', name: 'USB-C Hub', image: 'assets/icons/5.jpg' },
];
const customers = ['John Doe','Jane Smith','Mike Johnson','Sarah Wilson','Alex Lee','Priya Patel','Carlos Ruiz','Liu Wei'];
const statuses = ['pending','approved','rejected'];

function randomChoice(arr, idx) {
  return arr[idx % arr.length];
}

(async () => {
  console.log(`Seeding ${COUNT} reviews into Firestore (collection: reviews)`);
  let created = 0;
  for (let i = 0; i < COUNT; i++) {
    const prod = randomChoice(products, i);
    const vendor = randomChoice(vendors, i);
    const cust = randomChoice(customers, i);
    const status = randomChoice(statuses, i);
    const rating = (i % 5) + 1;
    const docRef = reviewsRef.doc();

    const data = {
      id: docRef.id,
      date: admin.firestore.Timestamp.fromDate(new Date(Date.now() - i * 24 * 60 * 60 * 1000)),
      customerId: `cust_${i + 1}`,
      customerName: cust,
      customerAvatar: i % 2 === 0 ? 'assets/icons/face1.png' : 'assets/icons/face2.png',
      productId: prod.id,
      productName: prod.name,
      productImage: prod.image,
      vendorName: vendor,
      // tag seeded docs so cleanup is easy
      seeded: true,
      seedTag: 'dev_seed_v1',
      rating: rating,
      comment: `Sample review #${i + 1} for ${prod.name}.`,
      status: status,
      isVerifiedPurchase: i % 3 === 0,
      vendorResponse: i % 7 === 0 ? 'Thank you for your feedback.' : null,
      vendorRespondedAt: i % 7 === 0 ? admin.firestore.Timestamp.fromDate(new Date()) : null,
    };

    try {
      await docRef.set(data);
      created++;
      if (created % 10 === 0) console.log(`  Created ${created} reviews...`);
    } catch (err) {
      console.error('Failed to create document', err);
      process.exit(1);
    }
  }

  console.log(`Seeding complete. ${created} documents written to 'reviews' collection.`);
  process.exit(0);
})();
