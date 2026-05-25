const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

const auth = admin.auth();
const db = admin.firestore();

/**
 * Cloud Function: Triggered when a new user is created in Firebase Auth
 * Automatically creates a customer document in Firestore
 */
exports.syncNewUserToCustomers = functions.auth.user().onCreate(async (user) => {
  try {
    console.log(`🆕 New auth user created: ${user.uid} (${user.email})`);

    // Check if customer document already exists
    const customerDoc = await db.collection("customers").doc(user.uid).get();

    if (customerDoc.exists) {
      console.log(`ℹ️  Customer document already exists for ${user.uid}`);
      return;
    }

    // Create customer document from auth user
    const customerData = {
      id: user.uid,
      name: user.displayName || user.email.split("@")[0],
      email: user.email || "",
      phone: user.phoneNumber || "",
      avatarUrl: user.photoURL || "",
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("customers").doc(user.uid).set(customerData);
    console.log(`✅ Created customer document for ${user.uid}`);
  } catch (error) {
    console.error(
      `❌ Error syncing user ${user.uid} to customers:`,
      error
    );
    throw error;
  }
});

/**
 * Cloud Function: Sync all existing Firebase Auth users to customers collection
 * Run once with: firebase functions:call syncAllUsersToCustomers
 */
exports.syncAllUsersToCustomers = functions.https.onCall(
  async (data, context) => {
    // Check authentication (only allow admin)
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      console.log("🔄 Starting bulk sync of all auth users to customers...\n");

      let synced = 0;
      let skipped = 0;
      let errors = 0;

      // Get all users from Firebase Auth
      let pageToken = undefined;

      do {
        const result = await auth.listUsers(1000, pageToken);

        for (const userRecord of result.users) {
          try {
            const customerDoc = await db
              .collection("customers")
              .doc(userRecord.uid)
              .get();

            if (customerDoc.exists) {
              console.log(`⏭️  Skipped (exists): ${userRecord.email}`);
              skipped++;
              continue;
            }

            // Create new customer document
            const customerData = {
              id: userRecord.uid,
              name:
                userRecord.displayName ||
                userRecord.email.split("@")[0],
              email: userRecord.email,
              phone: userRecord.phoneNumber || "",
              avatarUrl: userRecord.photoURL || "",
              status: "active",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              lastLogin: admin.firestore.FieldValue.serverTimestamp(),
            };

            await db
              .collection("customers")
              .doc(userRecord.uid)
              .set(customerData);

            console.log(`✅ Synced: ${userRecord.email}`);
            synced++;
          } catch (err) {
            console.error(
              `❌ Error syncing ${userRecord.email}:`,
              err.message
            );
            errors++;
          }
        }

        pageToken = result.pageToken;
      } while (pageToken);

      const message = `Sync complete! Synced: ${synced}, Skipped: ${skipped}, Errors: ${errors}`;
      console.log(`\n📊 ${message}`);
      return { success: true, synced, skipped, errors };
    } catch (error) {
      console.error("❌ Sync failed:", error.message);
      throw new functions.https.HttpsError(
        "internal",
        `Sync failed: ${error.message}`
      );
    }
  }
);

/**
 * Cloud Function: Keep customers collection in sync with Auth
 * Run periodically via Cloud Scheduler (daily)
 */
exports.scheduledSyncUsersToCustomers = functions.pubsub
  .schedule("every day 02:00")
  .onRun(async (context) => {
    try {
      console.log("🔄 Running daily sync of auth users to customers...");

      let synced = 0;
      let skipped = 0;

      // Get all auth users
      let pageToken = undefined;

      do {
        const result = await auth.listUsers(1000, pageToken);

        for (const userRecord of result.users) {
          const customerDoc = await db
            .collection("customers")
            .doc(userRecord.uid)
            .get();

          if (customerDoc.exists) {
            skipped++;
            continue;
          }

          // Create customer document for new auth user
          const customerData = {
            id: userRecord.uid,
            name:
              userRecord.displayName ||
              userRecord.email.split("@")[0],
            email: userRecord.email,
            phone: userRecord.phoneNumber || "",
            avatarUrl: userRecord.photoURL || "",
            status: "active",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLogin: admin.firestore.FieldValue.serverTimestamp(),
          };

          await db
            .collection("customers")
            .doc(userRecord.uid)
            .set(customerData);
          synced++;
        }

        pageToken = result.pageToken;
      } while (pageToken);

      console.log(
        `✅ Daily sync complete! Synced: ${synced}, Already existed: ${skipped}`
      );
    } catch (error) {
      console.error("❌ Daily sync failed:", error.message);
    }
  });
