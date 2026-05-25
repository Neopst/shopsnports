// Admin User Seeding Script
// Usage: node seed_admin_users.js --key path/to/sa.json --email <email> --password <password> [--displayName <name>]

const admin = require('firebase-admin');
const fs = require('fs');
const argv = require('minimist')(process.argv.slice(2));

async function main() {
  const key = argv.key;
  const email = argv.email;
  const password = argv.password;
  const displayName = argv.displayName || email.split('@')[0];
  const project = argv.project;

  if (!key || !email || !password) {
    console.error('Usage: node seed_admin_users.js --key path/to/sa.json --email <email> --password <password> [--displayName <name>] [--project <projectId>]');
    process.exit(1);
  }

  if (!fs.existsSync(key)) {
    console.error('Key file not found:', key);
    process.exit(1);
  }

  try {
    const keyJson = JSON.parse(fs.readFileSync(key, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(keyJson),
      projectId: project
    });

    const db = admin.firestore();
    const auth = admin.auth();

    console.log('🔐 Creating admin user...');
    console.log('   Email:', email);
    console.log('   Display Name:', displayName);

    // Create or update the user in Firebase Auth
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: displayName,
        emailVerified: true
      });
      console.log('✅ User created in Firebase Auth:', userRecord.uid);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        // User already exists, get the record
        userRecord = await auth.getUserByEmail(email);
        console.log('ℹ️  User already exists in Firebase Auth:', userRecord.uid);
      } else {
        throw error;
      }
    }

    // Set custom claims for admin
    await auth.setCustomUserClaims(userRecord.uid, {
      admin: true,
      role: 'super_admin'
    });
    console.log('✅ Custom claims set');

    // Create admin user document in Firestore
    const adminDocRef = db.collection('admin_users').doc(userRecord.uid);
    const adminDoc = await adminDocRef.get();

    if (!adminDoc.exists) {
      await adminDocRef.set({
        id: userRecord.uid,
        email: email,
        displayName: displayName,
        role: 'super_admin',
        status: 'active',
        permissions: {
          dashboard: true,
          users: true,
          content_management: true,
          shipping: true,
          affiliates: true,
          analytics: true,
          settings: true,
          super_admin: true
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: null,
        requirePasswordChange: false
      });
      console.log('✅ Admin document created in Firestore');
    } else {
      console.log('ℹ️  Admin document already exists in Firestore');
    }

    console.log('\n🎉 Admin user seeding complete!');
    console.log('   UID:', userRecord.uid);
    console.log('   Email:', email);
    console.log('   Role: super_admin');
    console.log('\n⚠️  IMPORTANT: Save this UID for reference:', userRecord.uid);

  } catch (error) {
    console.error('❌ Error seeding admin user:', error);
    process.exit(1);
  }
}

main();