const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();
const userId = 'onKwFWGTpaRBViQ28DY9gXzjWzK2';

async function checkUserDocument() {
  try {
    console.log('📋 Checking user document...\n');
    
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log('❌ USER DOCUMENT DOES NOT EXIST!');
      console.log('\nCreating document now...\n');
      await createUserDocument();
      return;
    }
    
    const data = userDoc.data();
    console.log('✅ Document exists. Current data:');
    console.log(JSON.stringify(data, null, 2));
    
    // Check roles field
    console.log('\n📊 Field Type Analysis:');
    console.log(`roles type: ${Array.isArray(data.roles) ? 'ARRAY ✅' : typeof data.roles + ' ❌'}`);
    console.log(`roles value:`, data.roles);
    console.log(`roleStatus type: ${typeof data.roleStatus}`);
    console.log(`roleStatus value:`, data.roleStatus);
    
    // Check if update needed
    const needsUpdate = !Array.isArray(data.roles) || 
                        !data.roleStatus ||
                        !data.affiliateApproved ||
                        !data.isAdmin;
    
    if (needsUpdate) {
      console.log('\n⚠️  Document needs updating...');
      await updateUserDocument(data);
    } else {
      console.log('\n✅ Document structure is correct!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

async function createUserDocument() {
  const userData = {
    id: userId,
    email: 'tester@shopsnports.com',
    name: 'Tester',
    roles: ['customer', 'vendor', 'affiliate', 'shipper'], // ARRAY
    roleStatus: {
      vendor: 'approved',
      affiliate: 'approved',
      shipper: 'approved'
    },
    activeRole: 'vendor',
    affiliateApproved: true,
    isAdmin: true
  };
  
  await db.collection('users').doc(userId).set(userData);
  console.log('✅ User document created successfully!');
  console.log(JSON.stringify(userData, null, 2));
}

async function updateUserDocument(currentData) {
  const updates = {
    roles: Array.isArray(currentData.roles) 
      ? currentData.roles 
      : ['customer', 'vendor', 'affiliate', 'shipper'],
    roleStatus: currentData.roleStatus || {
      vendor: 'approved',
      affiliate: 'approved',
      shipper: 'approved'
    },
    affiliateApproved: true,
    isAdmin: true,
    name: currentData.name || 'Tester'
  };
  
  await db.collection('users').doc(userId).update(updates);
  console.log('✅ User document updated successfully!');
  console.log(JSON.stringify(updates, null, 2));
}

checkUserDocument();
