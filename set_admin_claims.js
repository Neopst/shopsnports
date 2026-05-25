// Set custom claims for all existing admins
// Run: node set_admin_claims.js

const admin = require("firebase-admin");
const serviceAccount = require("./.firebase/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setAdminClaims() {
  const db = admin.firestore();
  const auth = admin.auth();

  try {
    console.log("📋 Fetching all admin users...");
    
    // Get all documents from admin_users collection
    const adminSnapshot = await db.collection("admin_users").get();
    
    if (adminSnapshot.empty) {
      console.log("❌ No admin users found in Firestore");
      process.exit(1);
    }

    console.log(`✅ Found ${adminSnapshot.size} admin user(s)`);

    let successCount = 0;
    let errorCount = 0;

    for (const doc of adminSnapshot.docs) {
      const adminData = doc.data();
      const uid = doc.id;
      const email = adminData.email || "unknown";
      const role = adminData.role || "admin";

      try {
        console.log(`\n🔐 Setting claims for: ${email} (${uid})`);
        
        // Set custom claims
        await auth.setCustomUserClaims(uid, {
          admin: true,
          role: role,
        });

        console.log(`✅ Claims set successfully for ${email}`);
        successCount++;
      } catch (error) {
        console.error(`❌ Error setting claims for ${email}:`, error.message);
        errorCount++;
      }
    }

    console.log(`\n${"=".repeat(50)}`);
    console.log(`✅ Success: ${successCount} admin(s)`);
    console.log(`❌ Failed: ${errorCount} admin(s)`);
    console.log(`${"=".repeat(50)}\n`);

    if (successCount > 0) {
      console.log("🎉 Custom claims have been set!");
      console.log("⚠️  Please ask users to refresh/re-login to see updated permissions\n");
    }

    process.exit(errorCount > 0 ? 1 : 0);
  } catch (error) {
    console.error("❌ Fatal error:", error.message);
    process.exit(1);
  }
}

setAdminClaims();
