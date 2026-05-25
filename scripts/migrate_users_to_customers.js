/**
 * Migration script: Copy users collection data to customers collection
 * Run this with: node scripts/migrate_users_to_customers.js
 * 
 * This consolidates all customer data into a single 'customers' collection
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '../shopsnports-firebase-key.json');
admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

async function migrateUsersToCustomers() {
  try {
    console.log('🔄 Starting migration from users → customers collection...\n');

    // Get all documents from users collection
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.size} documents in 'users' collection`);

    if (usersSnapshot.size === 0) {
      console.log('✅ No users to migrate. Creating empty customers collection...\n');
      await db.collection('customers').doc('_init').set({initializing: true});
      await db.collection('customers').doc('_init').delete();
      console.log('✅ Empty customers collection created');
      return;
    }

    let migratedCount = 0;
    let skippedCount = 0;

    // Migrate each user document to customers collection
    for (const doc of usersSnapshot.docs) {
      const data = doc.data();
      const userId = doc.id;

      try {
        // Extract only customer-relevant fields
        const customerData = {
          id: userId,
          name: data.name || '',
          email: data.email || '',
          phone: data.phone || '',
          avatarUrl: data.avatarUrl || '',
          status: data.status || 'active',
          createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          lastLogin: data.lastLogin || admin.firestore.FieldValue.serverTimestamp(),
          // Keep other fields if present
          address: data.address,
          gender: data.gender,
          roles: data.roles,
          affiliateApproved: data.affiliateApproved || false,
        };

        // Write to customers collection
        await db.collection('customers').doc(userId).set(customerData, { merge: true });
        console.log(`✅ Migrated: ${userId} (${data.name || 'Unknown'})`);
        migratedCount++;
      } catch (err) {
        console.error(`❌ Error migrating ${userId}: ${err.message}`);
        skippedCount++;
      }
    }

    console.log(`\n📊 Migration complete!`);
    console.log(`   ✅ Migrated: ${migratedCount}`);
    console.log(`   ⏭️  Skipped: ${skippedCount}`);

    // Optional: Delete users collection
    console.log('\n⚠️  Note: users collection still exists.');
    console.log('   To delete it manually:');
    console.log('   1. Go to Firebase Console → Firestore Database');
    console.log('   2. Select "users" collection');
    console.log('   3. Click "Delete collection"');
    console.log('   4. Confirm deletion');

    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
}

migrateUsersToCustomers();
