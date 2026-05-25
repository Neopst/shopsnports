/**
 * Add test users to Firestore
 * Run: node scripts/add_test_users.js
 */

const admin = require('firebase-admin');

// Initialize without service account - will use application default credentials
admin.initializeApp();

const db = admin.firestore();

async function addTestUsers() {
  try {
    // Get the Firebase Auth user to get the UID
    const userRecord = await admin.auth().getUserByEmail('tester@shopsnports.com');
    const uid = userRecord.uid;
    
    console.log('Found user with UID:', uid);
    
    // Add user document to Firestore
    await db.collection('users').doc(uid).set({
      id: uid,
      email: 'tester@shopsnports.com',
      name: 'Test User',
      roles: ['customer', 'vendor', 'affiliate', 'shipper'],
      activeRole: 'vendor',
      isAdmin: true,
      affiliateApproved: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ User document created in Firestore');
    console.log('User can now login and test all roles (vendor, affiliate, shipper)');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

addTestUsers();
