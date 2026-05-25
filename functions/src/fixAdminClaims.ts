import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: Fix missing admin claims
 * 
 * Callable by any authenticated user.
 * If user is in admin_users collection, sets required custom claims.
 * This fixes permission issues when admins don't have custom claims set.
 * 
 * Callable Cloud Function
 */
export const fixAdminClaims = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const db = admin.firestore();
    const auth = admin.auth();

    console.log(`🔍 Checking admin status for user: ${userId}`);

    // ========== CHECK IF USER IS ADMIN ==========
    const adminDoc = await db.collection('admin_users').doc(userId).get();

    if (!adminDoc.exists) {
      console.log(`❌ User ${userId} is not in admin_users collection`);
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not registered as an admin'
      );
    }

    const adminData = adminDoc.data()!;
    const email = adminData.email || 'unknown';
    const role = adminData.role || 'admin';

    console.log(`✅ User is admin: ${email} (role: ${role})`);

    // ========== SET CUSTOM CLAIMS ==========
    await auth.setCustomUserClaims(userId, {
      admin: true,
      role: role,
    });

    console.log(`✅ Custom claims set for: ${email}`);

    return {
      success: true,
      message: `Custom claims updated for ${email}. Please refresh the app to see changes.`,
      email: email,
      role: role,
    };
  } catch (error: any) {
    console.error('❌ Error in fixAdminClaims:', error.message);
    
    if (error.code === 'permission-denied') {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to fix claims: ${error.message}`
    );
  }
});
